
locals {
  region       = "us-west-1"
  environment  = "default"  
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

output "test" {
  description = "Name of EKS Cluster used in tags for subnets"
  value       = {
    cidr_block              = [for k, v in data.aws_availability_zones.available.names:
                              cidrsubnet(data.aws_vpc.default.cidr_block, 4, k +length(data.aws_availability_zones.available.names))]
    availability_zone       = data.aws_availability_zones.available.names
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
  count          = length(data.aws_availability_zones.available.names)
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = aws_route_table.private.id
}

resource "aws_ec2_tag" "subnet_tag" {
  count          = length(data.aws_subnet_ids.public.ids)
  resource_id = element(tolist(data.aws_subnet_ids.public.ids), count.index)
  key         = "Tier"
  value       = "Public"
}
