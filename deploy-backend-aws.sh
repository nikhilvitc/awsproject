#!/bin/bash

# AWS Backend Deployment Script
# This script deploys the backend to AWS Elastic Beanstalk

set -e

echo "🚀 Starting AWS Backend Deployment..."

# Configuration
AWS_REGION="us-east-1"
APPLICATION_NAME="awsproject-backend"
ENVIRONMENT_NAME="awsproject-backend-prod"
S3_BUCKET="awsproject-backend-deployments"
VERSION_LABEL="backend-$(date +%Y%m%d-%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    print_error "AWS CLI is not configured. Please run 'aws configure' first."
    exit 1
fi

print_status "AWS CLI is configured ✓"

# Navigate to backend directory
cd "$(dirname "$0")/backend"

# Check if backend directory exists
if [ ! -d "." ]; then
    print_error "Backend directory not found!"
    exit 1
fi

print_status "Found backend directory ✓"

# Install dependencies
print_status "Installing backend dependencies..."
npm install --production

# Create deployment package
print_status "Creating deployment package..."
zip -r "../backend-deployment.zip" . -x "node_modules/*" "*.log" ".git/*" "test/*" "*.test.js"

# Upload to S3
print_status "Uploading to S3..."
aws s3 cp "../backend-deployment.zip" "s3://${S3_BUCKET}/${VERSION_LABEL}.zip"

# Create application version
print_status "Creating application version..."
aws elasticbeanstalk create-application-version \
    --application-name "${APPLICATION_NAME}" \
    --version-label "${VERSION_LABEL}" \
    --source-bundle S3Bucket="${S3_BUCKET}",S3Key="${VERSION_LABEL}.zip" \
    --description "Backend deployment $(date)"

# Deploy to environment
print_status "Deploying to Elastic Beanstalk environment..."
aws elasticbeanstalk update-environment \
    --environment-name "${ENVIRONMENT_NAME}" \
    --version-label "${VERSION_LABEL}"

print_status "Deployment initiated! Waiting for completion..."

# Wait for deployment to complete
aws elasticbeanstalk wait environment-updated \
    --environment-names "${ENVIRONMENT_NAME}"

# Get environment URL
ENVIRONMENT_URL=$(aws elasticbeanstalk describe-environments \
    --environment-names "${ENVIRONMENT_NAME}" \
    --query 'Environments[0].CNAME' \
    --output text)

print_status "✅ Backend deployment completed!"
print_status "🌐 Backend URL: http://${ENVIRONMENT_URL}"
print_status "🔗 Health Check: http://${ENVIRONMENT_URL}/health"

# Clean up
rm -f "../backend-deployment.zip"

print_status "🎉 Backend deployment successful!"
