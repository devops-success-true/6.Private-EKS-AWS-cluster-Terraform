###############################################
# EKS Cluster IAM Role
# Purpose: Role assumed by the EKS control plane
###############################################
resource "aws_iam_role" "clusterrole" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        },
        Action = ["sts:AssumeRole", "sts:TagSession"]
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name        = "${var.cluster_name}-cluster-role"
    Environment = var.environment
  })
}

# Grants control plane permissions to manage EKS
resource "aws_iam_role_policy_attachment" "cluster_eks" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.clusterrole.name
}

# Allows EKS to manage VPC resources (ENIs, SGs, IPs)
resource "aws_iam_role_policy_attachment" "cluster_vpc" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.clusterrole.name
}

###############################################
# EKS Node IAM Role
# Purpose: Role assumed by EKS worker nodes (EC2)
###############################################
resource "aws_iam_role" "noderole" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name        = "${var.cluster_name}-node-role"
    Environment = var.environment
  })
}

# Lets kubelet register nodes and talk to control plane
resource "aws_iam_role_policy_attachment" "node_worker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.noderole.name
}

# Allows CNI plugin to manage ENIs and pod networking
resource "aws_iam_role_policy_attachment" "node_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.noderole.name
}

# Enables pulling container images from Amazon ECR
resource "aws_iam_role_policy_attachment" "node_ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.noderole.name
}

# Allows pods to provision and attach EBS volumes
resource "aws_iam_role_policy_attachment" "node_ebs_csi" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.noderole.name
}

# Enables Session Manager (SSM) access for EC2 nodes
resource "aws_iam_role_policy_attachment" "node_ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.noderole.name
}
