variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "enable_dns_hostnames" {
  type = bool
}

variable "enable_dns_support" {
  type = bool
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "pub_subnet_count" {
  description = "Number of public subnets to create"
  type        = number
}

variable "pri_subnet_count" {
  description = "Number of private subnets to create"
  type        = number
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)

}

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  type = string
}

variable "region" {
  description = "The AWS region to deploy the resources in"
  type        = string
}

variable "AWS_ACCOUNT_ID" {
  description = "The AWS account ID"
  type        = string
}

variable "eks_addons" {
  description = "List of EKS addons with name and version"
  type = list(object({
    name    = string
    version = string
  }))
}