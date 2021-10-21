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


data "aws_eks_cluster" "target" {
  name = local.cluster_name
}

data "aws_eks_cluster_auth" "aws_iam_authenticator" {
  name = data.aws_eks_cluster.target.name
}

data "aws_region" "current" {}

provider "aws" {
  region = local.region
}

provider "kubernetes" {
  alias = "eks"
  host                   = data.aws_eks_cluster.target.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.target.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.aws_iam_authenticator.token  
}

provider "helm" {
  alias = "eks"
  kubernetes {
    host                   = data.aws_eks_cluster.target.endpoint
    token                  = data.aws_eks_cluster_auth.aws_iam_authenticator.token
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.target.certificate_authority[0].data)
  }
}

module "alb" {
  source  = "github.com/GSA/terraform-kubernetes-aws-load-balancer-controller"  
  
  providers = {
    kubernetes = kubernetes.eks
	helm       = helm.eks
  }
  
  k8s_cluster_type = "eks"
  k8s_cluster_name = data.aws_eks_cluster.target.name
  k8s_namespace = "kube-system"  
  aws_region_name = data.aws_region.current.name
  aws_resource_name_prefix = "${data.aws_eks_cluster.target.name}-"  
  alb_controller_depends_on = data.aws_eks_cluster.target
}
