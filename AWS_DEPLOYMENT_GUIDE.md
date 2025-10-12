# AWS Deployment Guide

This guide will help you deploy your full-stack application to Amazon AWS.

## Prerequisites

1. **AWS CLI installed and configured**
   ```bash
   aws configure
   ```
   You'll need:
   - AWS Access Key ID
   - AWS Secret Access Key
   - Default region (us-east-1)
   - Default output format (json)

2. **Node.js and npm installed**
   - Node.js 18.x or higher
   - npm 8.x or higher

3. **AWS Account with appropriate permissions**
   - Elastic Beanstalk access
   - S3 access
   - DynamoDB access
   - IAM access
   - CloudFront access (optional)

## Quick Start

### 1. Setup AWS Resources
```bash
./setup-aws-resources.sh
```

This script will create:
- S3 buckets for deployment and hosting
- DynamoDB tables
- IAM roles and policies
- Elastic Beanstalk application

### 2. Deploy Complete Application
```bash
./deploy-to-aws.sh
```

This script will:
- Deploy backend to Elastic Beanstalk
- Deploy frontend to S3
- Configure all necessary settings
- Provide you with the URLs

## Manual Deployment

### Backend Only
```bash
./deploy-backend-aws.sh
```

### Frontend Only
```bash
./deploy-frontend-aws.sh
```

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   React App     │────│  Elastic        │────│   DynamoDB      │
│   (S3 + CF)     │    │  Beanstalk      │    │   Tables        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │
         │                       │
    ┌────▼────┐            ┌────▼────┐
    │ CloudFront│            │   EC2   │
    │   CDN    │            │ Instance│
    └─────────┘            └─────────┘
```

## Configuration

### Environment Variables

The deployment scripts automatically set these environment variables:

**Backend:**
- `NODE_ENV=production`
- `AWS_REGION=us-east-1`

**Frontend:**
- `REACT_APP_API_URL` - Backend URL
- `REACT_APP_SOCKET_URL` - Socket.IO URL
- `REACT_APP_ENV=production`

### Custom Configuration

You can modify the configuration in the deployment scripts:

```bash
# Backend configuration
AWS_REGION="us-east-1"
BACKEND_APPLICATION_NAME="awsproject-backend"
BACKEND_ENVIRONMENT_NAME="awsproject-backend-prod"

# Frontend configuration
FRONTEND_S3_BUCKET="awsproject-frontend-bucket"
CLOUDFRONT_DISTRIBUTION_ID="YOUR_DISTRIBUTION_ID"
```

## AWS Services Used

### 1. Elastic Beanstalk
- **Purpose**: Hosts the Node.js backend API
- **Features**: Auto-scaling, load balancing, health monitoring
- **URL**: `http://awsproject-backend-prod.eba-fphuu5yq.us-east-1.elasticbeanstalk.com`

### 2. S3 Static Website Hosting
- **Purpose**: Hosts the React frontend
- **Features**: Static website hosting, CDN integration
- **URL**: `http://awsproject-frontend-bucket.s3-website-us-east-1.amazonaws.com`

### 3. DynamoDB
- **Purpose**: NoSQL database for application data
- **Tables**: ChatRooms, Messages, Meetings, Projects, ProjectFiles

### 4. CloudFront (Optional)
- **Purpose**: CDN for faster content delivery
- **Features**: Global edge locations, HTTPS, custom domains

## Monitoring and Logs

### Elastic Beanstalk Logs
```bash
# View recent logs
aws elasticbeanstalk describe-events \
    --environment-name awsproject-backend-prod

# Download logs
aws elasticbeanstalk request-environment-info \
    --environment-name awsproject-backend-prod \
    --info-type tail
```

### S3 Access Logs
- Enable S3 access logging for monitoring
- CloudFront provides detailed access logs

## Troubleshooting

### Common Issues

1. **Deployment fails with permission errors**
   ```bash
   # Check IAM permissions
   aws sts get-caller-identity
   ```

2. **Backend health check fails**
   ```bash
   # Check Elastic Beanstalk logs
   aws elasticbeanstalk describe-events \
       --environment-name awsproject-backend-prod
   ```

3. **Frontend can't connect to backend**
   - Check CORS configuration in backend
   - Verify backend URL in frontend config

4. **DynamoDB access denied**
   ```bash
   # Check IAM role permissions
   aws iam get-role-policy \
       --role-name awsproject-elasticbeanstalk-role \
       --policy-name DynamoDBAccess
   ```

### Health Checks

**Backend Health Check:**
```bash
curl http://awsproject-backend-prod.eba-fphuu5yq.us-east-1.elasticbeanstalk.com/health
```

**Frontend Health Check:**
```bash
curl http://awsproject-frontend-bucket.s3-website-us-east-1.amazonaws.com
```

## Security Considerations

1. **IAM Roles**: Use least privilege principle
2. **S3 Bucket Policies**: Restrict public access appropriately
3. **CORS Configuration**: Limit allowed origins
4. **Environment Variables**: Never commit secrets to version control

## Cost Optimization

1. **Elastic Beanstalk**: Use appropriate instance types
2. **S3**: Use appropriate storage classes
3. **DynamoDB**: Use on-demand billing for variable workloads
4. **CloudFront**: Monitor usage and optimize cache settings

## Scaling

### Auto Scaling
- Elastic Beanstalk automatically scales based on CPU/memory usage
- Configure scaling triggers in the Elastic Beanstalk console

### Database Scaling
- DynamoDB auto-scales based on demand
- Use DynamoDB Accelerator (DAX) for read-heavy workloads

## Backup and Recovery

### Database Backups
```bash
# Enable point-in-time recovery
aws dynamodb update-continuous-backups \
    --table-name ChatRooms \
    --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true
```

### Application Backups
- Elastic Beanstalk maintains application versions
- S3 provides versioning and cross-region replication

## Support

For issues with:
- **AWS Services**: Check AWS documentation and support
- **Application Code**: Review application logs and error messages
- **Deployment Scripts**: Check script output and AWS CLI responses

## Next Steps

1. **Custom Domain**: Set up Route 53 and SSL certificates
2. **CI/CD Pipeline**: Integrate with GitHub Actions or AWS CodePipeline
3. **Monitoring**: Set up CloudWatch alarms and dashboards
4. **Security**: Implement WAF and security scanning
5. **Performance**: Optimize with caching and CDN
