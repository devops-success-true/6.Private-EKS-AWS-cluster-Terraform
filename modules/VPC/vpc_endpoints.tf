#############################################
# VPC Endpoints for Session Manager & SSM
#############################################

# SSM Endpoint
resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [for s in aws_subnet.private : s.id]

  tags = {
    Name = "${local.name}-ssm-endpoint"
  }
}

# EC2 Messages Endpoint
resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [for s in aws_subnet.private : s.id]

  tags = {
    Name = "${local.name}-ec2messages-endpoint"
  }
}

# SSM Messages Endpoint
resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [for s in aws_subnet.private : s.id]

  # NOTE: No custom security group IDs needed.
  # AWS auto-creates a managed SG for interface endpoints.
  # Uncomment below only if compliance requires custom SGs.
  # security_group_ids = [
  #   aws_security_group.vpc_endpoints_sg.id,
  # ]

  tags = {
    Name = "${local.name}-ssmmessages-endpoint"
  }
}
