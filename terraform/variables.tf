variable "region"       { default = "us-east-1" }
variable "cluster_name" { default = "project3-eks" }
variable "vpc_cidr"     { default = "10.0.0.0/16" }
variable "az_count"     { default = 2 }
variable "project_name" {
  type    = string
  default = "project3"
}

variable "environment" {
  type    = string
  default = "sbx"
}