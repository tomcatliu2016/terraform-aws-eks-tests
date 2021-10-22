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
  environment  = "default"
}

provider "aws" {
  region = local.region
}

resource "aws_security_group" "eks_to_efs" {
  name        = "eks_efs_sg"
  description = "allow eks cluster to access"
  vpc_id      = local.vpc.vpc_id
  ingress {
    from_port = "2049"
    to_port   = "2049"
    protocol  = "tcp"
    cidr_blocks = [local.vpc.cidr_blocks]
    self      = true
  }

  egress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
  }
  tags = {
    Environment = "eks"
    Name = "eks_efs_sg"
  }
}
