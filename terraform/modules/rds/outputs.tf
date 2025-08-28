output "rds_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = aws_db_instance.main.endpoint
}

output "rds_identifier" {
  description = "The RDS instance identifier"
  value       = aws_db_instance.main.identifier
}

output "rds_username" {
  description = "The master username for the RDS instance"
  value       = aws_db_instance.main.username
  sensitive   = true
}

output "rds_database_name" {
  description = "The name of the database"
  value       = aws_db_instance.main.db_name
}

output "db_subnet_group_name" {
  description = "The name of the DB subnet group"
  value       = aws_db_subnet_group.main.name
}
