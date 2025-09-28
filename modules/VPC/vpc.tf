resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr              # e.g. 10.0.0.0/16
  enable_dns_support   = true                      # almost always true in prod
  enable_dns_hostnames = true

  tags = merge(
    var.common_tags,
    {
      Name        = local.name
      Environment = var.environment
      Owner       = var.owner
      CostCenter  = var.cost_center
    }
  )
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, { Name = "${local.name}-igw" })
}

# Explicit subnet CIDRs (safer in prod)
resource "aws_subnet" "public" {
  for_each = var.public_subnets # map of {az => cidr}
  vpc_id   = aws_vpc.main.id

  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = merge(
    var.common_tags,
    {
      Name                                        = "${local.name}-public-${each.key}"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
      "kubernetes.io/role/elb"                    = "1"
    }
  )
}

resource "aws_subnet" "private" {
  for_each = var.private_subnets
  vpc_id   = aws_vpc.main.id

  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = false

  tags = merge(
    var.common_tags,
    {
      Name                                        = "${local.name}-private-${each.key}"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
      "kubernetes.io/role/internal-elb"           = "1"
      "karpenter.sh/discovery"                    = var.cluster_name
    }
  )
}

# NAT Gateway per AZ (production-grade HA)
resource "aws_eip" "nat" {
  for_each = aws_subnet.public
  domain   = "vpc"

  tags = { Name = "${local.name}-nat-eip-${each.key}" }
}

resource "aws_nat_gateway" "nat" {
  for_each     = aws_subnet.public
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = each.value.id

  tags = { Name = "${local.name}-nat-${each.key}" }

  depends_on = [aws_internet_gateway.gw]
}

# Route tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${local.name}-public-rt" }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.gw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "public" {
  for_each      = aws_subnet.public
  subnet_id     = each.value.id
  route_table_id = aws_route_table.public.id
}

# Private route tables per AZ -> NAT
resource "aws_route_table" "private" {
  for_each = aws_nat_gateway.nat
  vpc_id   = aws_vpc.main.id
  tags     = { Name = "${local.name}-private-rt-${each.key}" }
}

resource "aws_route" "private_nat" {
  for_each             = aws_nat_gateway.nat
  route_table_id       = aws_route_table.private[each.key].id
  nat_gateway_id       = each.value.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

# VPC Flow Logs for audit
resource "aws_flow_log" "vpc" {
  vpc_id          = aws_vpc.main.id
  log_destination = aws_cloudwatch_log_group.vpc_logs.arn
  traffic_type    = "ALL"

  tags = { Name = "${local.name}-vpc-flowlogs" }
}

resource "aws_cloudwatch_log_group" "vpc_logs" {
  name              = "/aws/vpc/${local.name}"
  retention_in_days = 30
}
