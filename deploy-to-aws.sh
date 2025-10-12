#!/bin/bash

# AWS Deployment Script for DynamoDB Chat Application
# This script deploys both frontend and backend to AWS

set -e

echo "🚀 Starting AWS Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="us-east-1"
BACKEND_APP_NAME="awsproject-backend"
FRONTEND_BUCKET="awsproject-frontend-$(date +%s)"
CLOUDFRONT_DISTRIBUTION=""

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

# Deploy backend to Elastic Beanstalk
deploy_backend() {
    print_status "Deploying backend to Elastic Beanstalk..."
    
    cd backend
    
    # Initialize EB if not already done
    if [ ! -f ".elasticbeanstalk/config.yml" ]; then
        print_status "Initializing Elastic Beanstalk application..."
        eb init $BACKEND_APP_NAME --region $AWS_REGION --platform "Node.js 18"
    fi
    
    # Create environment if it doesn't exist
    if ! eb list | grep -q "production"; then
        print_status "Creating production environment..."
        eb create production --instance-type t3.micro
    fi
    
    # Deploy
    print_status "Deploying to production..."
    eb deploy production
    
    # Get the URL
    BACKEND_URL=$(eb status production | grep "CNAME" | awk '{print $2}')
    print_status "Backend deployed at: https://$BACKEND_URL"
    
    cd ..
}

# Deploy frontend to S3
deploy_frontend() {
    print_status "Deploying frontend to S3..."
    
    cd jellylemonshake
    
    # Build the application
    print_status "Building React application..."
    npm run build
    
    # Create S3 bucket
    print_status "Creating S3 bucket: $FRONTEND_BUCKET"
    aws s3 mb s3://$FRONTEND_BUCKET --region $AWS_REGION
    
    # Upload files
    print_status "Uploading files to S3..."
    aws s3 sync build/ s3://$FRONTEND_BUCKET --delete
    
    # Configure bucket for static website hosting
    print_status "Configuring S3 for static website hosting..."
    aws s3 website s3://$FRONTEND_BUCKET --index-document index.html --error-document index.html
    
    # Set bucket policy for public read
    cat > bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$FRONTEND_BUCKET/*"
        }
    ]
}
EOF
    
    aws s3api put-bucket-policy --bucket $FRONTEND_BUCKET --policy file://bucket-policy.json
    rm bucket-policy.json
    
    FRONTEND_URL="http://$FRONTEND_BUCKET.s3-website-$AWS_REGION.amazonaws.com"
    print_status "Frontend deployed at: $FRONTEND_URL"
    
    cd ..
}

# Create CloudFront distribution
create_cloudfront() {
    print_status "Creating CloudFront distribution..."
    
    # Create CloudFront configuration
    cat > cloudfront-config.json << EOF
{
    "CallerReference": "$(date +%s)",
    "Comment": "AWS Project Frontend Distribution",
    "DefaultRootObject": "index.html",
    "Origins": {
        "Quantity": 1,
        "Items": [
            {
                "Id": "S3-$FRONTEND_BUCKET",
                "DomainName": "$FRONTEND_BUCKET.s3.amazonaws.com",
                "S3OriginConfig": {
                    "OriginAccessIdentity": ""
                }
            }
        ]
    },
    "DefaultCacheBehavior": {
        "TargetOriginId": "S3-$FRONTEND_BUCKET",
        "ViewerProtocolPolicy": "redirect-to-https",
        "TrustedSigners": {
            "Enabled": false,
            "Quantity": 0
        },
        "ForwardedValues": {
            "QueryString": false,
            "Cookies": {
                "Forward": "none"
            }
        },
        "MinTTL": 0,
        "DefaultTTL": 86400,
        "MaxTTL": 31536000
    },
    "Enabled": true,
    "PriceClass": "PriceClass_100"
}
EOF
    
    # Create distribution
    DISTRIBUTION_ID=$(aws cloudfront create-distribution --distribution-config file://cloudfront-config.json --query 'Distribution.Id' --output text)
    
    # Get distribution domain
    CLOUDFRONT_DOMAIN=$(aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'Distribution.DomainName' --output text)
    
    print_status "CloudFront distribution created: https://$CLOUDFRONT_DOMAIN"
    
    rm cloudfront-config.json
}

# Update frontend API URL
update_frontend_config() {
    if [ ! -z "$BACKEND_URL" ]; then
        print_status "Updating frontend configuration..."
        
        cd jellylemonshake
        
        # Update API URL in build
        sed -i.bak "s|http://localhost:5000|https://$BACKEND_URL|g" build/static/js/*.js
        
        # Re-upload to S3
        aws s3 sync build/ s3://$FRONTEND_BUCKET --delete
        
        cd ..
    fi
}

# Main deployment function
main() {
    print_status "Starting AWS deployment process..."
    
    # Pre-flight checks
    check_aws_cli
    check_eb_cli
    
    # Deploy backend
    deploy_backend
    
    # Deploy frontend
    deploy_frontend
    
    # Create CloudFront distribution
    create_cloudfront
    
    # Update frontend configuration
    update_frontend_config
    
    # Summary
    echo ""
    print_status "🎉 Deployment completed successfully!"
    echo ""
    echo "📋 Deployment Summary:"
    echo "  Backend URL: https://$BACKEND_URL"
    echo "  Frontend S3: $FRONTEND_URL"
    echo "  CloudFront: https://$CLOUDFRONT_DOMAIN"
    echo ""
    echo "🔧 Next Steps:"
    echo "  1. Update your domain DNS to point to CloudFront"
    echo "  2. Configure SSL certificate for custom domain"
    echo "  3. Set up monitoring and alerts"
    echo "  4. Configure backup strategies"
    echo ""
}

# Run main function
main "$@"
