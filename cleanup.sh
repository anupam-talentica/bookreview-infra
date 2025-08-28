#!/bin/bash

# Exit on error
set -e

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install it first."
    exit 1
fi

# Load environment variables from terraform.tfvars if it exists
if [ -f "terraform/terraform.tfvars" ]; then
    echo "Loading variables from terraform.tfvars..."
    ENVIRONMENT=$(grep -E '^environment\s*=' terraform/terraform.tfvars | awk -F'"' '{print $2}')
    AWS_REGION=$(grep -E '^aws_region\s*=' terraform/terraform.tfvars | awk -F'"' '{print $2}')
    
    # Set AWS region
    export AWS_DEFAULT_REGION=${AWS_REGION:-"us-west-2"}
    ENVIRONMENT=${ENVIRONMENT:-"dev"}
else
    echo "Warning: terraform.tfvars not found. Using default values."
    export AWS_DEFAULT_REGION="us-west-2"
    ENVIRONMENT="dev"
fi

echo "Starting cleanup for environment: $ENVIRONMENT in region: $AWS_DEFAULT_REGION"
echo "----------------------------------------"

# Function to delete resources with retries
function delete_with_retry() {
    local resource_type=$1
    local resource_ids=("${@:2}")
    
    for id in "${resource_ids[@]}"; do
        echo "Deleting $resource_type: $id"
        max_retries=5
        retry_count=0
        
        while [ $retry_count -lt $max_retries ]; do
            case $resource_type in
                "RDS Instance")
                    aws rds delete-db-instance \
                        --db-instance-identifier "$id" \
                        --skip-final-snapshot \
                        --delete-automated-backups && break
                    ;;
                "ElastiCache Replication Group")
                    aws elasticache delete-replication-group \
                        --replication-group-id "$id" \
                        --retain-primary-cluster && break
                    ;;
                "ElastiCache Parameter Group")
                    aws elasticache delete-cache-parameter-group \
                        --cache-parameter-group-name "$id" && break
                    ;;
                "ElastiCache Subnet Group")
                    aws elasticache delete-cache-subnet-group \
                        --cache-subnet-group-name "$id" && break
                    ;;
                "RDS Subnet Group")
                    aws rds delete-db-subnet-group \
                        --db-subnet-group-name "$id" && break
                    ;;
                "RDS Parameter Group")
                    aws rds delete-db-parameter-group \
                        --db-parameter-group-name "$id" && break
                    ;;
                "Security Group")
                    # First, revoke all ingress and egress rules
                    aws ec2 revoke-security-group-ingress \
                        --group-id "$id" \
                        --ip-permissions "$(aws ec2 describe-security-groups --group-ids "$id" --query 'SecurityGroups[0].IpPermissions' --output json)" 2>/dev/null || true
                    
                    aws ec2 revoke-security-group-egress \
                        --group-id "$id" \
                        --ip-permissions "$(aws ec2 describe-security-groups --group-ids "$id" --query 'SecurityGroups[0].IpPermissionsEgress' --output json)" 2>/dev/null || true
                    
                    # Then delete the security group
                    aws ec2 delete-security-group --group-id "$id" && break
                    ;;
                *)
                    echo "Unknown resource type: $resource_type"
                    return 1
                    ;;
            esac
            
            retry_count=$((retry_count + 1))
            echo "Retry $retry_count of $max_retries for $resource_type: $id"
            sleep 10
        done
        
        if [ $retry_count -eq $max_retries ]; then
            echo "Warning: Failed to delete $resource_type: $id after $max_retries attempts"
        else
            echo "Successfully deleted $resource_type: $id"
        fi
    done
}

# Get VPC ID
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Environment,Values=$ENVIRONMENT" --query 'Vpcs[0].VpcId' --output text)

