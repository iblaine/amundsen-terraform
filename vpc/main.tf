locals {
  prefix_vpc = "${var.name}-${var.environment}-vpc"
  prefix_sg  = "${var.name}-${var.environment}-sg"
}

# create vpc
resource "aws_vpc" "main" {
  cidr_block           = var.cidr
  enable_dns_support   = true # intergration to route53, allows service discovery service, allows you to query aws hosts from route53
  enable_dns_hostnames = true # intergration to route53, allows service discovery service, allows you to query aws hosts from route53

  tags = {
    Name        = local.prefix_vpc
    Environment = var.environment
  }
}

# needed because we have a host publicly exposed
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${local.prefix_vpc}-igw"
    Environment = var.environment
  }
}

# distribute incoming traffic from public to frontend services
resource "aws_nat_gateway" "main" {
  count         = length(var.private_subnets)
  allocation_id = element(aws_eip.nat.*.id, count.index)
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  depends_on    = [aws_internet_gateway.main]

  tags = {
    Name        = "${local.prefix_vpc}-nat-${format("%03d", count.index+1)}"
    Environment = var.environment
  }
}

# eip for our nat
resource "aws_eip" "nat" {
  count = length(var.private_subnets)
  vpc = true

  tags = {
    Name        = "${local.prefix_vpc}-eip-${format("%03d", count.index+1)}"
    Environment = var.environment
  }
}

# eip for our nat
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.private_subnets, count.index)
  availability_zone = element(var.availability_zones, count.index)
  count             = length(var.private_subnets)

  tags = {
    Name        = "${local.prefix_vpc}-private-subnet-${format("%03d", count.index+1)}"
    Environment = var.environment
  }
}

# public subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.public_subnets, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  count                   = length(var.public_subnets)
  map_public_ip_on_launch = true

  tags = {
    Name        = "${local.prefix_vpc}-public-subnet-${format("%03d", count.index+1)}"
    Environment = var.environment
  }
}

# create empty public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${local.prefix_vpc}-routing-table-public"
    Environment = var.environment
  }
}

# create empty private route table, populate gateway
resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# create private subnet, empty w/vpc_id, number of route table to create
resource "aws_route_table" "private" {
  count  = length(var.private_subnets)
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${local.prefix_vpc}-routing-table-private-${format("%03d", count.index+1)}"
    Environment = var.environment
  }
}

# private route to nat gateway, for each subnet
resource "aws_route" "private" {
  count                  = length(compact(var.private_subnets))
  route_table_id         = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.main.*.id, count.index)
}

# attach route table to private subnet
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

# attach route table to private public
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}
