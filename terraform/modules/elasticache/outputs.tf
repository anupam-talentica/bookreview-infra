output "redis_primary_endpoint" {
  description = "The address of the endpoint for the primary node in the replication group"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "redis_reader_endpoint" {
  description = "The address of the endpoint for the reader node in the replication group"
  value       = aws_elasticache_replication_group.main.reader_endpoint_address
}

output "redis_port" {
  description = "The port number on which the Redis endpoint is accepting connections"
  value       = aws_elasticache_replication_group.main.port
}

output "redis_security_group_ids" {
  description = "The IDs of the security groups associated with the Redis cluster"
  value       = aws_elasticache_replication_group.main.security_group_ids
}

output "redis_replication_group_id" {
  description = "The ID of the ElastiCache Replication Group"
  value       = aws_elasticache_replication_group.main.id
}