if [ "$VPC_ID" != "None" ] && [ ! -z "$VPC_ID" ]; then
    echo "Found VPC: $VPC_ID"
    
    # Delete NAT Gateway
    echo "Deleting NAT Gateway..."
    NAT_GATEWAY_ID=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" --query 'NatGateways[?State==`available`].NatGatewayId' --output text)
    if [ ! -z "$NAT_GATEWAY_ID" ]; then
        aws ec2 delete-nat-gateway --nat-gateway-id "$NAT_GATEWAY_ID"
        echo "Waiting for NAT Gateway to be deleted..."
        aws ec2 wait nat-gateway-deleted --nat-gateway-ids "$NAT_GATEWAY_ID"
        echo "NAT Gateway deleted: $NAT_GATEWAY_ID"
    fi
    
    # Release Elastic IPs
    echo "Releasing Elastic IPs..."
    EIP_ALLOCATION_IDS=$(aws ec2 describe-addresses --filters "Name=domain,Values=vpc" --query "Addresses[?InstanceId==null].AllocationId" --output text)
    for ALLOC_ID in $EIP_ALLOCATION_IDS; do
        aws ec2 release-address --allocation-id "$ALLOC_ID"
        echo "Released Elastic IP: $ALLOC_ID"
    done
    
    # Delete Internet Gateway
    echo "Deleting Internet Gateway..."
    IGW_ID=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[0].InternetGatewayId' --output text)
    if [ "$IGW_ID" != "None" ] && [ ! -z "$IGW_ID" ]; then
        aws ec2 detach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID"
        aws ec2 delete-internet-gateway --internet-gateway-id "$IGW_ID"
        echo "Internet Gateway deleted: $IGW_ID"
    fi
    
    # Delete Subnets
    echo "Deleting Subnets..."
    SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[].SubnetId' --output json | jq -r '.[]')
    for SUBNET_ID in $SUBNET_IDS; do
        aws ec2 delete-subnet --subnet-id "$SUBNET_ID"
        echo "Deleted Subnet: $SUBNET_ID"
    done
    
    # Delete Route Tables (except the main one)
    echo "Deleting Route Tables..."
    ROUTE_TABLE_IDS=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query 'RouteTables[?Associations==`[]`].RouteTableId' --output json | jq -r '.[]')
    for RT_ID in $ROUTE_TABLE_IDS; do
        aws ec2 delete-route-table --route-table-id "$RT_ID"
        echo "Deleted Route Table: $RT_ID"
    done
    
    # Wait for instances to be terminated
    echo "Waiting for all instances to be terminated..."
    aws ec2 wait instance-terminated --filters "Name=vpc-id,Values=$VPC_ID"
    
    # Delete VPC
    echo "Deleting VPC: $VPC_ID"
    aws ec2 delete-vpc --vpc-id "$VPC_ID"
    echo "VPC deleted: $VPC_ID"
else
    echo "No VPC found with Environment=$ENVIRONMENT"
fi

# Delete RDS Instances
echo "Deleting RDS Instances..."
RDS_INSTANCES=$(aws rds describe-db-instances --query "DBInstances[?starts_with(DBInstanceIdentifier, '$ENVIRONMENT-')].DBInstanceIdentifier" --output text)
if [ ! -z "$RDS_INSTANCES" ]; then
    delete_with_retry "RDS Instance" $RDS_INSTANCES
fi

# Delete RDS Subnet Groups
echo "Deleting RDS Subnet Groups..."
RDS_SUBNET_GROUPS=$(aws rds describe-db-subnet-groups --query "DBSubnetGroups[?starts_with(DBSubnetGroupName, '$ENVIRONMENT-')].DBSubnetGroupName" --output text)
if [ ! -z "$RDS_SUBNET_GROUPS" ]; then
    delete_with_retry "RDS Subnet Group" $RDS_SUBNET_GROUPS
fi

# Delete RDS Parameter Groups
echo "Deleting RDS Parameter Groups..."
RDS_PARAM_GROUPS=$(aws rds describe-db-parameter-groups --query "DBParameterGroups[?starts_with(DBParameterGroupName, '$ENVIRONMENT-')].DBParameterGroupName" --output text)
if [ ! -z "$RDS_PARAM_GROUPS" ]; then
    delete_with_retry "RDS Parameter Group" $RDS_PARAM_GROUPS
fi

# Delete ElastiCache Replication Groups
echo "Deleting ElastiCache Replication Groups..."
CACHE_GROUPS=$(aws elasticache describe-replication-groups --query "ReplicationGroups[?starts_with(ReplicationGroupId, '$ENVIRONMENT-')].ReplicationGroupId" --output text)
if [ ! -z "$CACHE_GROUPS" ]; then
    delete_with_retry "ElastiCache Replication Group" $CACHE_GROUPS
fi

# Delete ElastiCache Parameter Groups
echo "Deleting ElastiCache Parameter Groups..."
CACHE_PARAM_GROUPS=$(aws elasticache describe-cache-parameter-groups --query "CacheParameterGroups[?starts_with(CacheParameterGroupName, '$ENVIRONMENT-')].CacheParameterGroupName" --output text)
if [ ! -z "$CACHE_PARAM_GROUPS" ]; then
    delete_with_retry "ElastiCache Parameter Group" $CACHE_PARAM_GROUPS
fi

# Delete ElastiCache Subnet Groups
echo "Deleting ElastiCache Subnet Groups..."
CACHE_SUBNET_GROUPS=$(aws elasticache describe-cache-subnet-groups --query "CacheSubnetGroups[?starts_with(CacheSubnetGroupName, '$ENVIRONMENT-')].CacheSubnetGroupName" --output text)
if [ ! -z "$CACHE_SUBNET_GROUPS" ]; then
    delete_with_retry "ElastiCache Subnet Group" $CACHE_SUBNET_GROUPS
fi

# Delete Security Groups
echo "Deleting Security Groups..."
SECURITY_GROUPS=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=*$ENVIRONMENT*" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text)
if [ ! -z "$SECURITY_GROUPS" ]; then
    delete_with_retry "Security Group" $SECURITY_GROUPS
fi

echo "----------------------------------------"
echo "Cleanup completed for environment: $ENVIRONMENT"
echo "Note: Some resources may take a few minutes to be completely removed from AWS"
