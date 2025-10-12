#!/bin/bash

# Create CloudFront Distribution for Backend HTTPS (Fixed)
echo "🚀 Creating CloudFront Distribution for Backend HTTPS..."

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
BACKEND_DOMAIN="awsproject-backend-prod.eba-fphuu5yq.us-east-1.elasticbeanstalk.com"

print_step "Creating CloudFront distribution for backend: ${BACKEND_DOMAIN}"

# Create CloudFront distribution configuration for backend (Fixed)
cat > backend-cloudfront-config.json << EOF
{
  "CallerReference": "awsproject-backend-$(date +%s)",
  "Comment": "AWS Project Backend HTTPS Distribution",
  "DefaultRootObject": "",
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "Backend-${BACKEND_DOMAIN}",
        "DomainName": "${BACKEND_DOMAIN}",
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
    "TargetOriginId": "Backend-${BACKEND_DOMAIN}",
    "ViewerProtocolPolicy": "redirect-to-https",
    "TrustedSigners": {
      "Enabled": false,
      "Quantity": 0
    },
    "ForwardedValues": {
      "QueryString": true,
      "Cookies": {
        "Forward": "all"
      },
      "Headers": {
        "Quantity": 4,
        "Items": ["Authorization", "Content-Type", "Origin", "Referer"]
      }
    },
    "MinTTL": 0,
    "DefaultTTL": 0,
    "MaxTTL": 0
  },
  "CacheBehaviors": {
    "Quantity": 2,
    "Items": [
      {
        "PathPattern": "/api/*",
        "TargetOriginId": "Backend-${BACKEND_DOMAIN}",
        "ViewerProtocolPolicy": "redirect-to-https",
        "TrustedSigners": {
          "Enabled": false,
          "Quantity": 0
        },
        "ForwardedValues": {
          "QueryString": true,
          "Cookies": {
            "Forward": "all"
          },
          "Headers": {
            "Quantity": 5,
            "Items": ["Authorization", "Content-Type", "Origin", "Referer", "X-Requested-With"]
          }
        },
        "MinTTL": 0,
        "DefaultTTL": 0,
        "MaxTTL": 0
      },
      {
        "PathPattern": "/socket.io/*",
        "TargetOriginId": "Backend-${BACKEND_DOMAIN}",
        "ViewerProtocolPolicy": "redirect-to-https",
        "TrustedSigners": {
          "Enabled": false,
          "Quantity": 0
        },
        "ForwardedValues": {
          "QueryString": true,
          "Cookies": {
            "Forward": "all"
          },
          "Headers": {
            "Quantity": 5,
            "Items": ["Authorization", "Content-Type", "Origin", "Referer", "X-Requested-With"]
          }
        },
        "MinTTL": 0,
        "DefaultTTL": 0,
        "MaxTTL": 0
      }
    ]
  },
  "Enabled": true,
  "PriceClass": "PriceClass_100"
}
EOF

print_step "Creating CloudFront distribution for backend..."

# Create the distribution
BACKEND_DISTRIBUTION_ID=$(aws cloudfront create-distribution --distribution-config file://backend-cloudfront-config.json --query 'Distribution.Id' --output text)

if [ $? -eq 0 ] && [ ! -z "$BACKEND_DISTRIBUTION_ID" ]; then
    print_status "Backend CloudFront distribution created successfully!"
    echo "Backend Distribution ID: ${BACKEND_DISTRIBUTION_ID}"
    
    # Get the domain name
    BACKEND_DISTRIBUTION_DOMAIN=$(aws cloudfront get-distribution --id ${BACKEND_DISTRIBUTION_ID} --query 'Distribution.DomainName' --output text)
    
    print_status "Backend Distribution Domain: ${BACKEND_DISTRIBUTION_DOMAIN}"
    
    echo ""
    print_step "📋 Next Steps:"
    echo "1. Wait 10-15 minutes for CloudFront to deploy"
    echo "2. Update frontend config to use HTTPS backend"
    echo "3. Test login with HTTPS backend"
    echo ""
    print_warning "Note: Backend CloudFront deployment takes 10-15 minutes."
    
    # Save distribution info
    echo "BACKEND_DISTRIBUTION_ID=${BACKEND_DISTRIBUTION_ID}" > backend-cloudfront-info.env
    echo "BACKEND_DISTRIBUTION_DOMAIN=${BACKEND_DISTRIBUTION_DOMAIN}" >> backend-cloudfront-info.env
    
    print_status "Backend distribution info saved to backend-cloudfront-info.env"
    
else
    print_error "Failed to create backend CloudFront distribution"
    exit 1
fi

# Clean up
rm backend-cloudfront-config.json

print_status "✅ Backend CloudFront distribution creation initiated!"
echo ""
echo "🌐 Your HTTPS Backend URL will be: https://${BACKEND_DISTRIBUTION_DOMAIN}"
echo "⏰ Wait 10-15 minutes for deployment to complete"
echo "🔐 Mixed content issue will be resolved!"
