#!/bin/bash

# AWS Resources Setup Script
# This script creates necessary AWS resources for deployment

set -e

echo "🔧 Setting up AWS Resources..."

# Configuration
AWS_REGION="us-east-1"
BACKEND_APPLICATION_NAME="awsproject-backend"
BACKEND_ENVIRONMENT_NAME="awsproject-backend-prod"
BACKEND_S3_BUCKET="awsproject-backend-deployments"
FRONTEND_S3_BUCKET="awsproject-frontend-bucket"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    print_error "AWS CLI is not configured. Please run 'aws configure' first."
    exit 1
fi

print_status "AWS CLI is configured ✓"

# Get AWS account info
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
print_status "AWS Account: ${ACCOUNT_ID}"

# Function to create S3 buckets
create_s3_buckets() {
    print_header "Creating S3 Buckets"
    
    # Create backend deployment bucket
    print_status "Creating backend deployment bucket..."
    if ! aws s3 ls "s3://${BACKEND_S3_BUCKET}" 2>/dev/null; then
        aws s3 mb "s3://${BACKEND_S3_BUCKET}" --region "${AWS_REGION}"
        print_status "✅ Backend bucket created: s3://${BACKEND_S3_BUCKET}"
    else
        print_status "✅ Backend bucket already exists: s3://${BACKEND_S3_BUCKET}"
    fi
    
    # Create frontend hosting bucket
    print_status "Creating frontend hosting bucket..."
    if ! aws s3 ls "s3://${FRONTEND_S3_BUCKET}" 2>/dev/null; then
        aws s3 mb "s3://${FRONTEND_S3_BUCKET}" --region "${AWS_REGION}"
        
        # Configure bucket for static website hosting
        aws s3 website "s3://${FRONTEND_S3_BUCKET}" \
            --index-document index.html \
            --error-document index.html
        
        print_status "✅ Frontend bucket created: s3://${FRONTEND_S3_BUCKET}"
    else
        print_status "✅ Frontend bucket already exists: s3://${FRONTEND_S3_BUCKET}"
    fi
}

# Function to create Elastic Beanstalk application
create_elasticbeanstalk_app() {
    print_header "Creating Elastic Beanstalk Application"
    
    # Check if application exists
    if aws elasticbeanstalk describe-applications --application-names "${BACKEND_APPLICATION_NAME}" > /dev/null 2>&1; then
        print_status "✅ Elastic Beanstalk application already exists: ${BACKEND_APPLICATION_NAME}"
        return
    fi
    
    # Create application
    print_status "Creating Elastic Beanstalk application..."
    aws elasticbeanstalk create-application \
        --application-name "${BACKEND_APPLICATION_NAME}" \
        --description "AWS Project Backend Application"
    
    print_status "✅ Elastic Beanstalk application created: ${BACKEND_APPLICATION_NAME}"
}

# Function to create DynamoDB tables
create_dynamodb_tables() {
    print_header "Creating DynamoDB Tables"
    
    cd "$(dirname "$0")/backend"
    
    if [ -f "scripts/createTables.js" ]; then
        print_status "Creating DynamoDB tables..."
        node scripts/createTables.js
        print_status "✅ DynamoDB tables created!"
    else
        print_warning "DynamoDB setup script not found. Creating tables manually..."
        
        # Create ChatRooms table
        aws dynamodb create-table \
            --table-name ChatRooms \
            --attribute-definitions \
                AttributeName=id,AttributeType=S \
            --key-schema \
                AttributeName=id,KeyType=HASH \
            --billing-mode PAY_PER_REQUEST \
            --region "${AWS_REGION}"
        
        # Create Messages table
        aws dynamodb create-table \
            --table-name Messages \
            --attribute-definitions \
                AttributeName=id,AttributeType=S \
                AttributeName=chatRoomId,AttributeType=S \
            --key-schema \
                AttributeName=id,KeyType=HASH \
            --global-secondary-indexes \
                IndexName=ChatRoomIndex,KeySchema='[{AttributeName=chatRoomId,KeyType=HASH}]',Projection='{ProjectionType=ALL}' \
            --billing-mode PAY_PER_REQUEST \
            --region "${AWS_REGION}"
        
        # Create Meetings table
        aws dynamodb create-table \
            --table-name Meetings \
            --attribute-definitions \
                AttributeName=id,AttributeType=S \
            --key-schema \
                AttributeName=id,KeyType=HASH \
            --billing-mode PAY_PER_REQUEST \
            --region "${AWS_REGION}"
        
        # Create Projects table
        aws dynamodb create-table \
            --table-name Projects \
            --attribute-definitions \
                AttributeName=id,AttributeType=S \
            --key-schema \
                AttributeName=id,KeyType=HASH \
            --billing-mode PAY_PER_REQUEST \
            --region "${AWS_REGION}"
        
        # Create ProjectFiles table
        aws dynamodb create-table \
            --table-name ProjectFiles \
            --attribute-definitions \
                AttributeName=id,AttributeType=S \
                AttributeName=projectId,AttributeType=S \
            --key-schema \
                AttributeName=id,KeyType=HASH \
            --global-secondary-indexes \
                IndexName=ProjectIndex,KeySchema='[{AttributeName=projectId,KeyType=HASH}]',Projection='{ProjectionType=ALL}' \
            --billing-mode PAY_PER_REQUEST \
            --region "${AWS_REGION}"
        
        print_status "✅ DynamoDB tables created manually!"
    fi
    
    cd "$(dirname "$0")"
}

