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
variable "common_tags" {
  type    = map(any)
  default = {} # it is optional
}

variable "vpc_tags" {
  type    = map(any)
  default = {}
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "igw_tags" {
  type    = map(string)
  default = {}
}
variable "region"{
  description = "The AWS region to deploy the resources in"
  type        = string
}
variable "nat_gateway_tags" {
  type    = map(string)
  default = {}
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