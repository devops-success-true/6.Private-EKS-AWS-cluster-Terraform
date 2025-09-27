data "tls_certificate" "eks-certificate" {
  url = aws_eks_cluster.my_cluster.identity[0].oidc[0].issuer
}

data "aws_eks_cluster" "eks-cluster" {
  name = aws_eks_cluster.my_cluster.name

  depends_on = [aws_eks_cluster.my_cluster]
}

data "aws_eks_cluster_auth" "eks-cluster-auth" {
  name = aws_eks_cluster.my_cluster.name
}

data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = [local.name]
  }
}

data "aws_subnets" "private_subnets" {
  filter {
    name   = "vpc-id"               # Filter by VPC ID
    values = [data.aws_vpc.main.id] # VPC ID from the data source
  }

  filter {
    name   = "tag:kubernetes.io/role/internal-elb" # Filter by the specific tag
    values = ["1"]                                 # Value to match
  }
}

data "aws_security_group" "cluster_sg" {
  filter{
    name = "tag:Name" # filter by tag name
    values = ["cluster-sg"]
  }
  name = "eks-cluster-sg"
  vpc_id = data.aws_vpc.main.id
}