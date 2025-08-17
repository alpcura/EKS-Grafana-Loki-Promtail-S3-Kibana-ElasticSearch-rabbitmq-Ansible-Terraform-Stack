

# ---- Resmi ALB Controller policy ----
data "http" "alb_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.1/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "alb_controller" {
  name   = "AWSLoadBalancerControllerIAMPolicy"
  policy = data.http.alb_iam_policy.response_body
}

# ---- EKS modülünden OIDC çıktıları ----
# (terraform-aws-eks modülünü kullanıyorsan bunlar zaten var)
locals {
  oidc_issuer_url      = module.eks.cluster_oidc_issuer_url
  oidc_provider_arn    = module.eks.oidc_provider_arn
  oidc_issuer_hostpath = replace(local.oidc_issuer_url, "https://", "")
}

# ---- TRUST POLICY (IRSA) : aud + sub şart! ----
data "aws_iam_policy_document" "alb_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    # SA: kube-system/aws-load-balancer-controller
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_hostpath}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    # OIDC audience: sts.amazonaws.com
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_hostpath}:aud"
      values   = ["sts.amazonaws.com"]
    }

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }
  }
}

resource "aws_iam_role" "alb_controller" {
  name               = "${var.cluster_name}-alb-controller"
  assume_role_policy = data.aws_iam_policy_document.alb_assume.json
  tags = {
    Project     = var.project_name
    Environment = var.environment
  }

  # EKS ve OIDC provider önce oluşsun
  depends_on = [module.eks]
}

resource "aws_iam_role_policy_attachment" "alb_attach" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}

# (Opsiyonel) ek izin: DescribeListenerAttributes
resource "aws_iam_role_policy" "alb_extra_describe_listener_attrs" {
  name = "alb-extra-describe-listener-attrs"
  role = aws_iam_role.alb_controller.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "elasticloadbalancing:DescribeListenerAttributes",
        Resource = "*"
      }
    ]
  })
}
