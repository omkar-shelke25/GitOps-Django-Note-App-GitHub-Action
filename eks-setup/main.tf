terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.3.0"
}

provider "aws" {
  region = "us-east-1"
}

# Default VPC
data "aws_vpc" "default" {
  default = true
}

# All subnets in default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Fetch subnet details
data "aws_subnet" "subnet_0" { id = element(data.aws_subnets.default.ids, 0) }
data "aws_subnet" "subnet_1" { id = element(data.aws_subnets.default.ids, 1) }
data "aws_subnet" "subnet_2" { id = element(data.aws_subnets.default.ids, 2) }
data "aws_subnet" "subnet_3" { id = element(data.aws_subnets.default.ids, 3) }
data "aws_subnet" "subnet_4" { id = element(data.aws_subnets.default.ids, 4) }
data "aws_subnet" "subnet_5" { id = element(data.aws_subnets.default.ids, 5) }

# AZ filtering
locals {
  supported_azs = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1f"]
  all_subnets = [
    data.aws_subnet.subnet_0,
    data.aws_subnet.subnet_1,
    data.aws_subnet.subnet_2,
    data.aws_subnet.subnet_3,
    data.aws_subnet.subnet_4,
    data.aws_subnet.subnet_5
  ]
  filtered_subnets = [
    for s in local.all_subnets : s.id
    if contains(local.supported_azs, s.availability_zone)
  ]
  selected_subnets = slice(local.filtered_subnets, 0, 2)
}

# EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.31.0"

  cluster_name    = "Note-app"
  cluster_version = "1.28"

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = local.selected_subnets

  eks_managed_node_groups = {
    worker = {
      min_size     = 1
      max_size     = 1
      desired_size = 1

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
    }
  }
}

# Local-exec to configure kubeconfig and install Argo CD
resource "null_resource" "configure_kube_and_argocd" {
  provisioner "local-exec" {
    command = <<-EOC
      echo "Updating kubeconfig..."
      aws eks update-kubeconfig --region us-east-1 --name ${module.eks.cluster_name}

      echo "Installing Argo CD..."
      kubectl create namespace argocd || true
      kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

      echo "Waiting for Argo CD to initialize..."
      sleep 60

      echo "Retrieving Argo CD admin password..."
      kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d > argocd_admin_password.txt
    EOC
  }

  depends_on = [module.eks]
}

# Output the Argo CD admin password
output "argocd_admin_password" {
  value       = file("argocd_admin_password.txt")
  description = "Initial Argo CD admin password"
  sensitive   = true
}
