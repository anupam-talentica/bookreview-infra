# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "main" {
  name        = "${var.environment}-redis-subnet-group"
  description = "Subnet group for ElastiCache Redis"
  subnet_ids  = var.private_subnet_ids
  
  tags = {
    Name        = "${var.environment}-redis-subnet-group"
    Environment = var.environment
  }
}

# ElastiCache Parameter Group
resource "aws_elasticache_parameter_group" "main" {
  name        = "${var.environment}-redis-params"
  family      = "redis6.x"
  description = "Parameter group for ${var.environment} Redis cluster"
  
  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }
  
  parameter {
    name  = "notify-keyspace-events"
    value = "lK"
  }
  
  tags = {
    Name        = "${var.environment}-redis-params"
    Environment = var.environment
  }
}

# ElastiCache Redis Cluster
resource "aws_elasticache_replication_group" "main" {
  replication_group_id          = "${var.environment}-redis"
  replication_group_description = "Redis cluster for ${var.environment}"
  
  # Node configuration - using the smallest instance type
  node_type            = "cache.t4g.micro"  # ARM-based, cheaper than t3.micro
  port                 = 6379
  parameter_group_name = aws_elasticache_parameter_group.main.name
  
  # Network configuration
  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = var.cache_security_groups
  
  # Multi-AZ and failover (disabled for cost savings)
  automatic_failover_enabled = false
  multi_az_enabled          = false
  
  # Redis version and configuration
  engine         = "redis"
  engine_version = var.engine_version
  
  # Data persistence (disabled for cost savings, but increases risk of data loss)
  snapshot_retention_limit = 0  # Disable automatic backups
  snapshot_window         = ""  # Clear the snapshot window
  
  # Maintenance window (set to non-peak hours)
  maintenance_window = "sun:04:00-sun:05:00"
  
  # Disable auto minor version upgrade
  auto_minor_version_upgrade = false
  
  # Security (enabling encryption has minimal cost impact)
  at_rest_encryption_enabled  = true
  transit_encryption_enabled  = false
  
  # Scaling - single node for minimal cost
  num_cache_clusters = 1
  
  # Use cluster mode disabled for single shard
  cluster_mode {
    replicas_per_node_group = 0  # No replicas for minimal cost
    num_node_groups         = 1  # Single shard
  }
  
  tags = {
    Name        = "${var.environment}-redis"
    Environment = var.environment
    CostCenter  = "bookreview-${var.environment}"
  }
  
  depends_on = [
    aws_elasticache_parameter_group.main,
    aws_elasticache_subnet_group.main
  ]
}
