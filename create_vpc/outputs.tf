output "region" {
  description = "AWS region"
  value       = local.region
}

output "vpc" {
  description = "Complete output of VPC module"
  value       = module.vpc
}
