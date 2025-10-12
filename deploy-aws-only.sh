#!/bin/bash

# AWS-Only Deployment Script
# This script deploys only to your existing AWS infrastructure

set -e

echo "🚀 Deploying to AWS Only..."

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

# Deploy backend to AWS Elastic Beanstalk
deploy_backend_aws() {
    print_status "Deploying backend to AWS Elastic Beanstalk..."
    
    cd backend
    
    # Check if we're in the right directory
    if [ ! -f "package.json" ]; then
        print_error "package.json not found. Are you in the backend directory?"
        exit 1
    fi
    
    # Deploy to existing environment
    print_status "Deploying to awsproject-backend-prod..."
    eb deploy awsproject-backend-prod
    
    # Get the URL
    BACKEND_URL=$(eb status awsproject-backend-prod | grep "CNAME" | awk '{print $2}')
    print_status "✅ Backend deployed at: https://$BACKEND_URL"
    
    cd ..
}

# Update frontend configuration for AWS
update_frontend_for_aws() {
    print_status "Updating frontend configuration for AWS..."
    
    cd jellylemonshake
    
    # Update API URL to use HTTPS
    print_status "Updating API URL to use HTTPS..."
    sed -i.bak 's|http://awsproject-backend-prod.eba-fphuu5yq.us-east-1.elasticbeanstalk.com|https://awsproject-backend-prod.eba-fphuu5yq.us-east-1.elasticbeanstalk.com|g' src/config.js
    
    # Build the application
    print_status "Building frontend for AWS..."
    npm run build
    
    print_status "✅ Frontend built successfully"
    cd ..
}

# Test AWS deployment
test_aws_deployment() {
    print_status "Testing AWS deployment..."
    
    BACKEND_URL="awsproject-backend-prod.eba-fphuu5yq.us-east-1.elasticbeanstalk.com"
    
    # Test backend health
    print_status "Testing backend health..."
    if curl -s --connect-timeout 10 "https://$BACKEND_URL/api/health" > /dev/null; then
        print_status "✅ Backend health check passed"
    else
        print_warning "⚠️  Backend health check failed"
    fi
    
    # Test Socket.IO endpoint
    print_status "Testing Socket.IO endpoint..."
    if curl -s --connect-timeout 10 "https://$BACKEND_URL/socket.io/" > /dev/null; then
        print_status "✅ Socket.IO endpoint accessible"
    else
        print_warning "⚠️  Socket.IO endpoint not accessible"
    fi
}

# Main function
main() {
    print_status "Starting AWS-only deployment..."
    echo ""
    
    # Deploy backend
    deploy_backend_aws
    echo ""
    
    # Update frontend
    update_frontend_for_aws
    echo ""
    
    # Test deployment
    test_aws_deployment
    echo ""
    
    # Summary
    print_status "🎉 AWS deployment completed!"
    echo ""
    echo "📋 Deployment Summary:"
    echo "  Backend URL: https://awsproject-backend-prod.eba-fphuu5yq.us-east-1.elasticbeanstalk.com"
    echo ""
    echo "🔧 Collaborative Features Deployed:"
    echo "  ✅ Live code editing with real-time sync"
    echo "  ✅ User cursor tracking and highlighting"
    echo "  ✅ User presence indicators"
    echo "  ✅ Typing indicators"
    echo "  ✅ Auto-save functionality"
    echo "  ✅ Conflict detection"
    echo "  ✅ Improved CORS configuration"
    echo ""
    echo "🧪 Testing Instructions:"
    echo "  1. Open your frontend application"
    echo "  2. Open the Collaborative Editor"
    echo "  3. Click the '🧪 Test' button to simulate collaboration"
    echo "  4. Check browser console for debug messages"
    echo "  5. Look for 'Live Collaboration Active' status"
    echo ""
}

# Run main function
main "$@"
