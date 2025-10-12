#!/bin/bash

# Complete AWS Deployment Script
# This script deploys both backend and frontend to AWS

set -e

echo "🚀 Starting Complete AWS Deployment..."

# Configuration
AWS_REGION="us-east-1"
BACKEND_APPLICATION_NAME="awsproject-backend"
BACKEND_ENVIRONMENT_NAME="awsproject-backend-prod"
BACKEND_S3_BUCKET="awsproject-backend-deployments"
FRONTEND_S3_BUCKET="awsproject-frontend-bucket"
CLOUDFRONT_DISTRIBUTION_ID="E1234567890ABC"  # Replace with your actual CloudFront distribution ID

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

# Function to deploy backend
deploy_backend() {
    print_header "Deploying Backend to Elastic Beanstalk"
    
    cd "$(dirname "$0")/backend"
    
    if [ ! -d "." ]; then
        print_error "Backend directory not found!"
        return 1
    fi
    
    VERSION_LABEL="backend-$(date +%Y%m%d-%H%M%S)"
    
    # Install dependencies
    print_status "Installing backend dependencies..."
    npm install --production
    
    # Create deployment package
    print_status "Creating deployment package..."
    zip -r "../backend-deployment.zip" . -x "node_modules/*" "*.log" ".git/*" "test/*" "*.test.js"
    
    # Upload to S3
    print_status "Uploading to S3..."
    aws s3 cp "../backend-deployment.zip" "s3://${BACKEND_S3_BUCKET}/${VERSION_LABEL}.zip"
    
    # Create application version
    print_status "Creating application version..."
    aws elasticbeanstalk create-application-version \
        --application-name "${BACKEND_APPLICATION_NAME}" \
        --version-label "${VERSION_LABEL}" \
        --source-bundle S3Bucket="${BACKEND_S3_BUCKET}",S3Key="${VERSION_LABEL}.zip" \
        --description "Backend deployment $(date)"
    
    # Deploy to environment
    print_status "Deploying to Elastic Beanstalk environment..."
    aws elasticbeanstalk update-environment \
        --environment-name "${BACKEND_ENVIRONMENT_NAME}" \
        --version-label "${VERSION_LABEL}"
    
    print_status "Backend deployment initiated! Waiting for completion..."
    
    # Wait for deployment to complete
    aws elasticbeanstalk wait environment-updated \
        --environment-names "${BACKEND_ENVIRONMENT_NAME}"
    
    # Get environment URL
    BACKEND_URL=$(aws elasticbeanstalk describe-environments \
        --environment-names "${BACKEND_ENVIRONMENT_NAME}" \
        --query 'Environments[0].CNAME' \
        --output text)
    
    print_status "✅ Backend deployment completed!"
    print_status "🌐 Backend URL: http://${BACKEND_URL}"
    
    # Clean up
    rm -f "../backend-deployment.zip"
    
    # Return to project root
    cd "$(dirname "$0")"
    
    echo "${BACKEND_URL}"
}

