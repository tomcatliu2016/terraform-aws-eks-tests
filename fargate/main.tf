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

module "fargate_profile_existing_cluster" {
  source = "terraform-aws-modules/eks/aws//modules/fargate"
  version = "17.22.0"
  cluster_name = local.cluster_name
  subnets      = [local.vpc.private_subnets[0], local.vpc.private_subnets[1]]

  fargate_profiles = {
    default = {
      name = "default"
      selectors = [
        {
          namespace = "kube-system"
        },
        {
          namespace = "default"
        }
      ]

      tags = {
        Owner = "default"
      }
    },
	game = {
      name = "game-2048"
      selectors = [
        {
          namespace = "game-2048"
        }
      ]

      tags = {
        Owner = "game"
      }
    }
  }
}


#############
# Kubernetes
#############

data "aws_eks_cluster" "cluster" {
  name = local.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = local.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}


