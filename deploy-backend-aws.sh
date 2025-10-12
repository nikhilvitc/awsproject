#!/bin/bash

# AWS Backend Deployment Script
# This script deploys your backend to AWS Elastic Beanstalk

set -e

echo "🚀 Deploying Backend to AWS Elastic Beanstalk..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="us-east-1"
APP_NAME="awsproject-backend"
ENVIRONMENT_NAME="awsproject-backend-prod"
INSTANCE_TYPE="t3.micro"

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

# Check if AWS CLI is installed
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    print_status "AWS CLI found"
}

# Check if EB CLI is installed
check_eb_cli() {
    if ! command -v eb &> /dev/null; then
        print_warning "EB CLI is not installed. Installing..."
        pip install awsebcli
    fi
    print_status "EB CLI found"
}

# Create IAM role for Elastic Beanstalk
create_iam_role() {
    print_status "Setting up IAM role for Elastic Beanstalk..."
    
    # Create instance profile role
    aws iam create-role \
        --role-name DynamoDBChatAppRole \
        --assume-role-policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {
                        "Service": "ec2.amazonaws.com"
                    },
                    "Action": "sts:AssumeRole"
                }
            ]
        }' 2>/dev/null || print_warning "Role already exists"
    
    # Attach DynamoDB policy
    aws iam put-role-policy \
        --role-name DynamoDBChatAppRole \
        --policy-name DynamoDBChatAppPolicy \
        --policy-document file://iam-policy.json 2>/dev/null || print_warning "Policy already exists"
    
    # Create instance profile
    aws iam create-instance-profile \
        --instance-profile-name DynamoDBChatAppRole 2>/dev/null || print_warning "Instance profile already exists"
    
    # Add role to instance profile
    aws iam add-role-to-instance-profile \
        --instance-profile-name DynamoDBChatAppRole \
        --role-name DynamoDBChatAppRole 2>/dev/null || print_warning "Role already added to instance profile"
    
    print_status "IAM role setup completed"
}

# Initialize Elastic Beanstalk
init_eb() {
    print_status "Initializing Elastic Beanstalk application..."
    
    cd backend
    
    # Initialize EB if not already done
    if [ ! -f ".elasticbeanstalk/config.yml" ]; then
        print_status "Creating new EB application..."
        eb init $APP_NAME --region $AWS_REGION --platform "Node.js 18"
    else
        print_status "EB application already initialized"
    fi
    
    cd ..
}

# Create environment
create_environment() {
    print_status "Creating Elastic Beanstalk environment..."
    
    cd backend
    
    # Check if environment exists
    if eb list | grep -q "$ENVIRONMENT_NAME"; then
        print_status "Environment $ENVIRONMENT_NAME already exists"
    else
        print_status "Creating new environment: $ENVIRONMENT_NAME"
        eb create $ENVIRONMENT_NAME \
            --instance-type $INSTANCE_TYPE \
            --single \
            --timeout 20
    fi
    
    cd ..
}

# Deploy application
deploy_application() {
    print_status "Deploying application to Elastic Beanstalk..."
    
    cd backend
    
    # Deploy
    eb deploy $ENVIRONMENT_NAME
    
    # Get the URL
    BACKEND_URL=$(eb status $ENVIRONMENT_NAME | grep "CNAME" | awk '{print $2}')
    print_status "Backend deployed at: https://$BACKEND_URL"
    
    cd ..
}

# Update CORS configuration for AWS backend
update_cors_for_aws() {
    print_status "Updating CORS configuration for AWS backend..."
    
    cd backend
    
    # Add AWS backend URL to CORS configuration
    sed -i.bak 's|"https://awsproject-backend.onrender.com"|"https://awsproject-backend.onrender.com",\n      "https://'$BACKEND_URL'"|' index.js
    
    print_status "CORS configuration updated"
    
    cd ..
}

# Test deployment
test_deployment() {
    print_status "Testing AWS backend deployment..."
    
    if [ ! -z "$BACKEND_URL" ]; then
        # Test health endpoint
        if curl -s "https://$BACKEND_URL/api/health" > /dev/null; then
            print_status "✅ Backend is accessible at https://$BACKEND_URL"
        else
            print_warning "⚠️  Backend might not be accessible yet"
        fi
    fi
}

# Main deployment function
main() {
    print_status "Starting AWS backend deployment..."
    
    # Pre-flight checks
    check_aws_cli
    check_eb_cli
    
    # Setup IAM role
    create_iam_role
    
    # Initialize and deploy
    init_eb
    create_environment
    deploy_application
    
    # Update configuration
    update_cors_for_aws
    
    # Test deployment
    test_deployment
    
    # Summary
    echo ""
    print_status "🎉 AWS Backend deployment completed!"
    echo ""
    echo "📋 Deployment Summary:"
    echo "  Backend URL: https://$BACKEND_URL"
    echo "  Region: $AWS_REGION"
    echo "  Instance Type: $INSTANCE_TYPE"
    echo ""
    echo "🔧 Next Steps:"
    echo "  1. Update frontend to use AWS backend URL"
    echo "  2. Test all API endpoints"
    echo "  3. Monitor logs: eb logs"
    echo "  4. Scale if needed: eb scale 2"
    echo ""
    echo "📝 Useful Commands:"
    echo "  eb status          # Check environment status"
    echo "  eb logs            # View application logs"
    echo "  eb health          # Check health"
    echo "  eb scale 2         # Scale to 2 instances"
    echo ""
}

# Run main function
main "$@"
