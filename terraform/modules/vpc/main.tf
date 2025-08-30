# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
    CostCenter  = "bookreview-${var.environment}"
  }
}

# Public Subnets (minimal for NAT Gateway)
resource "aws_subnet" "public" {
  count                   = min(2, length(var.availability_zones))  # Create in 2 AZs for high availability
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)  # 10.0.0.0/24, 10.0.1.0/24
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name        = "${var.environment}-public-${count.index + 1}"
    Environment = var.environment
    Type        = "public"
    CostCenter  = "bookreview-${var.environment}"
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count             = min(2, length(var.availability_zones))  # Create in 2 AZs for high availability
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 10 + count.index)  # 10.0.10.0/24, 10.0.11.0/24
  availability_zone = var.availability_zones[count.index]
  
  tags = {
    Name        = "${var.environment}-private-${count.index + 1}"
    Environment = var.environment
    Type        = "private"
    CostCenter  = "bookreview-${var.environment}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name        = "${var.environment}-igw"
    Environment = var.environment
    CostCenter  = "bookreview-${var.environment}"
  }
}

# Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name        = "${var.environment}-public-rt"
    Environment = var.environment
    CostCenter  = "bookreview-${var.environment}"
  }
}

# Route Table Association for Public Subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public[0].id
  route_table_id = aws_route_table.public.id
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
  
  tags = {
    Name        = "${var.environment}-nat-eip"
    Environment = var.environment
    CostCenter  = "bookreview-${var.environment}"
  }
  
  # Ensure EIP is released when NAT is deleted
  depends_on = [aws_internet_gateway.main]
}

# NAT Gateway (smallest size)
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id  # Only need one NAT Gateway for cost optimization
  
  tags = {
    Name        = "${var.environment}-nat"
    Environment = var.environment
    CostCenter  = "bookreview-${var.environment}"
  }
  
  depends_on = [aws_internet_gateway.main]
}

# Route Table for Private Subnet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
  
  tags = {
    Name        = "${var.environment}-private-rt"
    Environment = var.environment
    CostCenter  = "bookreview-${var.environment}"
  }
}

# Output the private subnet IDs for ALB and other resources
output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

# Route Table Association for Private Subnets
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# VPC Endpoint for S3 (to save on NAT Gateway data transfer costs)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  
  route_table_ids = [
    aws_route_table.private.id
  ]
  
  tags = {
    Name        = "${var.environment}-s3-endpoint"
    Environment = var.environment
    CostCenter  = "bookreview-${var.environment}"
  }
}
