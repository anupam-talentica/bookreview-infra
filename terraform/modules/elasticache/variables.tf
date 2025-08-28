variable "vpc_id" {
  description = "The ID of the VPC where the ElastiCache cluster will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the ElastiCache subnet group"
  type        = list(string)
}

variable "cache_security_groups" {
  description = "List of security group IDs to attach to the ElastiCache cluster"
  type        = list(string)
}

variable "node_type" {
  description = "Instance type for Redis nodes"
  type        = string
  default     = "cache.t3.micro"
}

variable "num_cache_nodes" {
  description = "Number of cache nodes for Redis"
  type        = number
  default     = 1
}

variable "parameter_group_name" {
  description = "Name of the parameter group for Redis"
  type        = string
  default     = "default.redis6.x"
}

variable "engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "6.x"
}

variable "environment" {
  description = "Environment name"
  type        = string
}
