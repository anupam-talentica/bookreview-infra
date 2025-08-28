terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
}

# Import all the modules
module "vpc" {
  source = "./modules/vpc"
  
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones  = var.availability_zones
  environment         = var.environment
}

module "security_groups" {
  source = "./modules/security_groups"
  
  vpc_id      = module.vpc.vpc_id
  environment = var.environment
}

module "rds" {
  source = "./modules/rds"
  
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  db_security_groups = [module.security_groups.rds_security_group_id]
  db_username        = var.db_username
  db_password        = var.db_password
  db_name            = var.db_name
  environment        = var.environment
}

module "elasticache" {
  source = "./modules/elasticache"
  
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  cache_security_groups  = [module.security_groups.elasticache_security_group_id]
  environment           = var.environment
  node_type             = var.redis_node_type
  num_cache_nodes       = var.redis_num_cache_nodes
  parameter_group_name  = var.redis_parameter_group_name
  engine_version        = var.redis_engine_version
}
