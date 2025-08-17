terraform {
  required_version = ">= 1.5"
  required_providers {
    aws         = { source = "hashicorp/aws",        version = "~> 5.50" }
    kubernetes  = { source = "hashicorp/kubernetes", version = "~> 2.30" }
    http        = { source = "hashicorp/http" }
  }
}

provider "aws" {
  region  = var.region
  profile = "sandbox"   # <- ZORLA SANDBOX
  # optional: bazen local IMDS denemelerini kesmek için
  # skip_metadata_api_check = true
}