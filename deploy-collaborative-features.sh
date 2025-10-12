#!/bin/bash

# AWS Deployment Script for Collaborative Editing Features
# This script deploys the updated backend and frontend with live collaborative editing

set -e

echo "🚀 Deploying Collaborative Editing Features to AWS..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="us-east-1"
BACKEND_APP_NAME="awsproject-backend"
FRONTEND_BUCKET="awsproject-frontend-$(date +%s)"
ENVIRONMENT_NAME="awsproject-backend-prod"

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

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_step "Checking prerequisites..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    print_status "✅ AWS CLI found"
    
    # Check EB CLI
    if ! command -v eb &> /dev/null; then
        print_warning "EB CLI is not installed. Installing..."
        pip install awsebcli
    fi
    print_status "✅ EB CLI found"
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed. Please install it first."
        exit 1
    fi
    print_status "✅ Node.js found"
    
    # Check npm
    if ! command -v npm &> /dev/null; then
        print_error "npm is not installed. Please install it first."
        exit 1
    fi
    print_status "✅ npm found"
}

# Create deployment package for backend
prepare_backend() {
    print_step "Preparing backend for deployment..."
    
    cd backend
    
    # Install dependencies
    print_status "Installing backend dependencies..."
    npm install --production
    
    # Create deployment package
    print_status "Creating backend deployment package..."
    zip -r ../awsproject-backend-collaborative-$(date +%Y%m%d-%H%M%S).zip . \
        -x "node_modules/.cache/*" \
        -x "*.log" \
        -x ".git/*" \
        -x "test/*" \
        -x "*.test.js"
    
    print_status "✅ Backend package created"
    cd ..
}

# Deploy backend to Elastic Beanstalk
deploy_backend() {
    print_step "Deploying backend to Elastic Beanstalk..."
    
    cd backend
    
    # Initialize EB if not already done
    if [ ! -f ".elasticbeanstalk/config.yml" ]; then
        print_status "Initializing Elastic Beanstalk application..."
        eb init $BACKEND_APP_NAME --region $AWS_REGION --platform "Node.js 18"
    fi
    
    # Check if environment exists
    if eb list | grep -q "$ENVIRONMENT_NAME"; then
        print_status "Environment $ENVIRONMENT_NAME exists, updating..."
    else
        print_status "Creating new environment: $ENVIRONMENT_NAME"
        eb create $ENVIRONMENT_NAME \
            --instance-type t3.micro \
            --single \
            --timeout 20
    fi
    
    # Deploy with new collaborative features
    print_status "Deploying collaborative editing features..."
    eb deploy $ENVIRONMENT_NAME
    
    # Get the URL
    BACKEND_URL=$(eb status $ENVIRONMENT_NAME | grep "CNAME" | awk '{print $2}')
    print_status "✅ Backend deployed at: https://$BACKEND_URL"
    
    cd ..
}

# Prepare frontend for deployment
prepare_frontend() {
    print_step "Preparing frontend for deployment..."
    
    cd jellylemonshake
    
    # Install dependencies
    print_status "Installing frontend dependencies..."
    npm install
    
    # Update API URL for production
    if [ ! -z "$BACKEND_URL" ]; then
        print_status "Updating API URL to: https://$BACKEND_URL"
        # Update config.js
        sed -i.bak "s|http://localhost:5000|https://$BACKEND_URL|g" src/config.js
        # Update any hardcoded URLs
        find src -name "*.js" -exec sed -i.bak "s|http://localhost:5000|https://$BACKEND_URL|g" {} \;
    fi
    
    # Build the application
    print_status "Building React application with collaborative features..."
    npm run build
    
    # Create deployment package
    print_status "Creating frontend deployment package..."
    cd build
    zip -r ../../awsproject-frontend-collaborative-$(date +%Y%m%d-%H%M%S).zip . \
        -x "*.map" \
        -x "*.log"
    cd ..
    
    print_status "✅ Frontend package created"
    cd ..
}

# Deploy frontend to S3
deploy_frontend() {
    print_step "Deploying frontend to S3..."
    
    cd jellylemonshake
    
    # Create S3 bucket
    print_status "Creating S3 bucket: $FRONTEND_BUCKET"
    aws s3 mb s3://$FRONTEND_BUCKET --region $AWS_REGION
    
    # Upload files
    print_status "Uploading collaborative features to S3..."
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
    print_status "✅ Frontend deployed at: $FRONTEND_URL"
    
    cd ..
}

