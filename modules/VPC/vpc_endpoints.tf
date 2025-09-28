#############################################
# VPC Endpoints for Session Manager & SSM
#############################################

# SSM Endpoint
# Purpose: Allows private instances/EKS worker nodes to connect to the AWS Systems Manager service
# without routing traffic over the internet (uses VPC private network instead).
resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type = "Interface"

  # These endpoints are created inside private subnets so worker nodes can use them.
  subnet_ids = [for s in aws_subnet.private : s.id]

  tags = {
    Name = "${local.name}-ssm-endpoint"
  }
}

# EC2 Messages Endpoint
# Purpose: Required for SSM Agent on EC2 instances/EKS nodes to receive commands
# sent from Systems Manager (SSM). Keeps communication private within the VPC.
resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type = "Interface"

  subnet_ids = [for s in aws_subnet.private : s.id]

  tags = {
    Name = "${local.name}-ec2messages-endpoint"
  }
}

# SSM Messages Endpoint
# Purpose: Used by Session Manager to handle interactive shell sessions (e.g., when you open
# `StartSession` in the AWS console or CLI). Ensures session traffic never leaves the VPC.
resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type = "Interface"
  
  subnet_ids = [for s in aws_subnet.private : s.id]

  # NOTE: Leaving security_group_ids commented is best practice.
  # AWS auto-manages an endpoint SG that already allows inbound from the VPC.
  # Uncomment and provide a custom SG only if compliance requires strict control.
  # security_group_ids = [
  #   aws_security_group.vpc_endpoints_sg.id,
  # ]

  tags = {
    Name = "${local.name}-ssmmessages-endpoint"
  }
}
