############################################
# loki_irsa_s3.tf  (S3 + IRSA for Loki)
############################################

locals {
  loki_bucket_name  = "${var.project_name}-logs-${var.environment}"
  loki_sa_namespace = "logging"
  loki_sa_name      = "loki"
}

# S3 Bucket
resource "random_id" "loki_suffix" {
  byte_length = 4
}

# ---- S3 bucket ----
resource "aws_s3_bucket" "loki" {
  bucket = "${local.loki_bucket_name}-${random_id.loki_suffix.hex}" # Örn: project3-logs-sbx-ab12cd34
  tags   = {
    Project     = var.project_name
    Environment = var.environment
  }
  force_destroy = true
}

# resource "aws_s3_bucket" "loki" {
#   bucket = local.loki_bucket_name
#   tags   = { Project = var.project_name, Environment = var.environment }
# }

resource "aws_s3_bucket_public_access_block" "loki" {
  bucket                  = aws_s3_bucket.loki.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "loki" {
  bucket = aws_s3_bucket.loki.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "loki" {
  bucket = aws_s3_bucket.loki.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "loki" {
  bucket = aws_s3_bucket.loki.id
  rule {
    id     = "logs-retention"
    status = "Enabled"

    # filter/prefix zorunlu
    filter { prefix = "" }

    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "GLACIER"
    }

    expiration { days = 365 }
  }
}

# IRSA Role (logging/loki)
data "aws_iam_policy_document" "loki_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${local.loki_sa_namespace}:${local.loki_sa_name}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }
  }
}

resource "aws_iam_role" "loki_irsa" {
  name               = "${var.project_name}-${var.environment}-loki-irsa"
  assume_role_policy = data.aws_iam_policy_document.loki_assume.json
  tags               = { Project = var.project_name, Environment = var.environment }
}

data "aws_iam_policy_document" "loki_s3_policy" {
  statement {
    sid     = "ListBucket"
    effect  = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:ListBucketVersions",
      "s3:ListBucketMultipartUploads"
    ]
    resources = [aws_s3_bucket.loki.arn]
  }

  statement {
    sid     = "RWObjects"
    effect  = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:AbortMultipartUpload"
    ]
    resources = ["${aws_s3_bucket.loki.arn}/*"]
  }
}

resource "aws_iam_policy" "loki_s3_policy" {
  name   = "${var.project_name}-${var.environment}-loki-s3"
  policy = data.aws_iam_policy_document.loki_s3_policy.json
}

resource "aws_iam_role_policy_attachment" "loki_attach" {
  role       = aws_iam_role.loki_irsa.name
  policy_arn = aws_iam_policy.loki_s3_policy.arn
}