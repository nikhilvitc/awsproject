#!/bin/bash

# AWS Credentials Setup Script
# This script helps you set up your AWS credentials for local development

echo "🔧 AWS Credentials Setup for DynamoDB Application"
echo "=================================================="
echo ""

# Check if .env file already exists
if [ -f ".env" ]; then
    echo "⚠️  .env file already exists!"
    read -p "Do you want to overwrite it? (y/N): " overwrite
    if [[ ! $overwrite =~ ^[Yy]$ ]]; then
        echo "Setup cancelled."
        exit 0
    fi
fi

echo "Please enter your AWS credentials:"
echo ""

# Get AWS Region
read -p "AWS Region (default: us-east-1): " aws_region
aws_region=${aws_region:-us-east-1}

# Get Access Key ID
read -p "AWS Access Key ID: " aws_access_key_id
if [ -z "$aws_access_key_id" ]; then
    echo "❌ Access Key ID is required!"
    exit 1
fi

# Get Secret Access Key
read -s -p "AWS Secret Access Key: " aws_secret_access_key
echo ""
if [ -z "$aws_secret_access_key" ]; then
    echo "❌ Secret Access Key is required!"
    exit 1
fi

# Get Port
read -p "Application Port (default: 5000): " port
port=${port:-5000}

# Create .env file
cat > .env << EOF
# AWS Configuration
AWS_REGION=$aws_region
AWS_ACCESS_KEY_ID=$aws_access_key_id
AWS_SECRET_ACCESS_KEY=$aws_secret_access_key

# Application Configuration
PORT=$port
NODE_ENV=development

# DynamoDB Table Names
CHAT_ROOMS_TABLE=ChatRooms
MESSAGES_TABLE=Messages
MEETINGS_TABLE=Meetings
PROJECTS_TABLE=Projects
PROJECT_FILES_TABLE=ProjectFiles
EOF

echo ""
echo "✅ .env file created successfully!"
echo ""
echo "🔍 Next steps:"
echo "1. Test your connection: npm run test"
echo "2. Create DynamoDB tables: npm run create-tables"
echo "3. Check setup: npm run check-setup"
echo "4. Start development server: npm run dev"
echo ""
echo "⚠️  Remember: Never commit your .env file to version control!"
