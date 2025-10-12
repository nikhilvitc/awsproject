#!/bin/bash

# AWS Frontend Deployment Script
# This script deploys the frontend to AWS S3 + CloudFront

set -e

echo "🚀 Starting AWS Frontend Deployment..."

# Configuration
AWS_REGION="us-east-1"
S3_BUCKET="awsproject-frontend-bucket"
CLOUDFRONT_DISTRIBUTION_ID="E1234567890ABC"  # Replace with your actual CloudFront distribution ID
BACKEND_URL="https://awsproject-backend-prod.eba-fphuu5yq.us-east-1.elasticbeanstalk.com"

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

# Navigate to frontend directory
cd "$(dirname "$0")/jellylemonshake"

# Check if frontend directory exists
if [ ! -d "." ]; then
    print_error "Frontend directory not found!"
    exit 1
fi

print_status "Found frontend directory ✓"

# Install dependencies
print_status "Installing frontend dependencies..."
npm install

# Set environment variables for build
export REACT_APP_API_URL="${BACKEND_URL}"
export REACT_APP_SOCKET_URL="${BACKEND_URL}"
export REACT_APP_ENV="production"

# Build the application
print_status "Building React application..."
npm run build

# Check if build was successful
if [ ! -d "build" ]; then
    print_error "Build failed! Build directory not found."
    exit 1
fi

print_status "Build completed successfully ✓"

# Create S3 bucket if it doesn't exist
print_status "Checking S3 bucket..."
if ! aws s3 ls "s3://${S3_BUCKET}" 2>/dev/null; then
    print_status "Creating S3 bucket..."
    aws s3 mb "s3://${S3_BUCKET}" --region "${AWS_REGION}"
    
    # Configure bucket for static website hosting
    aws s3 website "s3://${S3_BUCKET}" \
        --index-document index.html \
        --error-document index.html
fi

# Upload files to S3
print_status "Uploading files to S3..."
aws s3 sync build/ "s3://${S3_BUCKET}" --delete

# Set proper content types
print_status "Setting content types..."
aws s3 cp "s3://${S3_BUCKET}" "s3://${S3_BUCKET}" --recursive --metadata-directive REPLACE \
    --content-type "text/html" --exclude "*" --include "*.html"

aws s3 cp "s3://${S3_BUCKET}" "s3://${S3_BUCKET}" --recursive --metadata-directive REPLACE \
    --content-type "application/javascript" --exclude "*" --include "*.js"

aws s3 cp "s3://${S3_BUCKET}" "s3://${S3_BUCKET}" --recursive --metadata-directive REPLACE \
    --content-type "text/css" --exclude "*" --include "*.css"

# Set cache headers
print_status "Setting cache headers..."
aws s3 cp "s3://${S3_BUCKET}" "s3://${S3_BUCKET}" --recursive --metadata-directive REPLACE \
    --cache-control "public, max-age=31536000" --exclude "*.html"

aws s3 cp "s3://${S3_BUCKET}" "s3://${S3_BUCKET}" --recursive --metadata-directive REPLACE \
    --cache-control "no-cache" --include "*.html"

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
            "Resource": "arn:aws:s3:::${S3_BUCKET}/*"
        }
    ]
}
EOF

aws s3api put-bucket-policy --bucket "${S3_BUCKET}" --policy file://bucket-policy.json
rm bucket-policy.json

# Invalidate CloudFront cache if distribution ID is provided
if [ "${CLOUDFRONT_DISTRIBUTION_ID}" != "E1234567890ABC" ]; then
    print_status "Invalidating CloudFront cache..."
    aws cloudfront create-invalidation \
        --distribution-id "${CLOUDFRONT_DISTRIBUTION_ID}" \
        --paths "/*"
fi

# Get website URL
WEBSITE_URL="http://${S3_BUCKET}.s3-website-${AWS_REGION}.amazonaws.com"

print_status "✅ Frontend deployment completed!"
print_status "🌐 Frontend URL: ${WEBSITE_URL}"
print_status "🔗 S3 Bucket: s3://${S3_BUCKET}"

if [ "${CLOUDFRONT_DISTRIBUTION_ID}" != "E1234567890ABC" ]; then
    CLOUDFRONT_URL=$(aws cloudfront get-distribution \
        --id "${CLOUDFRONT_DISTRIBUTION_ID}" \
        --query 'Distribution.DomainName' \
        --output text)
    print_status "🌐 CloudFront URL: https://${CLOUDFRONT_URL}"
fi

print_status "🎉 Frontend deployment successful!"
