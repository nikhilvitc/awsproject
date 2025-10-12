#!/bin/bash

# Quick Netlify HTTPS Deployment Script
# This script deploys your frontend to Netlify with automatic HTTPS

set -e

echo "🚀 Quick Netlify HTTPS Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
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

# Check if Netlify CLI is installed
check_netlify_cli() {
    if ! command -v netlify &> /dev/null; then
        print_error "Netlify CLI is not installed."
        print_status "Installing Netlify CLI..."
        npm install -g netlify-cli
    fi
    print_status "Netlify CLI found"
}

# Build frontend
build_frontend() {
    print_status "Building React application..."
    
    cd jellylemonshake
    
    # Set environment variable for build
    export REACT_APP_API_URL=$BACKEND_URL
    
    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
        print_status "Installing dependencies..."
        npm install
    fi
    
    # Build the application
    npm run build
    
    print_status "Frontend built successfully"
    
    cd ..
}

# Deploy to Netlify
deploy_to_netlify() {
    print_status "Deploying to Netlify..."
    
    cd jellylemonshake
    
    # Check if user is logged in
    if ! netlify status &> /dev/null; then
        print_status "Please log in to Netlify..."
        netlify login
    fi
    
    # Deploy to production
    print_status "Deploying to production..."
    NETLIFY_URL=$(netlify deploy --prod --dir=build --json | jq -r '.url')
    
    print_status "✅ Frontend deployed to Netlify!"
    print_status "🌐 HTTPS URL: $NETLIFY_URL"
    
    cd ..
    
    echo "$NETLIFY_URL" > netlify-url.txt
}

# Test the deployment
test_deployment() {
    if [ -f "netlify-url.txt" ]; then
        NETLIFY_URL=$(cat netlify-url.txt)
        print_status "Testing deployment..."
        
        # Test if the site is accessible
        if curl -s "$NETLIFY_URL" > /dev/null; then
            print_status "✅ Frontend is accessible"
        else
            print_warning "⚠️  Frontend might not be accessible yet"
        fi
        
        # Test if backend is accessible
        if curl -s "$BACKEND_URL/api/health" > /dev/null; then
            print_status "✅ Backend is accessible"
        else
            print_warning "⚠️  Backend might not be accessible"
        fi
    fi
}

# Main deployment function
main() {
    print_status "Starting Netlify HTTPS deployment..."
    
    # Pre-flight checks
    check_netlify_cli
    
    # Build and deploy
    build_frontend
    deploy_to_netlify
    test_deployment
    
    # Summary
    echo ""
    print_status "🎉 Netlify deployment completed!"
    echo ""
    if [ -f "netlify-url.txt" ]; then
        NETLIFY_URL=$(cat netlify-url.txt)
        echo "📋 Deployment Summary:"
        echo "  Frontend URL (HTTPS): $NETLIFY_URL"
        echo "  Backend URL: $BACKEND_URL"
        echo ""
        echo "🔒 HTTPS Benefits:"
        echo "  ✅ Camera/microphone permissions will now work"
        echo "  ✅ WebRTC video calls will function properly"
        echo "  ✅ Secure connection for all users"
        echo ""
        echo "🧪 Test your application:"
        echo "  1. Open: $NETLIFY_URL"
        echo "  2. Try the video call feature"
        echo "  3. Camera permissions should now be requested properly"
        echo ""
    fi
}

# Run main function
main "$@"
