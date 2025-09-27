# for ec2 instance
resource "aws_security_group" "allow_tls" {
  name        = "allow_all"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow_All"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress { # openvpn
    description = "Allow_All"
    from_port   = 1194
    to_port     = 1194
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_all"
  }
}

# for eks cluster
resource "aws_security_group" "cluster_sg" {
  name        = "eks-cluster-sg"
  description = "Node groups to cluster API"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Node groups to cluster API"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # should be specific IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" #all protocols are allowed
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cluster-sg"
    "karpenter.sh/discovery"                 = var.cluster_name #karpenter cluster autoscaler tags
    "kubernetes.io/cluster/${var.cluster_name}" = "owned" #karpenter cluster autoscaler tags
  }
}