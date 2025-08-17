############################
# eks.tf
############################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.37" # 20.x serisi (senin init'te gelen sürümle uyumlu)
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]        # tercihen kendi IP/32 koy
  cluster_endpoint_private_access      = false                # VPN yoksa şimdilik kapalı
  # ---- Cluster ----
  cluster_name    = var.cluster_name        # örn: "project3-eks"
  cluster_version = "1.29"
  vpc_id          = module.vpc.vpc_id

  # API server hangi subnet'leri görsün?
  # (Cluster ENI'leri için hem private hem public veriyoruz;
  #  Worker node'lar ise AŞAĞIDA sadece private'a konuyor.)
  subnet_ids = concat(
    module.vpc.private_subnets,
    module.vpc.public_subnets
  )

  # IRSA (ALB Controller vb. için gerekli)
  enable_irsa = true

  # ---- Addon'lar ----
  cluster_addons = {
    coredns = {
      most_recent              = true
      resolve_conflicts        = "OVERWRITE"
      resolve_conflicts_on_create = "OVERWRITE"
    }
    kube-proxy = {
      most_recent              = true
      resolve_conflicts        = "OVERWRITE"
      resolve_conflicts_on_create = "OVERWRITE"
    }
    vpc-cni = {
      most_recent              = true
      resolve_conflicts        = "OVERWRITE"
      resolve_conflicts_on_create = "OVERWRITE"
    }
    metrics-server = {
      most_recent              = true
      resolve_conflicts        = "OVERWRITE"
      resolve_conflicts_on_create = "OVERWRITE"
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      resolve_conflicts        = "OVERWRITE"
      resolve_conflicts_on_create = "OVERWRITE"
      
      # role unutulmasin !!
      service_account_role_arn = aws_iam_role.ebs_csi.arn
    }
  }

  # İsteğe bağlı ama faydalı: kontrol düzlemi logları
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # ---- Node Group (managed) ----
  eks_managed_node_groups = {
    general = {
      ami_type       = "AL2_x86_64"
      instance_types = ["t3.medium"]

      min_size     = 2
      max_size     = 4
      desired_size = 2

      # Worker node'ları private subnet'lere yerleştir
      subnet_ids = module.vpc.private_subnets

      labels = {
        nodegroup = "general"
      }
      tags = {
        Name    = "${var.cluster_name}-general"
        Project = "project3"
      }
    }
  }

  # (Varsayılan) cluster kuran kullanıcıya admin RBAC
  enable_cluster_creator_admin_permissions = true

  tags = {
    Project = "project3"
  }
}