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

# S3 Outputs
output "frontend_production_bucket" {
  description = "Name of the production frontend S3 bucket"
  value       = aws_s3_bucket.frontend_production.id
}

output "frontend_staging_bucket" {
  description = "Name of the staging frontend S3 bucket"
  value       = aws_s3_bucket.frontend_staging.id
}

output "images_bucket" {
  description = "Name of the images S3 bucket"
  value       = aws_s3_bucket.images.id
}

output "frontend_production_website_endpoint" {
  description = "Website endpoint for production frontend bucket"
  value       = aws_s3_bucket_website_configuration.frontend_production.website_endpoint
}

output "frontend_staging_website_endpoint" {
  description = "Website endpoint for staging frontend bucket"
  value       = aws_s3_bucket_website_configuration.frontend_staging.website_endpoint
}

