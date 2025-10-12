#!/bin/bash

# CloudFront HTTPS Setup Script
# This script creates a CloudFront distribution for HTTPS frontend access

set -e

echo "🔒 Setting up CloudFront HTTPS for Frontend..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="us-east-1"
FRONTEND_BUCKET="awsproject-frontend-1760216054"
DISTRIBUTION_COMMENT="AWS Project Frontend HTTPS Distribution"

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

# Create CloudFront distribution
create_cloudfront_distribution() {
    print_status "Creating CloudFront distribution for HTTPS..."
    
    # Create CloudFront configuration
    cat > cloudfront-config.json << EOF
{
    "CallerReference": "$(date +%s)",
    "Comment": "$DISTRIBUTION_COMMENT",
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
    "Origins": {
        "Quantity": 1,
        "Items": [
            {
                "Id": "S3-$FRONTEND_BUCKET",
                "DomainName": "$FRONTEND_BUCKET.s3-website-$AWS_REGION.amazonaws.com",
                "CustomOriginConfig": {
                    "HTTPPort": 80,
                    "HTTPSPort": 443,
                    "OriginProtocolPolicy": "http-only"
                }
            }
        ]
    },
    "Enabled": true,
    "PriceClass": "PriceClass_100",
    "HttpVersion": "http2",
    "IsIPV6Enabled": true
}
EOF

    # Create the distribution
    DISTRIBUTION_ID=$(aws cloudfront create-distribution --distribution-config file://cloudfront-config.json --query 'Distribution.Id' --output text)
    
    print_status "CloudFront distribution created: $DISTRIBUTION_ID"
    
    # Get the domain name
    DISTRIBUTION_DOMAIN=$(aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'Distribution.DomainName' --output text)
    
    print_status "CloudFront domain: https://$DISTRIBUTION_DOMAIN"
    
    # Clean up
    rm cloudfront-config.json
    
    # Save distribution info
    cat > cloudfront-info.txt << EOF
Distribution ID: $DISTRIBUTION_ID
Domain Name: $DISTRIBUTION_DOMAIN
HTTPS URL: https://$DISTRIBUTION_DOMAIN
Status: Creating (may take 10-15 minutes to be fully available)
EOF
    
    print_status "Distribution info saved to cloudfront-info.txt"
}

# Check distribution status
check_distribution_status() {
    if [ -f "cloudfront-info.txt" ]; then
        DISTRIBUTION_ID=$(grep "Distribution ID:" cloudfront-info.txt | cut -d' ' -f3)
        
        print_status "Checking distribution status..."
        
        STATUS=$(aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'Distribution.Status' --output text)
        
        if [ "$STATUS" = "Deployed" ]; then
            print_status "✅ CloudFront distribution is ready!"
            DISTRIBUTION_DOMAIN=$(aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'Distribution.DomainName' --output text)
            print_status "🌐 Your HTTPS frontend is available at: https://$DISTRIBUTION_DOMAIN"
        else
            print_warning "⏳ CloudFront distribution is still deploying... Status: $STATUS"
            print_warning "This may take 10-15 minutes. Check again later with:"
            print_warning "aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'Distribution.Status' --output text"
        fi
    else
        print_error "cloudfront-info.txt not found. Please run the script first."
    fi
}

# Main function
main() {
    print_status "Starting CloudFront HTTPS setup..."
    
    # Pre-flight checks
    check_aws_cli
    
    # Create distribution
    create_cloudfront_distribution
    
    # Wait a moment and check status
    sleep 5
    check_distribution_status
    
    # Summary
    echo ""
    print_status "🎉 CloudFront setup completed!"
    echo ""
    echo "📋 Next Steps:"
    echo "  1. Wait 10-15 minutes for CloudFront to fully deploy"
    echo "  2. Test your HTTPS frontend URL"
    echo "  3. Camera/microphone permissions should now work!"
    echo ""
    echo "🔧 To check status later:"
    echo "  aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'Distribution.Status' --output text"
    echo ""
    echo "🌐 Your HTTPS frontend will be available at:"
    echo "  https://$DISTRIBUTION_DOMAIN"
    echo ""
}

# Check if user wants to check status
if [ "$1" = "status" ]; then
    check_distribution_status
else
    main "$@"
fi
