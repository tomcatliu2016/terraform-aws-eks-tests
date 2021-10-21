data "terraform_remote_state" "vpc" {
  backend = "local"

  config = {
    path = "../create_private_subnets_for_default_vpc/terraform.tfstate"
  }
}

locals {
  region       = data.terraform_remote_state.vpc.outputs.region  
  vpc          = data.terraform_remote_state.vpc.outputs.vpc
  cluster_name = "test-eks"
}

provider "aws" {
  region = local.region
}

data "aws_vpc" "selected" {
  id = local.vpc.vpc_id
}

data "aws_subnet_ids" "private" {
  vpc_id = local.vpc.vpc_id

  tags = {
    Tier = "Private"
  }
}

data "aws_subnet_ids" "public" {
  vpc_id = local.vpc.vpc_id

  tags = {
    Tier = "Public"
  }
}