# Function to deploy frontend
deploy_frontend() {
    local backend_url=$1
    
    print_header "Deploying Frontend to S3 + CloudFront"
    
    cd "$(dirname "$0")/jellylemonshake"
    
    if [ ! -d "." ]; then
        print_error "Frontend directory not found!"
        return 1
    fi
    
    # Install dependencies
    print_status "Installing frontend dependencies..."
    npm install
    
    # Set environment variables for build
    export REACT_APP_API_URL="http://${backend_url}"
    export REACT_APP_SOCKET_URL="http://${backend_url}"
    export REACT_APP_ENV="production"
    
    # Build the application
    print_status "Building React application..."
    npm run build
    
    # Check if build was successful
    if [ ! -d "build" ]; then
        print_error "Build failed! Build directory not found."
        return 1
    fi
    
    print_status "Build completed successfully ✓"
    
    # Create S3 bucket if it doesn't exist
    print_status "Checking S3 bucket..."
    if ! aws s3 ls "s3://${FRONTEND_S3_BUCKET}" 2>/dev/null; then
        print_status "Creating S3 bucket..."
        aws s3 mb "s3://${FRONTEND_S3_BUCKET}" --region "${AWS_REGION}"
        
        # Configure bucket for static website hosting
        aws s3 website "s3://${FRONTEND_S3_BUCKET}" \
            --index-document index.html \
            --error-document index.html
    fi
    
    # Upload files to S3
    print_status "Uploading files to S3..."
    aws s3 sync build/ "s3://${FRONTEND_S3_BUCKET}" --delete
    
    # Set proper content types and cache headers
    print_status "Setting content types and cache headers..."
    aws s3 cp "s3://${FRONTEND_S3_BUCKET}" "s3://${FRONTEND_S3_BUCKET}" --recursive --metadata-directive REPLACE \
        --content-type "text/html" --cache-control "no-cache" --exclude "*" --include "*.html"
    
    aws s3 cp "s3://${FRONTEND_S3_BUCKET}" "s3://${FRONTEND_S3_BUCKET}" --recursive --metadata-directive REPLACE \
        --content-type "application/javascript" --cache-control "public, max-age=31536000" --exclude "*" --include "*.js"
    
    aws s3 cp "s3://${FRONTEND_S3_BUCKET}" "s3://${FRONTEND_S3_BUCKET}" --recursive --metadata-directive REPLACE \
        --content-type "text/css" --cache-control "public, max-age=31536000" --exclude "*" --include "*.css"
    
    # Configure bucket policy for public read access
    print_status "Configuring bucket policy..."
    cat > bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${FRONTEND_S3_BUCKET}/*"
        }
    ]
}
EOF
    
    aws s3api put-bucket-policy --bucket "${FRONTEND_S3_BUCKET}" --policy file://bucket-policy.json
    rm bucket-policy.json
    
    # Invalidate CloudFront cache if distribution ID is provided
    if [ "${CLOUDFRONT_DISTRIBUTION_ID}" != "E1234567890ABC" ]; then
        print_status "Invalidating CloudFront cache..."
        aws cloudfront create-invalidation \
            --distribution-id "${CLOUDFRONT_DISTRIBUTION_ID}" \
            --paths "/*"
    fi
    
    # Get website URL
    FRONTEND_URL="http://${FRONTEND_S3_BUCKET}.s3-website-${AWS_REGION}.amazonaws.com"
    
    print_status "✅ Frontend deployment completed!"
    print_status "🌐 Frontend URL: ${FRONTEND_URL}"
    
    # Return to project root
    cd "$(dirname "$0")"
    
    echo "${FRONTEND_URL}"
}

# Function to setup DynamoDB tables
setup_dynamodb() {
    print_header "Setting up DynamoDB Tables"
    
    cd "$(dirname "$0")/backend"
    
    if [ -f "scripts/createTables.js" ]; then
        print_status "Creating DynamoDB tables..."
        node scripts/createTables.js
        print_status "✅ DynamoDB tables setup completed!"
    else
        print_warning "DynamoDB setup script not found. Please create tables manually."
    fi
    
    cd "$(dirname "$0")"
}

# Main deployment process
main() {
    print_header "Starting Complete AWS Deployment"
    
    # Setup DynamoDB tables first
    setup_dynamodb
    
    # Deploy backend
    BACKEND_URL=$(deploy_backend)
    if [ $? -ne 0 ]; then
        print_error "Backend deployment failed!"
        exit 1
    fi
    
    # Wait a bit for backend to be ready
    print_status "Waiting for backend to be ready..."
    sleep 30
    
    # Deploy frontend
    FRONTEND_URL=$(deploy_frontend "${BACKEND_URL}")
    if [ $? -ne 0 ]; then
        print_error "Frontend deployment failed!"
        exit 1
    fi
    
    # Final summary
    print_header "🎉 Deployment Complete!"
    echo ""
    print_status "Backend URL: http://${BACKEND_URL}"
    print_status "Frontend URL: ${FRONTEND_URL}"
    print_status "Health Check: http://${BACKEND_URL}/health"
    echo ""
    print_status "Your application is now live on AWS! 🚀"
}

# Run main function
main
