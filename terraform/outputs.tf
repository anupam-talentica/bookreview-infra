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

# ElastiCache Outputs
output "redis_primary_endpoint" {
  description = "The address of the endpoint for the primary node in the Redis replication group"
  value       = module.elasticache.redis_primary_endpoint
}

output "redis_reader_endpoint" {
  description = "The address of the endpoint for the reader node in the Redis replication group"
  value       = module.elasticache.redis_reader_endpoint
}

output "redis_port" {
  description = "The port number on which the Redis endpoint is accepting connections"
  value       = module.elasticache.redis_port
}
