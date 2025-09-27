terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.36.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "3.0.0-pre2"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

#get configuration using Exec Plugins
provider "kubernetes" {
  # host                   = data.aws_eks_cluster.eks-cluster.endpoint
  host = module.eks.endpoint
  # cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks-cluster.certificate_authority.0.data)
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes = {
    # host                   = data.aws_eks_cluster.eks-cluster.endpoint
    host = module.eks.endpoint
    # cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks-cluster.certificate_authority[0].data)
    cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
      command     = "aws"
    }
  }
}