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

module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name    = local.cluster_name
  cluster_version = "1.21"
  
  #very important for creating alb controller on fargate  
  enable_irsa = true

  vpc_id          = local.vpc.vpc_id
  subnets         = [local.vpc.private_subnets[0],
                     local.vpc.private_subnets[1],
                     local.vpc.public_subnets[0],
                     local.vpc.public_subnets[1]]
  

  tags = {
    env = "production"    
  }
}

#############
# Kubernetes
#############

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

