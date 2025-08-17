data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"

  # İstersen çakışma ihtimalini sıfırlamak için 10.50.0.0/16 kullan:
  cidr = var.vpc_cidr

  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # İKİSİ DE /20 (newbits=4) — ÇAKIŞMA YOK
  # private: index 0..(az_count-1)  -> 10.0.0.0/20, 10.0.16.0/20, ...
  private_subnets = [
    for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 4, i)
  ]

  # public: index 8..(8+az_count-1) -> 10.0.128.0/20, 10.0.144.0/20, ...
  # (private bloklarıyla kesişmez)
  public_subnets = [
    for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 4, 8 + i)
  ]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  tags = { Project = "project3" }
}