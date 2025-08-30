# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name        = "${var.environment}-db-subnet-group"
  description = "Database subnet group for ${var.environment}"
  subnet_ids  = var.private_subnet_ids
  
  tags = {
    Name        = "${var.environment}-db-subnet-group"
    Environment = var.environment
  }
}

# RDS Parameter Group
resource "aws_db_parameter_group" "main" {
  name        = "${var.environment}-postgres-pg"
  family      = "postgres17"
  description = "Parameter group for ${var.environment} PostgreSQL database"
  
  parameter {
    name  = "log_statement"
    value = "all"
  }
  
  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }
  
  tags = {
    Name        = "${var.environment}-postgres-pg"
    Environment = var.environment
  }
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "main" {
  identifier             = "${var.environment}-postgres-db"
  engine                 = "postgres"
  engine_version         = "17.6"
  instance_class         = "db.t3.micro"  # Cheapest non-burstable is db.t4g.micro (ARM-based, ~20% cheaper)
  allocated_storage      = 10              # Minimum is 10GB
  max_allocated_storage  = 20              # Reduced from 100GB to 20GB
  storage_type           = "gp3"
  storage_encrypted      = true
  
  # Allow major version upgrades
  allow_major_version_upgrade = true
  
  # Apply changes immediately
  apply_immediately      = true
  
  # Performance Insights (disable for cost savings)
  performance_insights_enabled = false
  
  # Disable enhanced monitoring to reduce costs
  monitoring_interval    = 0
  
  # Disable deletion protection for easier cleanup (enable for production)
  deletion_protection    = false
  
  # Skip final snapshot for easier cleanup (set to false for production)
  skip_final_snapshot    = true
  
  # Reduce backup retention to minimum (0-35 days, 0 disables automated backups)
  backup_retention_period = 1
  
  # Set backup window to a non-peak time
  backup_window          = "02:00-03:00"
  
  # Database credentials
  username = var.db_username
  password = var.db_password
  db_name  = var.db_name
  
  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = var.db_security_groups
  
  # Multi-AZ configuration (disabled for cost savings, enable for production)
  multi_az               = false
  
  # Maintenance window
  maintenance_window     = "sun:03:00-sun:04:00"
  
  # Disable minor version upgrades to prevent unexpected changes
  auto_minor_version_upgrade = false
  
  # Apply the parameter group
  parameter_group_name   = aws_db_parameter_group.main.name
  
  tags = {
    Name        = "${var.environment}-postgres-db"
    Environment = var.environment
    CostCenter  = "bookreview-${var.environment}"
  }
  
  depends_on = [
    aws_db_parameter_group.main,
    aws_db_subnet_group.main
  ]
}

# IAM Role for Enhanced Monitoring
resource "aws_iam_role" "rds_enhanced_monitoring" {
  name = "${var.environment}-rds-enhanced-monitoring-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
  
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"]
  
  tags = {
    Name        = "${var.environment}-rds-enhanced-monitoring-role"
    Environment = var.environment
  }
}
