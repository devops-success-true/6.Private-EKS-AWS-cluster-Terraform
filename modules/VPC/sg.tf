resource "aws_security_group" "allow_tls" {
  name        = "${local.name}-bastion-sg"
  description = "Restricted SSH/VPN access for bastion"
  vpc_id      = aws_vpc.main.id

  # SSH access (restrict to office/VPN CIDR)
  ingress {
    description = "SSH from corporate network"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.corporate_vpn_cidr] # e.g. "203.0.113.0/24"
  }

  # OpenVPN access (if really needed, also restrict)
  ingress {
    description = "OpenVPN from corporate network"
    from_port   = 1194
    to_port     = 1194
    protocol    = "tcp"
    cidr_blocks = [var.corporate_vpn_cidr]
  }

  # Outbound traffic (default allow all is common)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "${local.name}-bastion-sg" })
}

#########################################
# Security Group for EKS Cluster
#########################################
resource "aws_security_group" "cluster_sg" {
  name        = "${local.name}-eks-cluster-sg"
  description = "Restrict access to EKS API endpoint"
  vpc_id      = aws_vpc.main.id

  # Allow node groups to connect to control plane (443)
  ingress {
    description     = "Worker nodes to EKS API"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.node_sg.id] # safer than 0.0.0.0/0
  }

  # Outbound access (needed for API to talk back to nodes, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.common_tags,
    {
      Name                                        = "${local.name}-eks-cluster-sg"
      "karpenter.sh/discovery"                    = var.cluster_name
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
  )
}

#########################################
# (Recommended) Security Group for Nodes
#########################################
resource "aws_security_group" "node_sg" {
  name        = "${local.name}-eks-nodes-sg"
  description = "EKS worker nodes"
  vpc_id      = aws_vpc.main.id

  # Allow nodes to talk to each other
  ingress {
    description = "Node-to-node communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # Allow inbound from cluster SG (API server calls back)
  ingress {
    description     = "Control plane to kubelet"
    from_port       = 10250
    to_port         = 10250
    protocol        = "tcp"
    security_groups = [aws_security_group.cluster_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "${local.name}-eks-nodes-sg" })
}
