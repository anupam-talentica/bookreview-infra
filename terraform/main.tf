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
  
  environment           = var.environment
  vpc_id               = module.vpc.vpc_id
  private_subnet_ids   = module.vpc.private_subnet_ids
  aws_region          = var.aws_region
  db_endpoint         = module.rds.rds_endpoint
  db_name             = var.db_name
  db_username         = var.db_username
  db_password         = var.db_password
  ecr_repository_url  = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/bookreview-backend"
  alb_arn             = aws_lb.main.arn
  alb_security_group_id = module.security_groups.alb_security_group_id
}

data "aws_caller_identity" "current" {}

# S3 Buckets for Frontend Hosting
resource "aws_s3_bucket" "frontend_production" {
  bucket = "bookreview-frontend"

  tags = {
    Environment = var.environment
    Name        = "bookreview-frontend"
    Purpose     = "Frontend hosting - Production"
  }
}

resource "aws_s3_bucket" "frontend_staging" {
  bucket = "bookreview-frontend-staging"

  tags = {
    Environment = "staging"
    Name        = "bookreview-frontend-staging"
    Purpose     = "Frontend hosting - Staging"
  }
}

# S3 Bucket for Images (Backend)
resource "aws_s3_bucket" "images" {
  bucket = "bookreview-images-${var.environment}"

  tags = {
    Environment = var.environment
    Name        = "bookreview-images-${var.environment}"
    Purpose     = "Image storage"
  }
}

# S3 Bucket Website Configuration
resource "aws_s3_bucket_website_configuration" "frontend_production" {
  bucket = aws_s3_bucket.frontend_production.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_website_configuration" "frontend_staging" {
  bucket = aws_s3_bucket.frontend_staging.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# S3 Bucket Public Access Configuration
resource "aws_s3_bucket_public_access_block" "frontend_production" {
  bucket = aws_s3_bucket.frontend_production.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_public_access_block" "frontend_staging" {
  bucket = aws_s3_bucket.frontend_staging.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_public_access_block" "images" {
  bucket = aws_s3_bucket.images.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# S3 Bucket Policy for Frontend (Public Read)
resource "aws_s3_bucket_policy" "frontend_production" {
  bucket = aws_s3_bucket.frontend_production.id
  depends_on = [aws_s3_bucket_public_access_block.frontend_production]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend_production.arn}/*"
      },
    ]
  })
}

resource "aws_s3_bucket_policy" "frontend_staging" {
  bucket = aws_s3_bucket.frontend_staging.id
  depends_on = [aws_s3_bucket_public_access_block.frontend_staging]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend_staging.arn}/*"
      },
    ]
  })
}
