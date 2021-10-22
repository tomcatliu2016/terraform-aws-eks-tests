output "region" {
  description = "AWS region"
  value       = local.region
}

output "cluster_name" {
  description = "Name of EKS Cluster used in tags for subnets"
  value       = local.cluster_name
}

output "vpc" {
  description = "Complete output of VPC module"
  value       = {
    vpc_id: data.aws_vpc.selected.id
	private_subnets: tolist(data.aws_subnet_ids.private.ids)
	public_subnets: tolist(data.aws_subnet_ids.public.ids)
    cidr_blocks: data.aws_vpc.selected.cidr_block
  }
}
