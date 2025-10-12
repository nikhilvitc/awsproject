#!/bin/bash

# Update Frontend to Use AWS Backend
# This script updates the frontend to point to your AWS backend

set -e

echo "🔄 Updating Frontend to Use AWS Backend..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
AWS_BACKEND_URL=""
FRONTEND_BUCKET="awsproject-frontend-1760216054"
AWS_REGION="us-east-1"

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

# Get AWS backend URL
get_backend_url() {
    print_status "Getting AWS backend URL..."
    
    cd backend
    
    if [ -f ".elasticbeanstalk/config.yml" ]; then
        # Get the URL from EB status
        BACKEND_URL=$(eb status | grep "CNAME" | awk '{print $2}')
        if [ ! -z "$BACKEND_URL" ]; then
            AWS_BACKEND_URL="https://$BACKEND_URL"
            print_status "Found AWS backend URL: $AWS_BACKEND_URL"
        else
            print_error "Could not find AWS backend URL. Make sure your backend is deployed."
            exit 1
        fi
    else
        print_error "Elastic Beanstalk not initialized. Please deploy backend first."
        exit 1
    fi
    
    cd ..
}

# Update frontend API configuration
update_frontend_config() {
    print_status "Updating frontend API configuration..."
    
    cd jellylemonshake
    
    # Update API base URL
    sed -i.bak "s|export const API_BASE_URL = process.env.REACT_APP_API_URL || \".*\"|export const API_BASE_URL = process.env.REACT_APP_API_URL || \"$AWS_BACKEND_URL\"|" src/components/api.js
    
    print_status "Frontend API configuration updated"
    
    cd ..
}

# Build frontend with AWS backend URL
build_frontend() {
    print_status "Building frontend with AWS backend URL..."
    
    cd jellylemonshake
    
    # Set environment variable
    export REACT_APP_API_URL="$AWS_BACKEND_URL"
    
    # Build
    npm run build
    
    print_status "Frontend built successfully"
    
    cd ..
}

# Deploy to S3
deploy_to_s3() {
    print_status "Deploying updated frontend to S3..."
    
    cd jellylemonshake
    
    # Upload to S3
    aws s3 sync build/ s3://$FRONTEND_BUCKET --delete --region $AWS_REGION
    
    print_status "Frontend deployed to S3"
    
    cd ..
}

# Test the deployment
test_deployment() {
    print_status "Testing deployment..."
    
    FRONTEND_URL="http://$FRONTEND_BUCKET.s3-website-$AWS_REGION.amazonaws.com"
    
    print_status "Frontend URL: $FRONTEND_URL"
    print_status "Backend URL: $AWS_BACKEND_URL"
    
    # Test backend
    if curl -s "$AWS_BACKEND_URL/api/health" > /dev/null; then
        print_status "✅ AWS Backend is accessible"
    else
        print_warning "⚠️  AWS Backend might not be accessible"
    fi
}

# Main function
main() {
    print_status "Starting frontend update for AWS backend..."
    
    # Get backend URL
    get_backend_url
    
    # Update and deploy
    update_frontend_config
    build_frontend
    deploy_to_s3
    test_deployment
    
    # Summary
    echo ""
    print_status "🎉 Frontend updated for AWS backend!"
    echo ""
    echo "📋 Deployment Summary:"
    echo "  Frontend URL: http://$FRONTEND_BUCKET.s3-website-$AWS_REGION.amazonaws.com"
    echo "  Backend URL: $AWS_BACKEND_URL"
    echo ""
    echo "🧪 Test your application:"
    echo "  1. Open: http://$FRONTEND_BUCKET.s3-website-$AWS_REGION.amazonaws.com"
    echo "  2. Test room creation and messaging"
    echo "  3. Verify real-time chat works"
    echo ""
}

# Run main function
main "$@"
