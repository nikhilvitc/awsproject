#!/bin/bash

# Frontend Deployment Script with CORS Fix
# This script rebuilds and redeploys the frontend to S3

set -e

echo "🚀 Deploying Frontend with CORS Fix..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="us-east-1"
FRONTEND_BUCKET="awsproject-frontend-1760216054"  # Your existing bucket
BACKEND_URL="https://awsproject-backend.onrender.com"

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

# Build frontend with correct API URL
build_frontend() {
    print_status "Building React application..."
    
    cd jellylemonshake
    
    # Set environment variable for build
    export REACT_APP_API_URL=$BACKEND_URL
    
    # Build the application
    npm run build
    
    print_status "Frontend built successfully"
    
    cd ..
}

# Deploy to S3
deploy_to_s3() {
    print_status "Deploying to S3 bucket: $FRONTEND_BUCKET"
    
    cd jellylemonshake
    
    # Upload files
    print_status "Uploading files to S3..."
    aws s3 sync build/ s3://$FRONTEND_BUCKET --delete --region $AWS_REGION
    
    print_status "Frontend deployed successfully!"
    
    cd ..
}

# Test the deployment
test_deployment() {
    print_status "Testing deployment..."
    
    FRONTEND_URL="http://$FRONTEND_BUCKET.s3-website-$AWS_REGION.amazonaws.com"
    
    print_status "Frontend URL: $FRONTEND_URL"
    print_status "Backend URL: $BACKEND_URL"
    
    # Test if backend is accessible
    if curl -s "$BACKEND_URL/api/health" > /dev/null; then
        print_status "✅ Backend is accessible"
    else
        print_warning "⚠️  Backend might not be accessible"
    fi
}

# Main deployment function
main() {
    print_status "Starting frontend deployment with CORS fix..."
    
    # Pre-flight checks
    check_aws_cli
    
    # Build and deploy
    build_frontend
    deploy_to_s3
    test_deployment
    
    # Summary
    echo ""
    print_status "🎉 Frontend deployment completed!"
    echo ""
    echo "📋 Deployment Summary:"
    echo "  Frontend URL: http://$FRONTEND_BUCKET.s3-website-$AWS_REGION.amazonaws.com"
    echo "  Backend URL: $BACKEND_URL"
    echo ""
    echo "🔧 CORS Configuration Updated:"
    echo "  ✅ Added S3 website hosting domains to CORS whitelist"
    echo "  ✅ Updated API base URL to point to your backend"
    echo "  ✅ Fixed regex patterns for S3 domains"
    echo ""
    echo "🧪 Test your application:"
    echo "  1. Open: http://$FRONTEND_BUCKET.s3-website-$AWS_REGION.amazonaws.com"
    echo "  2. Check browser console for CORS errors"
    echo "  3. Test room creation and messaging"
    echo ""
}

# Run main function
main "$@"
