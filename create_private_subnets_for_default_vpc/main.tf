
locals {
  region       = "us-west-1"
  environment  = "default"
  cluster_name = "test-eks"
  cidr_block   = [for k, v in data.aws_availability_zones.available.names:
                  cidrsubnet(data.aws_vpc.default.cidr_block, 4, k +length(data.aws_availability_zones.available.names))]
}

provider "aws" {
  region = local.region
}

data "aws_vpc" "default" {
  default = true
}

data "aws_availability_zones" "available" {}

data "aws_subnet_ids" "public" {
  vpc_id = data.aws_vpc.default.id

  filter {
    name   = "mapPublicIpOnLaunch"
    values = [true]
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = data.aws_vpc.default.id
  count                   = length(data.aws_availability_zones.available.names)
  cidr_block              = element(local.cidr_block, count.index)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = false
  tags = {
    Name        = "${local.environment}-${element(data.aws_availability_zones.available.names, count.index)}-private-subnet"
    Environment = local.environment
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
	Tier = "Private"
  }
}

resource "aws_route_table" "private" {
  vpc_id = data.aws_vpc.default.id
  tags = {
    Name        = "${local.environment}-private-route-table"
    Environment = local.environment
  }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private_subnet)
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = aws_route_table.private.id
}

resource "aws_ec2_tag" "subnet_tag" {
  count          = length(data.aws_subnet_ids.public.ids)
  resource_id = element(tolist(data.aws_subnet_ids.public.ids), count.index)
  key         = "Tier"
  value       = "Public"
}


resource "aws_eip" "nat_eip" {
  vpc        = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = tolist(data.aws_subnet_ids.public.ids)[0]
  tags = {
    Name        = "nat"
    Environment = local.environment
  }
}

resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}
