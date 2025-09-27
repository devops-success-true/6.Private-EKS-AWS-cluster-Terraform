module "vpc" {
  source               = "./modules/VPC"
  vpc_cidr             = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  project_name         = var.project_name
  environment          = var.environment
  pub_subnet_count     = var.pub_subnet_count
  pri_subnet_count     = var.pri_subnet_count
  tags                 = var.tags
  cluster_name         = var.cluster_name
  region               = var.region
}

module "ec2" {
  source       = "./modules/EC2"
  project_name = var.project_name
  environment  = var.environment

  depends_on = [module.vpc]
}

module "eks" {
  source          = "./modules/EKS"
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  eks_addons      = var.eks_addons
  project_name    = var.project_name
  environment     = var.environment
  region          = var.region
  tags            = var.tags

  depends_on = [module.vpc, module.ec2]
}