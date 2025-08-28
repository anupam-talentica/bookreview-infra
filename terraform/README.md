# AWS Infrastructure for Book Review Application

This Terraform configuration sets up the AWS infrastructure for the Book Review application, including:

- VPC with public and private subnets
- RDS PostgreSQL database with Multi-AZ deployment
- ElastiCache Redis cluster
- Security groups and networking components

## Prerequisites

1. Install [Terraform](https://www.terraform.io/downloads.html) (>= 1.2.0)
2. Configure AWS credentials with appropriate permissions
3. Copy `terraform.tfvars.example` to `terraform.tfvars` and update with your values

## Directory Structure

```
infrastructure/terraform/
├── main.tf              # Main Terraform configuration
├── variables.tf         # Variable declarations
├── outputs.tf           # Output values
├── terraform.tfvars     # Variable values (not version controlled)
├── terraform.tfvars.example  # Example variable values
└── modules/
    ├── vpc/             # VPC and networking components
    ├── security_groups/ # Security group definitions
    ├── rds/            # RDS PostgreSQL configuration
    └── elasticache/    # ElastiCache Redis configuration
```

## Usage

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Review the execution plan:
   ```bash
   terraform plan
   ```

3. Apply the configuration:
   ```bash
   terraform apply
   ```

4. To destroy all resources:
   ```bash
   terraform destroy
   ```

## Variables

### Required Variables

- `db_username`: Username for the RDS master user
- `db_password`: Password for the RDS master user

### Optional Variables

- `aws_region`: AWS region (default: "us-west-2")
- `environment`: Environment name (default: "dev")
- `vpc_cidr`: CIDR block for VPC (default: "10.0.0.0/16")
- `public_subnet_cidrs`: List of public subnet CIDRs (default: ["10.0.1.0/24", "10.0.2.0/24"])
- `private_subnet_cidrs`: List of private subnet CIDRs (default: ["10.0.3.0/24", "10.0.4.0/24"])
- `db_name`: Database name (default: "bookreviewdb")
- `redis_node_type`: ElastiCache node type (default: "cache.t3.micro")
- `redis_num_cache_nodes`: Number of cache nodes (default: 1)

## Outputs

- RDS endpoint and credentials
- Redis primary and reader endpoints
- VPC and subnet IDs
- Security group IDs

## Security Notes

- Database credentials are marked as sensitive and will not be displayed in the console output
- RDS instances are deployed in private subnets
- Security groups are configured to allow access only from within the VPC
- Encryption at rest and in transit is enabled where supported
