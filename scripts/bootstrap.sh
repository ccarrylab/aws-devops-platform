#!/bin/bash
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

BUCKET_NAME="terraform-state-platform-$(date +%s)"
DYNAMODB_TABLE="terraform-state-lock"
AWS_REGION="us-east-1"

echo -e "${GREEN}AWS DevOps Platform Bootstrap${NC}\n"

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${RED}AWS CLI not installed${NC}"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}AWS credentials not configured${NC}"
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}✓ AWS Account: ${ACCOUNT_ID}${NC}"

# Create S3 bucket
echo -e "${YELLOW}Creating S3 bucket...${NC}"
if aws s3api head-bucket --bucket ${BUCKET_NAME} 2>/dev/null; then
    echo -e "${YELLOW}Bucket already exists${NC}"
else
    aws s3api create-bucket --bucket ${BUCKET_NAME} --region ${AWS_REGION}
    aws s3api put-bucket-versioning --bucket ${BUCKET_NAME} --versioning-configuration Status=Enabled
    aws s3api put-bucket-encryption --bucket ${BUCKET_NAME} --server-side-encryption-configuration '{
        "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
    }'
    aws s3api put-public-access-block --bucket ${BUCKET_NAME} --public-access-block-configuration \
        "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
    echo -e "${GREEN}✓ Created: ${BUCKET_NAME}${NC}"
fi

# Create DynamoDB table
echo -e "${YELLOW}Creating DynamoDB table...${NC}"
if aws dynamodb describe-table --table-name ${DYNAMODB_TABLE} --region ${AWS_REGION} &> /dev/null; then
    echo -e "${YELLOW}Table already exists${NC}"
else
    aws dynamodb create-table \
        --table-name ${DYNAMODB_TABLE} \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region ${AWS_REGION} > /dev/null
    aws dynamodb wait table-exists --table-name ${DYNAMODB_TABLE} --region ${AWS_REGION}
    echo -e "${GREEN}✓ Created: ${DYNAMODB_TABLE}${NC}"
fi

# Create backend configuration
cat > infrastructure/backend.tf <<EOF
terraform {
  backend "s3" {
    bucket         = "${BUCKET_NAME}"
    key            = "platform/terraform.tfstate"
    region         = "${AWS_REGION}"
    encrypt        = true
    dynamodb_table = "${DYNAMODB_TABLE}"
  }
}
EOF

echo -e "${GREEN}✓ Backend configuration created${NC}\n"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Bootstrap Complete!${NC}"
echo -e "${GREEN}========================================${NC}\n"
echo -e "S3 Bucket:      ${BUCKET_NAME}"
echo -e "DynamoDB Table: ${DYNAMODB_TABLE}"
echo -e "Region:         ${AWS_REGION}\n"
echo -e "Next steps:"
echo -e "  1. ${GREEN}cd infrastructure && terraform init${NC}"
echo -e "  2. ${GREEN}terraform plan${NC}"
echo -e "  3. ${GREEN}terraform apply${NC}\n"
