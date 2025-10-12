# AWS DynamoDB Setup Guide

This guide will walk you through setting up DynamoDB from the AWS website and configuring your application.

## Step 1: AWS Account Setup

### 1.1 Create AWS Account
1. Go to [https://aws.amazon.com](https://aws.amazon.com)
2. Click "Create an AWS Account"
3. Follow the registration process
4. Verify your email and phone number

### 1.2 Access AWS Console
1. Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Sign in with your credentials

## Step 2: Create DynamoDB Tables

### 2.1 Navigate to DynamoDB
1. In the AWS Console, search for "DynamoDB"
2. Click on "DynamoDB" service
3. Click "Create table"

### 2.2 Create ChatRooms Table
1. **Table name**: `ChatRooms`
2. **Partition key**: `roomId` (String)
3. **Sort key**: Leave empty
4. **Settings**: Use default settings
5. Click "Create table"

**Add Global Secondary Index:**
1. Go to the "Indexes" tab
2. Click "Create index"
3. **Index name**: `NameIndex`
4. **Partition key**: `name` (String)
5. Click "Create index"

### 2.3 Create Messages Table
1. **Table name**: `Messages`
2. **Partition key**: `messageId` (String)
3. **Sort key**: Leave empty
4. Click "Create table"

**Add Global Secondary Index:**
1. Go to the "Indexes" tab
2. Click "Create index"
3. **Index name**: `RoomIdIndex`
4. **Partition key**: `roomId` (String)
5. **Sort key**: `createdAt` (String)
6. Click "Create index"

### 2.4 Create Meetings Table
1. **Table name**: `Meetings`
2. **Partition key**: `meetingId` (String)
3. **Sort key**: Leave empty
4. Click "Create table"

**Add Global Secondary Indexes:**
1. **RoomIdIndex**: Partition key `roomId` (String), Sort key `scheduledTime` (String)
2. **OrganizerIndex**: Partition key `organizer` (String), Sort key `scheduledTime` (String)
3. **StatusIndex**: Partition key `status` (String)
4. **StatusScheduledTimeIndex**: Partition key `status` (String), Sort key `scheduledTime` (String)
5. **ScheduledTimeIndex**: Partition key `scheduledTime` (String)

### 2.5 Create Projects Table
1. **Table name**: `Projects`
2. **Partition key**: `projectId` (String)
3. **Sort key**: Leave empty
4. Click "Create table"

**Add Global Secondary Indexes:**
1. **RoomIdIndex**: Partition key `roomId` (String), Sort key `createdAt` (String)
2. **CreatedByIndex**: Partition key `createdBy` (String), Sort key `createdAt` (String)
3. **StatusIndex**: Partition key `status` (String), Sort key `createdAt` (String)

## Step 3: Create IAM User for Application

### 3.1 Navigate to IAM
1. In AWS Console, search for "IAM"
2. Click on "IAM" service

### 3.2 Create New User
1. Click "Users" in the left sidebar
2. Click "Create user"
3. **User name**: `dynamodb-app-user`
4. **Access type**: Select "Programmatic access"
5. Click "Next: Permissions"

### 3.3 Attach Policies
1. Click "Attach existing policies directly"
2. Search for "DynamoDB"
3. Select "AmazonDynamoDBFullAccess" (for development)
   - **Note**: For production, create a custom policy with minimal permissions
4. Click "Next: Tags"
5. Click "Next: Review"
6. Click "Create user"

### 3.4 Save Credentials
1. **IMPORTANT**: Copy the Access Key ID and Secret Access Key
2. Download the CSV file or save these credentials securely
3. You'll need these for your `.env` file

## Step 4: Configure Your Application

### 4.1 Create Environment File
Create a `.env` file in your `backend` directory:

```env
# AWS Configuration
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your_access_key_id_here
AWS_SECRET_ACCESS_KEY=your_secret_access_key_here

# Server Configuration
PORT=5000
NODE_ENV=development

# JDoodle API Configuration (if you have these)
JDOODLE_CLIENT_ID=your_jdoodle_client_id
JDOODLE_CLIENT_SECRET=your_jdoodle_client_secret
```

### 4.2 Replace Placeholder Values
- Replace `your_access_key_id_here` with your actual Access Key ID
- Replace `your_secret_access_key_here` with your actual Secret Access Key
- Update `AWS_REGION` if you're using a different region

## Step 5: Test Your Setup

### 5.1 Install Dependencies
```bash
cd backend
npm install
```

### 5.2 Test DynamoDB Connection
```bash
npm test
```

This will run the integration test to verify everything is working.

### 5.3 Start Your Application
```bash
npm start
```

## Step 6: Production Considerations

### 6.1 Security Best Practices
1. **Never commit `.env` files** to version control
2. **Use IAM roles** instead of access keys when deploying to AWS services
3. **Create custom IAM policies** with minimal required permissions
4. **Enable CloudTrail** for audit logging

### 6.2 Custom IAM Policy (Recommended)
Instead of `AmazonDynamoDBFullAccess`, create a custom policy:

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
                "dynamodb:DeleteItem"
            ],
            "Resource": [
                "arn:aws:dynamodb:us-east-1:YOUR_ACCOUNT_ID:table/ChatRooms",
                "arn:aws:dynamodb:us-east-1:YOUR_ACCOUNT_ID:table/Messages",
                "arn:aws:dynamodb:us-east-1:YOUR_ACCOUNT_ID:table/Meetings",
                "arn:aws:dynamodb:us-east-1:YOUR_ACCOUNT_ID:table/Projects",
                "arn:aws:dynamodb:us-east-1:YOUR_ACCOUNT_ID:table/ChatRooms/index/*",
                "arn:aws:dynamodb:us-east-1:YOUR_ACCOUNT_ID:table/Messages/index/*",
                "arn:aws:dynamodb:us-east-1:YOUR_ACCOUNT_ID:table/Meetings/index/*",
                "arn:aws:dynamodb:us-east-1:YOUR_ACCOUNT_ID:table/Projects/index/*"
            ]
        }
    ]
}
```

## Troubleshooting

### Common Issues:

1. **Access Denied**: Check your AWS credentials and IAM permissions
2. **Table Not Found**: Ensure tables are created in the correct region
3. **Connection Timeout**: Verify your AWS region matches your configuration
4. **Invalid Credentials**: Double-check your Access Key ID and Secret Access Key

### Getting Help:
- AWS DynamoDB Documentation: https://docs.aws.amazon.com/dynamodb/
- AWS IAM Documentation: https://docs.aws.amazon.com/iam/
- AWS Support: Available through AWS Console

## Cost Optimization

### DynamoDB Pricing:
- **On-Demand**: Pay per request (good for variable workloads)
- **Provisioned**: Pay for allocated capacity (good for predictable workloads)

### Tips:
1. Start with On-Demand pricing for development
2. Monitor usage with AWS CloudWatch
3. Switch to Provisioned capacity for production if usage is predictable
4. Use DynamoDB Accelerator (DAX) for high-performance applications

Your DynamoDB setup is now complete! 🎉
