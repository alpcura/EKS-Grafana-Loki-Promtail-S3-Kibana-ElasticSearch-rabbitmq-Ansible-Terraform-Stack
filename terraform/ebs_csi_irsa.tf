############################################
# EBS CSI IRSA + Addon binding (Terraform)
############################################

# Trust policy (multi-line block; tek satır HATA veriyordu)
data "aws_iam_policy_document" "ebs_csi_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
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

resource "aws_iam_role" "ebs_csi" {
  name               = "${var.project_name}-${var.environment}-ebs-csi-irsa"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_trust.json
  tags               = { Project = var.project_name, Environment = var.environment }
}

# Managed policy: AmazonEBSCSIDriverPolicy (GEREKLİ)
data "aws_iam_policy" "ebs_csi_managed" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_iam_role_policy_attachment" "ebs_csi_attach" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = data.aws_iam_policy.ebs_csi_managed.arn
}

# Addon'ı o role ile BAĞLA (OVERWRITE) -> IRSA kesin bu role'e düşer
# resource "aws_eks_addon" "ebs_csi" {
#   cluster_name                = var.cluster_name
#   addon_name                  = "aws-ebs-csi-driver"
#   resolve_conflicts_on_create = "OVERWRITE"
#   resolve_conflicts_on_update = "OVERWRITE"
#   service_account_role_arn    = aws_iam_role.ebs_csi.arn

#   depends_on = [aws_iam_role_policy_attachment.ebs_csi_attach]
# }