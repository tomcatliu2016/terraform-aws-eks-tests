output "region" {
  description = "AWS region"
  value       = local.region
}

output "vpc" {
  description = "Complete output of VPC module"
  value       = {
    vpc_id: data.aws_vpc.default.id
	private_subnets: aws_subnet.private_subnet.*.id
	public_subnets: tolist(data.aws_subnet_ids.public.ids)
  }
}
