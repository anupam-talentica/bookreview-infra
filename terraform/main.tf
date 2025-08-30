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
  aws_region          = var.aws_region
}

module "security_groups" {
  source = "./modules/security_groups"
  
  vpc_id      = module.vpc.vpc_id
  vpc_cidr    = var.vpc_cidr
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

# ALB for ECS
resource "aws_lb" "main" {
  name               = "${var.environment}-bookreview-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.security_groups.alb_security_group_id]
  subnets            = module.vpc.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Environment = var.environment
    Name        = "${var.environment}-bookreview-alb"
  }
}

# ECS Module
module "ecs" {
  source = "./modules/ecs"
  
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  aws_region        = var.aws_region
  db_endpoint       = module.rds.rds_endpoint
  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password
  ecr_repository_url = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/bookreview-backend"
  alb_arn           = aws_lb.main.arn
}

data "aws_caller_identity" "current" {}
