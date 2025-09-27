variable "common_tags" {
  type    = map(any)
  default = {} # it is optional
}
variable "cluster_version" {
  type = string
}
variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  description = "The AWS region to deploy the resources in"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
}
variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "eks_addons" {
  description = "List of EKS addons with name and version"
  type = list(object({
    name    = string
    version = string
  }))
}