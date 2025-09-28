###############################################
# Ubuntu AMI Lookup
# Purpose: Get the latest Ubuntu 24.04 AMI from Canonical.
# Note: `most_recent = true` will change silently when Canonical publishes new images.
#       Fine for dev/test, but in production it's safer to pin AMI IDs or pull from SSM.
###############################################
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  owners = ["099720109477"] # Canonical
}

# --- Production alternative ---
# Instead of rolling `most_recent = true`, use AWS SSM Parameter Store which Canonical updates.
# This way you always pull the official recommended AMI ID for Ubuntu 24.04 (x86_64).
# Uncomment this block for production stability:
#
# data "aws_ssm_parameter" "ubuntu_ami" {
#   name = "/aws/service/canonical/ubuntu/noble/stable/current/amd64/hvm/ebs-gp3/ami-id"
# }
#
# Then reference it as: data.aws_ssm_parameter.ubuntu_ami.value
# -------------------------------------------------------------

###############################################
# VPC Lookup
# Purpose: Find the VPC by Name tag.
# Note: Works if you tag VPCs consistently with `Name = local.name`.
#       In production, prefer consuming `vpc_id` from module outputs instead of tag search.
###############################################
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = [local.name]
  }
}

###############################################
# Public Subnets Lookup
# Purpose: Fetch public subnets in the VPC tagged for internet-facing ELBs.
# Note: Safer to consume `public_subnet_ids` from VPC module outputs in production.
###############################################
data "aws_subnets" "public_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  filter {
    name   = "tag:kubernetes.io/role/elb"
    values = ["1"]
  }
}

###############################################
# Bastion Security Group Lookup
# Purpose: Get the bastion SG (restricted SSH/VPN access).
# Note: Much safer than using a world-open "allow_all" SG.
#       For production, prefer wiring SG IDs via module outputs instead of lookups.
###############################################
data "aws_security_group" "ec2_sg" {
  filter {
    name   = "tag:Name"
    values = ["${local.name}-bastion-sg"]
  }
  vpc_id = data.aws_vpc.main.id
}
