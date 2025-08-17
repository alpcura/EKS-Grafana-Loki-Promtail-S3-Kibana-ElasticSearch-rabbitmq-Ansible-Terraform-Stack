output "cluster_name"       { value = var.cluster_name }
output "region"             { value = var.region }
output "vpc_id"             { value = module.vpc.vpc_id }
output "public_subnets"     { value = module.vpc.public_subnets }
output "private_subnets"    { value = module.vpc.private_subnets }
output "alb_controller_role_arn" { value = aws_iam_role.alb_controller.arn }
output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --name ${var.cluster_name} --region ${var.region}"
}

# --- Loki için gerekli olanlar ---
output "ebs_csi_role_arn" {
  value = aws_iam_role.ebs_csi.arn
}

output "loki_irsa_role_arn" {
  value = aws_iam_role.loki_irsa.arn
}

output "loki_bucket_name" {
  value = aws_s3_bucket.loki.bucket
}