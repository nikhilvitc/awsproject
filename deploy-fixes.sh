#!/bin/bash

# Deploy Critical Fixes Script
# This script deploys the backend and frontend fixes to AWS

set -e  # Exit on error

echo "🚀 AWS Project Critical Fixes Deployment"
echo "========================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BACKEND_ENV="awsproject-backend-prod"
BACKEND_APP="awsproject-backend"
VERSION_LABEL="v1.0.1-fixed-$(date +%Y%m%d-%H%M%S)"

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")

if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo -e "${RED}❌ Error: Unable to get AWS Account ID. Make sure AWS CLI is configured.${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} AWS Account ID: $AWS_ACCOUNT_ID"
echo ""

# Function to deploy backend
deploy_backend() {
    echo "📦 Deploying Backend to Elastic Beanstalk..."
    echo "   Environment: $BACKEND_ENV"
    echo "   Version: $VERSION_LABEL"
    echo ""
    
    if [ ! -f "awsproject-backend-deploy-fixed.zip" ]; then
        echo -e "${RED}❌ Error: awsproject-backend-deploy-fixed.zip not found${NC}"
        exit 1
    fi
    
    # Upload to S3
    S3_BUCKET="elasticbeanstalk-us-east-1-$AWS_ACCOUNT_ID"
    S3_KEY="$BACKEND_APP/$VERSION_LABEL.zip"
    
    echo "   Uploading to S3..."
    aws s3 cp awsproject-backend-deploy-fixed.zip "s3://$S3_BUCKET/$S3_KEY" || {
        echo -e "${RED}❌ Error: Failed to upload to S3${NC}"
        exit 1
    }
    
    echo -e "${GREEN}   ✓${NC} Uploaded to S3"
    
    # Create application version
    echo "   Creating application version..."
    aws elasticbeanstalk create-application-version \
        --application-name "$BACKEND_APP" \
        --version-label "$VERSION_LABEL" \
        --source-bundle "S3Bucket=$S3_BUCKET,S3Key=$S3_KEY" \
        --description "Critical fixes: HTTPS config, fixed chatrooms.js route" || {
        echo -e "${RED}❌ Error: Failed to create application version${NC}"
        exit 1
    }
    
    echo -e "${GREEN}   ✓${NC} Application version created"
    
    # Update environment
    echo "   Updating environment..."
    aws elasticbeanstalk update-environment \
        --environment-name "$BACKEND_ENV" \
        --version-label "$VERSION_LABEL" || {
        echo -e "${RED}❌ Error: Failed to update environment${NC}"
        exit 1
    }
    
    echo -e "${GREEN}   ✓${NC} Environment update initiated"
    echo ""
    echo -e "${GREEN}✅ Backend deployment started!${NC}"
    echo "   Monitor progress at: https://console.aws.amazon.com/elasticbeanstalk/"
    echo ""
}

# Function to deploy frontend
deploy_frontend() {
    echo "📦 Deploying Frontend..."
    echo ""
    
    # Ask for S3 bucket name
    read -p "   Enter your S3 bucket name for frontend hosting: " S3_BUCKET
    
    if [ -z "$S3_BUCKET" ]; then
        echo -e "${RED}❌ Error: S3 bucket name is required${NC}"
        exit 1
    fi
    
    # Ask for CloudFront distribution ID (optional)
    read -p "   Enter your CloudFront distribution ID (press Enter to skip): " CF_DIST_ID
    
    # Extract frontend build
    if [ ! -f "awsproject-frontend-deploy-fixed.zip" ]; then
        echo -e "${RED}❌ Error: awsproject-frontend-deploy-fixed.zip not found${NC}"
        exit 1
    fi
    
    echo "   Extracting frontend build..."
    unzip -q -o awsproject-frontend-deploy-fixed.zip -d ./temp-frontend
    
    # Sync to S3
    echo "   Syncing to S3..."
    aws s3 sync ./temp-frontend/build "s3://$S3_BUCKET" --delete || {
        echo -e "${RED}❌ Error: Failed to sync to S3${NC}"
        rm -rf ./temp-frontend
        exit 1
    }
    
    echo -e "${GREEN}   ✓${NC} Synced to S3"
    
    # Clean up
    rm -rf ./temp-frontend
    
    # Invalidate CloudFront cache if distribution ID provided
    if [ ! -z "$CF_DIST_ID" ]; then
        echo "   Invalidating CloudFront cache..."
        aws cloudfront create-invalidation \
            --distribution-id "$CF_DIST_ID" \
            --paths "/*" > /dev/null || {
            echo -e "${YELLOW}⚠️  Warning: Failed to invalidate CloudFront cache${NC}"
        }
        echo -e "${GREEN}   ✓${NC} CloudFront cache invalidated"
    fi
    
    echo ""
    echo -e "${GREEN}✅ Frontend deployment complete!${NC}"
    echo "   URL: https://$S3_BUCKET.s3-website-us-east-1.amazonaws.com"
    echo ""
}

# Main menu
echo "What would you like to deploy?"
echo "1) Backend only"
echo "2) Frontend only"
echo "3) Both backend and frontend"
echo "4) Exit"
echo ""
read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        deploy_backend
        ;;
    2)
        deploy_frontend
        ;;
    3)
        deploy_backend
        echo ""
        deploy_frontend
        ;;
    4)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo "========================================"
echo -e "${GREEN}🎉 Deployment process complete!${NC}"
echo "========================================"
echo ""
echo "📋 Next Steps:"
echo "   1. Monitor backend deployment in AWS Console"
echo "   2. Test the application endpoints"
echo "   3. Check browser console for WebSocket connections"
echo "   4. Verify no CSP errors appear"
echo ""
echo "📖 For detailed verification steps, see: CRITICAL_FIXES_SUMMARY.md"
echo ""

