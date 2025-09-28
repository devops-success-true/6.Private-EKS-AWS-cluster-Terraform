terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"         # allow safe patch/minor upgrades
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.36"        # allow bugfix updates, not major bumps
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"        # stable release, not pre-release
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# safer: fetch cluster details instead of reading module internals
data "aws_eks_cluster" "this" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "this" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}
