#!/bin/bash

# Create IAM Role for DynamoDB Chat App
# This script creates the necessary IAM roles and policies for AWS deployment

set -e

echo "🔐 Creating IAM Roles for DynamoDB Chat App..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create trust policy for Elastic Beanstalk
create_trust_policy() {
    cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Create DynamoDB policy
create_dynamodb_policy() {
    cat > dynamodb-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:Query",
                "dynamodb:Scan",
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:UpdateItem",
                "dynamodb:DeleteItem",
                "dynamodb:BatchGetItem",
                "dynamodb:BatchWriteItem"
            ],
            "Resource": [
                "arn:aws:dynamodb:*:*:table/ChatRooms",
                "arn:aws:dynamodb:*:*:table/Messages",
                "arn:aws:dynamodb:*:*:table/Meetings",
                "arn:aws:dynamodb:*:*:table/Projects",
                "arn:aws:dynamodb:*:*:table/ChatRooms/index/*",
                "arn:aws:dynamodb:*:*:table/Messages/index/*",
                "arn:aws:dynamodb:*:*:table/Meetings/index/*",
                "arn:aws:dynamodb:*:*:table/Projects/index/*"
            ]
        }
    ]
}
EOF
}

# Create CloudWatch policy
create_cloudwatch_policy() {
    cat > cloudwatch-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricData",
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:ListMetrics"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

# Main function
main() {
    print_status "Creating IAM roles and policies..."
    
    # Create trust policy
    create_trust_policy
    print_status "Created trust policy"
    
    # Create DynamoDB policy
    create_dynamodb_policy
    print_status "Created DynamoDB policy"
    
    # Create CloudWatch policy
    create_cloudwatch_policy
    print_status "Created CloudWatch policy"
    
    # Create IAM role
    print_status "Creating IAM role: DynamoDBChatAppRole"
    aws iam create-role \
        --role-name DynamoDBChatAppRole \
        --assume-role-policy-document file://trust-policy.json \
        --description "Role for DynamoDB Chat App Elastic Beanstalk instances"
    
    # Create and attach DynamoDB policy
    print_status "Creating DynamoDB policy..."
    aws iam create-policy \
        --policy-name DynamoDBChatAppDynamoDBPolicy \
        --policy-document file://dynamodb-policy.json \
        --description "DynamoDB access policy for chat app"
    
    # Get policy ARN
    POLICY_ARN=$(aws iam list-policies --query 'Policies[?PolicyName==`DynamoDBChatAppDynamoDBPolicy`].Arn' --output text)
    
    # Attach DynamoDB policy to role
    aws iam attach-role-policy \
        --role-name DynamoDBChatAppRole \
        --policy-arn $POLICY_ARN
    
    # Attach CloudWatch policy to role
    aws iam attach-role-policy \
        --role-name DynamoDBChatAppRole \
        --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess
    
    # Create instance profile
    print_status "Creating instance profile..."
    aws iam create-instance-profile --instance-profile-name DynamoDBChatAppRole
    
    # Add role to instance profile
    aws iam add-role-to-instance-profile \
        --instance-profile-name DynamoDBChatAppRole \
        --role-name DynamoDBChatAppRole
    
    # Clean up temporary files
    rm trust-policy.json dynamodb-policy.json cloudwatch-policy.json
    
    print_status "✅ IAM roles and policies created successfully!"
    echo ""
    echo "📋 Created resources:"
    echo "  - IAM Role: DynamoDBChatAppRole"
    echo "  - Instance Profile: DynamoDBChatAppRole"
    echo "  - DynamoDB Policy: DynamoDBChatAppDynamoDBPolicy"
    echo ""
    echo "🚀 You can now deploy your application!"
}

# Run main function
main "$@"
