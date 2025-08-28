variable "vpc_id" {
  description = "The ID of the VPC where the RDS instance will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the RDS subnet group"
  type        = list(string)
}

variable "db_security_groups" {
  description = "List of security group IDs to attach to the RDS instance"
  type        = list(string)
}

variable "db_username" {
  description = "Username for the master DB user"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Password for the master DB user"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Name for the database"
  type        = string
  default     = "bookreviewdb"
}

variable "environment" {
  description = "Environment name"
  type        = string
}