# Create CloudFront distribution for better performance
create_cloudfront() {
    print_step "Creating CloudFront distribution for collaborative features..."
    
    # Create CloudFront configuration
    cat > cloudfront-config.json << EOF
{
    "CallerReference": "$(date +%s)",
    "Comment": "AWS Project Frontend with Collaborative Features",
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
        "DefaultTTL": 3600,
        "MaxTTL": 86400
    },
    "Enabled": true,
    "PriceClass": "PriceClass_100"
}
EOF
    
    # Create distribution
    DISTRIBUTION_ID=$(aws cloudfront create-distribution --distribution-config file://cloudfront-config.json --query 'Distribution.Id' --output text)
    
    # Get distribution domain
    CLOUDFRONT_DOMAIN=$(aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'Distribution.DomainName' --output text)
    
    print_status "✅ CloudFront distribution created: https://$CLOUDFRONT_DOMAIN"
    
    rm cloudfront-config.json
}

# Test collaborative features
test_collaborative_features() {
    print_step "Testing collaborative features..."
    
    if [ ! -z "$BACKEND_URL" ]; then
        # Test WebSocket connection
        print_status "Testing WebSocket connection..."
        if curl -s "https://$BACKEND_URL/api/health" > /dev/null; then
            print_status "✅ Backend is accessible"
        else
            print_warning "⚠️  Backend might not be accessible yet"
        fi
        
        # Test Socket.IO endpoint
        print_status "Testing Socket.IO endpoint..."
        if curl -s "https://$BACKEND_URL/socket.io/" > /dev/null; then
            print_status "✅ Socket.IO endpoint is accessible"
        else
            print_warning "⚠️  Socket.IO endpoint might not be accessible yet"
        fi
    fi
    
    if [ ! -z "$FRONTEND_URL" ]; then
        print_status "Testing frontend accessibility..."
        if curl -s "$FRONTEND_URL" > /dev/null; then
            print_status "✅ Frontend is accessible"
        else
            print_warning "⚠️  Frontend might not be accessible yet"
        fi
    fi
}

# Update environment variables
update_environment() {
    print_step "Updating environment configuration..."
    
    cd backend
    
    # Set environment variables for collaborative features
    eb setenv \
        NODE_ENV=production \
        ENABLE_COLLABORATIVE_EDITING=true \
        SOCKET_IO_TIMEOUT=20000 \
        SOCKET_IO_RECONNECTION_DELAY=1000 \
        SOCKET_IO_MAX_RECONNECTION_ATTEMPTS=5
    
    print_status "✅ Environment variables updated"
    
    cd ..
}

# Main deployment function
main() {
    print_status "🚀 Starting collaborative features deployment..."
    echo ""
    
    # Pre-flight checks
    check_prerequisites
    echo ""
    
    # Prepare and deploy backend
    prepare_backend
    deploy_backend
    echo ""
    
    # Update environment
    update_environment
    echo ""
    
    # Prepare and deploy frontend
    prepare_frontend
    deploy_frontend
    echo ""
    
    # Create CloudFront distribution
    create_cloudfront
    echo ""
    
    # Test deployment
    test_collaborative_features
    echo ""
    
    # Summary
    print_status "🎉 Collaborative features deployment completed!"
    echo ""
    echo "📋 Deployment Summary:"
    echo "  Backend URL: https://$BACKEND_URL"
    echo "  Frontend S3: $FRONTEND_URL"
    echo "  CloudFront: https://$CLOUDFRONT_DOMAIN"
    echo ""
    echo "🔧 New Collaborative Features:"
    echo "  ✅ Live code editing with real-time sync"
    echo "  ✅ User cursor tracking and highlighting"
    echo "  ✅ User presence indicators"
    echo "  ✅ Typing indicators"
    echo "  ✅ Auto-save functionality"
    echo "  ✅ Conflict detection"
    echo ""
    echo "🧪 Testing Instructions:"
    echo "  1. Open the CloudFront URL in multiple browser tabs"
    echo "  2. Log in with different users"
    echo "  3. Open the Collaborative Editor"
    echo "  4. Select a project and file"
    echo "  5. Start editing - you should see live updates!"
    echo ""
    echo "📝 Useful Commands:"
    echo "  eb status          # Check backend status"
    echo "  eb logs            # View backend logs"
    echo "  eb health          # Check backend health"
    echo "  aws s3 ls s3://$FRONTEND_BUCKET  # List frontend files"
    echo ""
}

# Run main function
main "$@"
