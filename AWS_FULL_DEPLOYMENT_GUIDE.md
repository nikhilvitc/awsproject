# AWS Full Stack Deployment Guide

## 🎯 Complete AWS Deployment for Your Chat Application

This guide will help you deploy both frontend and backend to AWS services.

## 📋 Architecture Overview

```
Frontend (React) → S3 + CloudFront → Global CDN
Backend (Node.js) → Elastic Beanstalk → Auto-scaling EC2
Database → DynamoDB → Serverless
```

## 🚀 Quick Deployment Commands

### Deploy Backend to AWS Elastic Beanstalk
```bash
./deploy-backend-aws.sh
```

### Deploy Frontend to S3
```bash
./deploy-frontend-cors-fix.sh
```

## 🔧 Prerequisites

### 1. Install Required Tools
```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install EB CLI
pip install awsebcli

# Configure AWS credentials
aws configure
```

### 2. AWS Account Setup
- AWS Account with appropriate permissions
- DynamoDB tables created (ChatRooms, Messages, Meetings, Projects, ProjectFiles)
- IAM user with deployment permissions

## 🏗️ Backend Deployment (Elastic Beanstalk)

### Step 1: Create IAM Role
The deployment script will automatically create:
- `DynamoDBChatAppRole` - Instance profile role
- `DynamoDBChatAppPolicy` - DynamoDB permissions

### Step 2: Deploy Backend
```bash
cd backend
eb init awsproject-backend --region us-east-1 --platform "Node.js 18"
eb create awsproject-backend-prod --instance-type t3.micro --single
eb deploy
```

### Step 3: Get Backend URL
```bash
eb status
# Note the CNAME URL (e.g., awsproject-backend-prod.elasticbeanstalk.com)
```

## 🌐 Frontend Deployment (S3 + CloudFront)

### Step 1: Build Frontend
```bash
cd jellylemonshake
export REACT_APP_API_URL="https://your-backend-url.elasticbeanstalk.com"
npm run build
```

### Step 2: Deploy to S3
```bash
aws s3 mb s3://awsproject-frontend-$(date +%s)
aws s3 sync build/ s3://your-bucket-name --delete
aws s3 website s3://your-bucket-name --index-document index.html
```

### Step 3: Configure CloudFront (Optional)
```bash
# Create CloudFront distribution pointing to S3 bucket
aws cloudfront create-distribution --distribution-config file://cloudfront-config.json
```

## 🔐 Security Configuration

### IAM Permissions
Your backend will automatically use the IAM role with these permissions:
- DynamoDB: Query, Scan, GetItem, PutItem, UpdateItem, DeleteItem
- CloudWatch Logs: CreateLogGroup, CreateLogStream, PutLogEvents

### CORS Configuration
The backend is configured to accept requests from:
- S3 website hosting domains
- Elastic Beanstalk domains
- Localhost (for development)

## 📊 Monitoring and Logs

### View Application Logs
```bash
cd backend
eb logs
```

### Check Health Status
```bash
eb health
```

### Monitor DynamoDB
- Go to AWS Console → DynamoDB
- Check table metrics and performance

## 🔄 Scaling and Updates

### Scale Your Application
```bash
eb scale 2  # Scale to 2 instances
eb scale 1  # Scale back to 1 instance
```

### Deploy Updates
```bash
# Make changes to your code
eb deploy  # Deploy changes
```

### Environment Management
```bash
eb list          # List environments
eb status        # Check status
eb terminate     # Terminate environment
```

## 💰 Cost Optimization

### DynamoDB
- Use On-Demand billing for variable workloads
- Switch to Provisioned for predictable workloads
- Enable point-in-time recovery

### Elastic Beanstalk
- Use t3.micro for development
- Scale up to t3.small for production
- Configure auto-scaling based on CPU/memory

### S3 + CloudFront
- S3 storage is very cheap
- CloudFront reduces bandwidth costs
- Use S3 lifecycle policies for old files

## 🧪 Testing Your Deployment

### Test Backend
```bash
curl https://your-backend-url.elasticbeanstalk.com/api/health
```

### Test Frontend
1. Open your S3 website URL
2. Check browser console for errors
3. Test room creation and messaging
4. Verify real-time chat works

### Test Full Stack
1. Create a room from frontend
2. Send messages
3. Check DynamoDB for data
4. Verify Socket.IO connections

## 🚨 Troubleshooting

### Common Issues

#### 1. CORS Errors
- Check CORS configuration in backend
- Verify frontend URL is in allowed origins
- Test with browser developer tools

#### 2. DynamoDB Access Denied
- Verify IAM role permissions
- Check DynamoDB table names
- Ensure tables exist in correct region

#### 3. Deployment Failures
- Check EB logs: `eb logs`
- Verify Node.js version compatibility
- Check environment variables

#### 4. Socket.IO Connection Issues
- Check CORS configuration
- Verify WebSocket support
- Test with different transports

### Debug Commands
```bash
# Check EB environment status
eb status

# View detailed logs
eb logs --all

# Check DynamoDB connection
aws dynamodb list-tables

# Test API endpoints
curl -X GET https://your-backend-url/api/rooms
```

## 📈 Production Considerations

### 1. Custom Domain
- Purchase domain name
- Configure Route 53
- Set up SSL certificates
- Update CORS configuration

### 2. Database Optimization
- Add Global Secondary Indexes
- Implement caching with DAX
- Set up cross-region replication

### 3. Monitoring
- Set up CloudWatch alarms
- Configure X-Ray tracing
- Monitor application metrics

### 4. Backup Strategy
- Enable DynamoDB point-in-time recovery
- Set up automated backups
- Configure cross-region replication

## 🎉 Success Checklist

- [ ] Backend deployed to Elastic Beanstalk
- [ ] Frontend deployed to S3
- [ ] DynamoDB tables created and accessible
- [ ] CORS configuration working
- [ ] Socket.IO real-time chat working
- [ ] Room creation and messaging functional
- [ ] Health checks passing
- [ ] Logs accessible
- [ ] Monitoring configured

Your AWS deployment is now complete! 🚀
