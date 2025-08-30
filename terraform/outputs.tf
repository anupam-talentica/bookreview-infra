# VPC Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

# RDS Outputs
output "rds_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = module.rds.rds_endpoint
}

output "rds_identifier" {
  description = "The RDS instance identifier"
  value       = module.rds.rds_identifier
}

output "rds_database_name" {
  description = "The name of the database"
  value       = module.rds.rds_database_name
}

