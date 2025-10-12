#!/bin/bash

# Fix IAM Permissions for Elastic Beanstalk EC2 Role
# This script attaches the necessary DynamoDB permissions to the EC2 role

set -e

echo "🔧 Fixing IAM Permissions for Elastic Beanstalk EC2 Role"
echo "======================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ROLE_NAME="aws-elasticbeanstalk-ec2-role"
POLICY_NAME="DynamoDBAccess"
POLICY_FILE="backend/iam-policy.json"

# Check if policy file exists
if [ ! -f "$POLICY_FILE" ]; then
    echo -e "${RED}❌ Error: Policy file $POLICY_FILE not found${NC}"
    exit 1
fi

echo "📋 Policy Details:"
echo "   Role Name: $ROLE_NAME"
echo "   Policy Name: $POLICY_NAME"
echo "   Policy File: $POLICY_FILE"
echo ""

# Check if role exists
echo "🔍 Checking if role exists..."
if aws iam get-role --role-name "$ROLE_NAME" > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Role $ROLE_NAME exists"
else
    echo -e "${RED}❌ Error: Role $ROLE_NAME does not exist${NC}"
    exit 1
fi

# Attach the policy
echo "📝 Attaching DynamoDB policy to EC2 role..."
aws iam put-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-name "$POLICY_NAME" \
    --policy-document "file://$POLICY_FILE"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Policy attached successfully"
else
    echo -e "${RED}❌ Error: Failed to attach policy${NC}"
    exit 1
fi

# Verify the policy was attached
echo "🔍 Verifying policy attachment..."
aws iam get-role-policy --role-name "$ROLE_NAME" --policy-name "$POLICY_NAME" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Policy verification successful"
else
    echo -e "${RED}❌ Error: Policy verification failed${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 IAM Permissions Fixed Successfully!${NC}"
echo ""
echo "📋 What was done:"
echo "   ✅ Attached DynamoDB permissions to aws-elasticbeanstalk-ec2-role"
echo "   ✅ Granted access to Users, ChatRooms, Messages, Meetings, Projects, ProjectFiles tables"
echo "   ✅ Included permissions for table indexes"
echo ""
echo "🔄 Next Steps:"
echo "   1. Wait 1-2 minutes for IAM changes to propagate"
echo "   2. Test your application - DynamoDB errors should be resolved"
echo "   3. Your backend should now be able to access DynamoDB tables"
echo ""
echo "🧪 Test Commands:"
echo "   curl -X POST http://awsproject-backend-prod.eba-fphuu5yq.us-east-1.elasticbeanstalk.com/api/rooms/test123/join \\"
echo "     -H \"Content-Type: application/json\" \\"
echo "     -d '{\"username\":\"testuser\"}'"
echo ""