# Function to create IAM role for Elastic Beanstalk
create_iam_role() {
    print_header "Creating IAM Role for Elastic Beanstalk"
    
    ROLE_NAME="awsproject-elasticbeanstalk-role"
    
    # Check if role exists
    if aws iam get-role --role-name "${ROLE_NAME}" > /dev/null 2>&1; then
        print_status "✅ IAM role already exists: ${ROLE_NAME}"
        return
    fi
    
    # Create trust policy
    cat > trust-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "elasticbeanstalk.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
    
    # Create role
    print_status "Creating IAM role..."
    aws iam create-role \
        --role-name "${ROLE_NAME}" \
        --assume-role-policy-document file://trust-policy.json
    
    # Attach policies
    print_status "Attaching policies to role..."
    aws iam attach-role-policy \
        --role-name "${ROLE_NAME}" \
        --policy-arn "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
    
    aws iam attach-role-policy \
        --role-name "${ROLE_NAME}" \
        --policy-arn "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
    
    aws iam attach-role-policy \
        --role-name "${ROLE_NAME}" \
        --policy-arn "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
    
    # Create and attach DynamoDB policy
    cat > dynamodb-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:Query",
                "dynamodb:Scan",
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:UpdateItem",
                "dynamodb:DeleteItem",
                "dynamodb:BatchGetItem",
                "dynamodb:BatchWriteItem"
            ],
            "Resource": [
                "arn:aws:dynamodb:${AWS_REGION}:${ACCOUNT_ID}:table/ChatRooms",
                "arn:aws:dynamodb:${AWS_REGION}:${ACCOUNT_ID}:table/Messages",
                "arn:aws:dynamodb:${AWS_REGION}:${ACCOUNT_ID}:table/Meetings",
                "arn:aws:dynamodb:${AWS_REGION}:${ACCOUNT_ID}:table/Projects",
                "arn:aws:dynamodb:${AWS_REGION}:${ACCOUNT_ID}:table/ProjectFiles",
                "arn:aws:dynamodb:${AWS_REGION}:${ACCOUNT_ID}:table/ChatRooms/index/*",
                "arn:aws:dynamodb:${AWS_REGION}:${ACCOUNT_ID}:table/Messages/index/*",
                "arn:aws:dynamodb:${AWS_REGION}:${ACCOUNT_ID}:table/Meetings/index/*",
                "arn:aws:dynamodb:${AWS_REGION}:${ACCOUNT_ID}:table/Projects/index/*",
                "arn:aws:dynamodb:${AWS_REGION}:${ACCOUNT_ID}:table/ProjectFiles/index/*"
            ]
        }
    ]
}
EOF
    
    aws iam put-role-policy \
        --role-name "${ROLE_NAME}" \
        --policy-name "DynamoDBAccess" \
        --policy-document file://dynamodb-policy.json
    
    # Clean up
    rm trust-policy.json dynamodb-policy.json
    
    print_status "✅ IAM role created: ${ROLE_NAME}"
}

# Function to create instance profile
create_instance_profile() {
    print_header "Creating Instance Profile"
    
    ROLE_NAME="awsproject-elasticbeanstalk-role"
    INSTANCE_PROFILE_NAME="awsproject-elasticbeanstalk-instance-profile"
    
    # Check if instance profile exists
    if aws iam get-instance-profile --instance-profile-name "${INSTANCE_PROFILE_NAME}" > /dev/null 2>&1; then
        print_status "✅ Instance profile already exists: ${INSTANCE_PROFILE_NAME}"
        return
    fi
    
    # Create instance profile
    print_status "Creating instance profile..."
    aws iam create-instance-profile --instance-profile-name "${INSTANCE_PROFILE_NAME}"
    
    # Add role to instance profile
    aws iam add-role-to-instance-profile \
        --instance-profile-name "${INSTANCE_PROFILE_NAME}" \
        --role-name "${ROLE_NAME}"
    
    print_status "✅ Instance profile created: ${INSTANCE_PROFILE_NAME}"
}

# Main setup process
main() {
    print_header "Starting AWS Resources Setup"
    
    # Create S3 buckets
    create_s3_buckets
    
    # Create DynamoDB tables
    create_dynamodb_tables
    
    # Create IAM role
    create_iam_role
    
    # Create instance profile
    create_instance_profile
    
    # Create Elastic Beanstalk application
    create_elasticbeanstalk_app
    
    print_header "🎉 AWS Resources Setup Complete!"
    echo ""
    print_status "Created resources:"
    print_status "  • S3 Buckets: ${BACKEND_S3_BUCKET}, ${FRONTEND_S3_BUCKET}"
    print_status "  • DynamoDB Tables: ChatRooms, Messages, Meetings, Projects, ProjectFiles"
    print_status "  • IAM Role: awsproject-elasticbeanstalk-role"
    print_status "  • Instance Profile: awsproject-elasticbeanstalk-instance-profile"
    print_status "  • Elastic Beanstalk Application: ${BACKEND_APPLICATION_NAME}"
    echo ""
    print_status "You can now run the deployment script! 🚀"
}

# Run main function
main
