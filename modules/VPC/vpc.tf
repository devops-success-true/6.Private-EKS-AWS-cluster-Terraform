resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  instance_tenancy     = "default"
  enable_dns_support   = var.enable_dns_support

  tags = merge(
    var.common_tags,
    var.vpc_tags,
    {
      Name = local.name
    }
  )
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    var.igw_tags,
    {
      Name = local.name
    }
  )
}

resource "aws_subnet" "public" {
  count                   = var.pub_subnet_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 1) #New Bits: 8 (Expanding the network from /16 to /24)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name                                        = "Public Subnet-${count.index + 1}"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned" # owned or shared
      "kubernetes.io/role/elb"                    = "1"     # true or 1
    }
  )

}

resource "aws_subnet" "private" {
  count                   = var.pri_subnet_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 3) # 1 means 192.168.1.0/24
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      Name                                            = "Private Subnet-${count.index + 1}"
      "kubernetes.io/cluster/${var.cluster_name}"     = "owned" # owned or shared
      "kubernetes.io/role/internal-elb"               = "1"     # true or 1
      "karpenter.sh/discovery"                 = var.cluster_name #karpenter cluster autoscaler tags
    }
  )
}

resource "aws_eip" "eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(
    var.common_tags,
    var.nat_gateway_tags,
    {
      Name = "${local.name}"
    }
  )

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = var.tags
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = var.tags
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.gw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private.id
  nat_gateway_id         = aws_nat_gateway.main.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "public" {
  count          = var.pub_subnet_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = var.pri_subnet_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}