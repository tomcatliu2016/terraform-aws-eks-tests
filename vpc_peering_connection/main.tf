data "terraform_remote_state" "common_data" {
  backend = "local"

  config = {
    path = "../common_data/terraform.tfstate"
  }
}

locals {
  region       = data.terraform_remote_state.common_data.outputs.region
  cluster_name = data.terraform_remote_state.common_data.outputs.cluster_name
  vpc          = data.terraform_remote_state.common_data.outputs.vpc
}

provider "aws" {
  region = local.region
}


data "aws_vpc" "default" {
  default = true
}

module "vpc_peering" {
  source = "cloudposse/vpc-peering/aws"
  # Cloud Posse recommends pinning every module to a specific version
  # version = "x.x.x"
  namespace          = "eg"
  stage              = "dev"
  name               = "cluster"
  requestor_vpc_id = data.aws_vpc.default.id
  acceptor_vpc_id  = local.vpc.vpc_id
}