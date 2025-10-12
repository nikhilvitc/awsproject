# AWS IAM Role Setup for Production Deployment

## 🎯 Create IAM Role for Your Application

### Step 1: Go to IAM Roles (Not Users)
1. In AWS Console, go to **IAM** → **Roles** (not Users)
2. Click **"Create role"**

### Step 2: Select Trusted Entity Type
- Choose **"AWS service"**
- Select **"Elastic Beanstalk"** (if using EB)
- OR **"Lambda"** (if using serverless)
- OR **"ECS Task"** (if using containers)

### Step 3: Attach Permissions Policy
1. Click **"Create policy"**
2. Go to **JSON** tab
3. Copy the policy from `backend/iam-policy.json`
4. Name it: `DynamoDBChatAppPolicy`
5. Create and attach the policy

### Step 4: Name Your Role
- Role name: `DynamoDBChatAppRole`
- Description: `IAM role for DynamoDB Chat Application`

## 🚀 Deployment Options

### Option 1: AWS Elastic Beanstalk (Recommended)
```bash
cd backend
eb init
eb create production --instance-type t3.micro
eb deploy
```

### Option 2: AWS Lambda (Serverless)
```bash
cd backend
npm install serverless-http
serverless deploy
```

### Option 3: AWS App Runner (Easiest)
1. Go to AWS App Runner console
2. Create service from source code
3. Connect to your GitHub repository
4. Use the IAM role created above

## 🔧 Update Your Application Code

Your application is already configured to use IAM roles! The `config/dynamodb.js` file will automatically use the IAM role when deployed on AWS.

## ✅ Benefits of IAM Roles vs Access Keys

- **More Secure**: No long-term credentials to manage
- **Automatic Rotation**: AWS handles credential rotation
- **Principle of Least Privilege**: Only necessary permissions
- **Audit Trail**: Better logging and monitoring
- **No Manual Management**: No need to store/rotate keys

## 🎯 Next Steps

1. **Cancel** the current access key creation
2. **Create IAM Role** using the steps above
3. **Deploy** using one of the options above
4. **Test** your deployed application

Your application will automatically use the IAM role when deployed on AWS! 🚀
