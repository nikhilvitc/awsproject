#!/bin/bash

# Frontend Update Script for Collaborative Features
# This script updates the frontend with new collaborative editing features

set -e

echo "🚀 Updating Frontend with Collaborative Features..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="us-east-1"
FRONTEND_BUCKET=""
CLOUDFRONT_DISTRIBUTION_ID=""

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

# Get backend URL from user
get_backend_url() {
    echo -n "Enter your backend URL (e.g., https://your-app.elasticbeanstalk.com): "
    read BACKEND_URL
    
    if [ -z "$BACKEND_URL" ]; then
        print_error "Backend URL is required"
        exit 1
    fi
    
    print_status "Using backend URL: $BACKEND_URL"
}

# Get S3 bucket name
get_s3_bucket() {
    echo -n "Enter your S3 bucket name for frontend: "
    read FRONTEND_BUCKET
    
    if [ -z "$FRONTEND_BUCKET" ]; then
        print_error "S3 bucket name is required"
        exit 1
    fi
    
    print_status "Using S3 bucket: $FRONTEND_BUCKET"
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

# Update frontend configuration
update_frontend_config() {
    print_step "Updating frontend configuration..."
    
    cd jellylemonshake
    
    # Update API URL in config.js
    print_status "Updating API URL to: $BACKEND_URL"
    sed -i.bak "s|http://localhost:5000|$BACKEND_URL|g" src/config.js
    
    # Update any hardcoded URLs in source files
    print_status "Updating hardcoded URLs..."
    find src -name "*.js" -exec sed -i.bak "s|http://localhost:5000|$BACKEND_URL|g" {} \;
    
    print_status "✅ Frontend configuration updated"
    cd ..
}

# Build frontend
build_frontend() {
    print_step "Building frontend with collaborative features..."
    
    cd jellylemonshake
    
    # Install dependencies
    print_status "Installing dependencies..."
    npm install
    
    # Build the application
    print_status "Building React application..."
    npm run build
    
    print_status "✅ Frontend built successfully"
    cd ..
}

# Deploy to S3
deploy_to_s3() {
    print_step "Deploying to S3..."
    
    cd jellylemonshake
    
    # Upload files to S3
    print_status "Uploading files to S3 bucket: $FRONTEND_BUCKET"
    aws s3 sync build/ s3://$FRONTEND_BUCKET --delete
    
    print_status "✅ Frontend deployed to S3"
    cd ..
}

# Invalidate CloudFront cache
invalidate_cloudfront() {
    print_step "Invalidating CloudFront cache..."
    
    echo -n "Enter your CloudFront distribution ID (optional): "
    read CLOUDFRONT_DISTRIBUTION_ID
    
    if [ ! -z "$CLOUDFRONT_DISTRIBUTION_ID" ]; then
        print_status "Invalidating CloudFront cache..."
        aws cloudfront create-invalidation \
            --distribution-id $CLOUDFRONT_DISTRIBUTION_ID \
            --paths "/*"
        print_status "✅ CloudFront cache invalidated"
    else
        print_warning "Skipping CloudFront invalidation"
    fi
}

# Test deployment
test_deployment() {
    print_step "Testing deployment..."
    
    # Get S3 website URL
    S3_URL="http://$FRONTEND_BUCKET.s3-website-$AWS_REGION.amazonaws.com"
    
    print_status "Testing frontend accessibility..."
    if curl -s "$S3_URL" > /dev/null; then
        print_status "✅ Frontend is accessible at: $S3_URL"
    else
        print_warning "⚠️  Frontend might not be accessible yet"
    fi
}

# Main function
main() {
    print_status "Starting frontend update..."
    echo ""
    
    # Get configuration from user
    get_backend_url
    get_s3_bucket
    echo ""
    
    # Check prerequisites
    check_prerequisites
    echo ""
    
    # Update and build frontend
    update_frontend_config
    build_frontend
    echo ""
    
    # Deploy to S3
    deploy_to_s3
    echo ""
    
    # Invalidate CloudFront cache
    invalidate_cloudfront
    echo ""
    
    # Test deployment
    test_deployment
    echo ""
    
    # Summary
    print_status "🎉 Frontend update completed!"
    echo ""
    echo "📋 Update Summary:"
    echo "  Backend URL: $BACKEND_URL"
    echo "  S3 Bucket: $FRONTEND_BUCKET"
    echo "  Frontend URL: http://$FRONTEND_BUCKET.s3-website-$AWS_REGION.amazonaws.com"
    echo ""
    echo "🔧 New Collaborative Features:"
    echo "  ✅ Live code editing interface"
    echo "  ✅ Real-time cursor tracking"
    echo "  ✅ User presence indicators"
    echo "  ✅ Typing indicators"
    echo "  ✅ Auto-save functionality"
    echo "  ✅ Conflict detection"
    echo ""
    echo "🧪 Testing Instructions:"
    echo "  1. Open the frontend URL in multiple browser tabs"
    echo "  2. Log in with different users"
    echo "  3. Open the Collaborative Editor"
    echo "  4. Select a project and file"
    echo "  5. Start editing - you should see live updates!"
    echo ""
}

# Run main function
main "$@"
