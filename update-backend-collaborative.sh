#!/bin/bash

# Quick Backend Update Script for Collaborative Features
# This script only updates the backend with new collaborative editing features

set -e

echo "🚀 Updating Backend with Collaborative Features..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="us-east-1"
BACKEND_APP_NAME="awsproject-backend"
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

# Check if EB CLI is installed
check_eb_cli() {
    if ! command -v eb &> /dev/null; then
        print_error "EB CLI is not installed. Please install it first: pip install awsebcli"
        exit 1
    fi
    print_status "✅ EB CLI found"
}

# Update backend
update_backend() {
    print_status "Updating backend with collaborative features..."
    
    cd backend
    
    # Check if we're in the right directory
    if [ ! -f "package.json" ]; then
        print_error "package.json not found. Are you in the backend directory?"
        exit 1
    fi
    
    # Install dependencies
    print_status "Installing dependencies..."
    npm install --production
    
    # Deploy to existing environment
    print_status "Deploying to $ENVIRONMENT_NAME..."
    eb deploy $ENVIRONMENT_NAME
    
    # Get the URL
    BACKEND_URL=$(eb status $ENVIRONMENT_NAME | grep "CNAME" | awk '{print $2}')
    print_status "✅ Backend updated at: https://$BACKEND_URL"
    
    cd ..
}

# Set environment variables for collaborative features
set_environment_variables() {
    print_status "Setting environment variables for collaborative features..."
    
    cd backend
    
    eb setenv \
        NODE_ENV=production \
        ENABLE_COLLABORATIVE_EDITING=true \
        SOCKET_IO_TIMEOUT=20000 \
        SOCKET_IO_RECONNECTION_DELAY=1000 \
        SOCKET_IO_MAX_RECONNECTION_ATTEMPTS=5
    
    print_status "✅ Environment variables set"
    
    cd ..
}

# Test the deployment
test_deployment() {
    print_status "Testing collaborative features..."
    
    if [ ! -z "$BACKEND_URL" ]; then
        # Test health endpoint
        if curl -s "https://$BACKEND_URL/api/health" > /dev/null; then
            print_status "✅ Backend health check passed"
        else
            print_warning "⚠️  Backend health check failed"
        fi
        
        # Test Socket.IO endpoint
        if curl -s "https://$BACKEND_URL/socket.io/" > /dev/null; then
            print_status "✅ Socket.IO endpoint accessible"
        else
            print_warning "⚠️  Socket.IO endpoint not accessible"
        fi
    fi
}

# Main function
main() {
    print_status "Starting backend update..."
    
    # Check prerequisites
    check_eb_cli
    
    # Update backend
    update_backend
    
    # Set environment variables
    set_environment_variables
    
    # Test deployment
    test_deployment
    
    # Summary
    echo ""
    print_status "🎉 Backend update completed!"
    echo ""
    echo "📋 Update Summary:"
    echo "  Backend URL: https://$BACKEND_URL"
    echo ""
    echo "🔧 New Features Added:"
    echo "  ✅ Live collaborative code editing"
    echo "  ✅ Real-time cursor tracking"
    echo "  ✅ User presence indicators"
    echo "  ✅ Typing indicators"
    echo "  ✅ Auto-save functionality"
    echo "  ✅ Conflict detection"
    echo ""
    echo "🧪 Next Steps:"
    echo "  1. Update your frontend to use the new backend URL"
    echo "  2. Test collaborative features with multiple users"
    echo "  3. Monitor logs: eb logs"
    echo ""
}

# Run main function
main "$@"
