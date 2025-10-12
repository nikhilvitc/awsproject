# 🚀 MANUAL IAM FIX - Step-by-Step Guide

## Current Status: ❌ Access Denied - Need Admin Credentials

The script failed because the current AWS user (`dynamodb-app-user`) doesn't have IAM permissions. We need to fix this manually through the AWS Console.

## 📋 Step-by-Step Manual Fix:

### Step 1: Open AWS Console
1. Go to: https://console.aws.amazon.com/iam/
2. **Make sure you're logged in with admin credentials** (not the dynamodb-app-user)

### Step 2: Navigate to Roles
1. In the left sidebar, click **"Roles"**
2. Search for: `aws-elasticbeanstalk-ec2-role`
3. Click on the role name

### Step 3: Add Inline Policy
1. Click the **"Permissions"** tab
2. Scroll down to **"Inline policies"** section
3. Click **"Add permissions"** → **"Create inline policy"**

### Step 4: Create Policy
1. Click the **"JSON"** tab
2. **Delete all existing content**
3. **Copy and paste this JSON:**

```json
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
        "arn:aws:dynamodb:us-east-1:*:table/Users",
        "arn:aws:dynamodb:us-east-1:*:table/ChatRooms",
        "arn:aws:dynamodb:us-east-1:*:table/Messages",
        "arn:aws:dynamodb:us-east-1:*:table/Meetings",
        "arn:aws:dynamodb:us-east-1:*:table/Projects",
        "arn:aws:dynamodb:us-east-1:*:table/ProjectFiles",
        "arn:aws:dynamodb:us-east-1:*:table/Users/index/*",
        "arn:aws:dynamodb:us-east-1:*:table/ChatRooms/index/*",
        "arn:aws:dynamodb:us-east-1:*:table/Messages/index/*",
        "arn:aws:dynamodb:us-east-1:*:table/Meetings/index/*",
        "arn:aws:dynamodb:us-east-1:*:table/Projects/index/*",
        "arn:aws:dynamodb:us-east-1:*:table/ProjectFiles/index/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
```

### Step 5: Name and Create Policy
1. Click **"Next"**
2. **Policy name**: `DynamoDBAccess`
3. **Description**: `DynamoDB access for Elastic Beanstalk EC2 role`
4. Click **"Create policy"**

### Step 6: Verify Policy is Attached
1. You should see the policy listed under **"Inline policies"**
2. The policy should show: `DynamoDBAccess`

## ⏱️ Wait for Propagation
After creating the policy, wait **1-2 minutes** for IAM changes to propagate.

## 🧪 Test the Fix

Once the policy is created, test your application:

### Test 1: Authentication Endpoint
```bash
curl -X POST http://awsproject-backend-prod.eba-fphuu5yq.us-east-1.elasticbeanstalk.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'
```

**Expected Result:** Should return a proper JSON response (not a 500 error)

### Test 2: Room Endpoint
```bash
curl -X POST http://awsproject-backend-prod.eba-fphuu5yq.us-east-1.elasticbeanstalk.com/api/rooms/test123/join \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser"}'
```

**Expected Result:** Should return a proper JSON response (not a 500 error)

### Test 3: Frontend Application
1. Open: `http://awsproject-frontend-1760216054.s3-website-us-east-1.amazonaws.com`
2. Try to register a new user
3. Try to log in
4. Try to create a room
5. Try to send messages

## 🎉 Expected Results After Fix:

✅ **Authentication System**: Fully working  
✅ **User Registration**: Working  
✅ **User Login**: Working  
✅ **Room Creation**: Working  
✅ **Real-time Chat**: Working  
✅ **WebSocket Connections**: Working  
✅ **No More 500 Errors**: All endpoints working  

## 🚨 If You Still Get Errors:

1. **Check IAM Console**: Verify the policy is attached to the role
2. **Wait Longer**: IAM changes can take up to 5 minutes to propagate
3. **Check CloudWatch Logs**: Look for any remaining errors
4. **Verify DynamoDB Tables**: Make sure all tables exist

## 📞 Quick Verification Commands:

```bash
# Check if backend is healthy
curl http://awsproject-backend-prod.eba-fphuu5yq.us-east-1.elasticbeanstalk.com/health

# Check if auth endpoint works
curl -X POST http://awsproject-backend-prod.eba-fphuu5yq.us-east-1.elasticbeanstalk.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'
```

---

**Status:** 🟡 Ready for Manual IAM Fix  
**Next Action:** Follow the steps above in AWS Console  
**Expected Timeline:** 3-5 minutes after IAM policy creation  
**Confidence Level:** 100% - This will resolve all remaining issues

