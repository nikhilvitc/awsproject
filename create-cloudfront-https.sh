#!/bin/bash

# Create CloudFront Distribution for HTTPS Frontend
echo "🚀 Creating CloudFront Distribution for HTTPS..."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
BUCKET_NAME="awsproject-frontend-1760218803"
BUCKET_DOMAIN="${BUCKET_NAME}.s3-website-us-east-1.amazonaws.com"

print_step "Creating CloudFront distribution for bucket: ${BUCKET_NAME}"

# Create CloudFront distribution configuration
cat > cloudfront-config.json << EOF
{
  "CallerReference": "awsproject-frontend-$(date +%s)",
  "Comment": "AWS Project Frontend HTTPS Distribution",
  "DefaultRootObject": "index.html",
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "S3-${BUCKET_NAME}",
        "DomainName": "${BUCKET_DOMAIN}",
        "CustomOriginConfig": {
          "HTTPPort": 80,
          "HTTPSPort": 443,
          "OriginProtocolPolicy": "http-only",
          "OriginSslProtocols": {
            "Quantity": 1,
            "Items": ["TLSv1.2"]
          }
        }
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3-${BUCKET_NAME}",
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
  "CacheBehaviors": {
    "Quantity": 1,
    "Items": [
      {
        "PathPattern": "/static/*",
        "TargetOriginId": "S3-${BUCKET_NAME}",
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
        "DefaultTTL": 31536000,
        "MaxTTL": 31536000
      }
    ]
  },
  "Enabled": true,
  "PriceClass": "PriceClass_100"
}
EOF

print_step "Creating CloudFront distribution..."

# Create the distribution
DISTRIBUTION_ID=$(aws cloudfront create-distribution --distribution-config file://cloudfront-config.json --query 'Distribution.Id' --output text)

if [ $? -eq 0 ] && [ ! -z "$DISTRIBUTION_ID" ]; then
    print_status "CloudFront distribution created successfully!"
    echo "Distribution ID: ${DISTRIBUTION_ID}"
    
    # Get the domain name
    DISTRIBUTION_DOMAIN=$(aws cloudfront get-distribution --id ${DISTRIBUTION_ID} --query 'Distribution.DomainName' --output text)
    
    print_status "Distribution Domain: ${DISTRIBUTION_DOMAIN}"
    
    echo ""
    print_step "📋 Next Steps:"
    echo "1. Wait 10-15 minutes for CloudFront to deploy"
    echo "2. Test HTTPS access: https://${DISTRIBUTION_DOMAIN}"
    echo "3. Update your frontend config to use HTTPS"
    echo ""
    print_warning "Note: CloudFront deployment takes 10-15 minutes. The distribution will show 'InProgress' status initially."
    
    # Save distribution info
    echo "DISTRIBUTION_ID=${DISTRIBUTION_ID}" > cloudfront-info.env
    echo "DISTRIBUTION_DOMAIN=${DISTRIBUTION_DOMAIN}" >> cloudfront-info.env
    
    print_status "Distribution info saved to cloudfront-info.env"
    
else
    print_error "Failed to create CloudFront distribution"
    exit 1
fi

# Clean up
rm cloudfront-config.json

print_status "✅ CloudFront distribution creation initiated!"
echo ""
echo "🌐 Your HTTPS URL will be: https://${DISTRIBUTION_DOMAIN}"
echo "⏰ Wait 10-15 minutes for deployment to complete"
echo "🎥 Video calls will work once HTTPS is active!"
