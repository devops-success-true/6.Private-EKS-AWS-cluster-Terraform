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

data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = [local.name]
  }
}

data "aws_subnets" "public_subnets" {
  filter {
    name   = "vpc-id"               # Filter by VPC ID
    values = [data.aws_vpc.main.id] # VPC ID from the data source
  }

  filter {
    name   = "tag:kubernetes.io/role/elb" # Filter by the specific tag
    values = ["1"]                                 # Value to match
  }
}

data "aws_security_group" "ec2_sg" {
  filter{
    name = "tag:Name" # filter by tag name
    values = ["allow_all"]
  }
  name = "allow_all"
  vpc_id = data.aws_vpc.main.id
}