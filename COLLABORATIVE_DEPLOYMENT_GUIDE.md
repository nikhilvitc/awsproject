# 🚀 AWS Deployment Guide for Collaborative Editing Features

This guide will help you deploy the new collaborative editing features to AWS.

## 📋 Prerequisites

Before starting, ensure you have:

- ✅ AWS CLI installed and configured
- ✅ EB CLI installed (`pip install awsebcli`)
- ✅ Node.js and npm installed
- ✅ AWS credentials configured
- ✅ Existing AWS infrastructure (Elastic Beanstalk, S3, etc.)

## 🎯 Deployment Options

### Option 1: Full Deployment (Recommended)
Deploy both backend and frontend with all collaborative features:

```bash
./deploy-collaborative-features.sh
```

### Option 2: Backend Only Update
Update only the backend with new WebSocket events:

```bash
./update-backend-collaborative.sh
```

### Option 3: Frontend Only Update
Update only the frontend with collaborative UI:

```bash
./update-frontend-collaborative.sh
```

## 🔧 Manual Deployment Steps

### Backend Deployment

1. **Navigate to backend directory:**
   ```bash
   cd backend
   ```

2. **Install dependencies:**
   ```bash
   npm install --production
   ```

3. **Deploy to Elastic Beanstalk:**
   ```bash
   eb deploy awsproject-backend-prod
   ```

4. **Set environment variables:**
   ```bash
   eb setenv NODE_ENV=production ENABLE_COLLABORATIVE_EDITING=true
   ```

### Frontend Deployment

1. **Navigate to frontend directory:**
   ```bash
   cd jellylemonshake
   ```

2. **Update API URL:**
   ```bash
   # Replace with your actual backend URL
   sed -i.bak 's|http://localhost:5000|https://your-backend-url.elasticbeanstalk.com|g' src/config.js
   ```

3. **Install dependencies and build:**
   ```bash
   npm install
   npm run build
   ```

4. **Deploy to S3:**
   ```bash
   aws s3 sync build/ s3://your-frontend-bucket --delete
   ```

## 🧪 Testing Collaborative Features

### 1. Basic Connectivity Test
- Open your frontend URL
- Check browser console for WebSocket connection logs
- Verify "Live Collaboration Active" status

### 2. Multi-User Test
- Open frontend in multiple browser tabs/windows
- Log in with different users
- Open Collaborative Editor
- Select a project and file
- Start editing - you should see:
  - Live content updates
  - User cursors
  - Typing indicators
  - User presence avatars

### 3. Feature Test Checklist
- ✅ Real-time content synchronization
- ✅ Cursor position tracking
- ✅ User presence indicators
- ✅ Typing indicators
- ✅ Auto-save functionality
- ✅ Conflict detection warnings

## 🔍 Troubleshooting

### WebSocket Connection Issues
```bash
# Check backend logs
eb logs

# Test Socket.IO endpoint
curl https://your-backend-url/socket.io/
```

### Frontend Not Loading
```bash
# Check S3 bucket permissions
aws s3api get-bucket-policy --bucket your-bucket-name

# Test S3 website
curl http://your-bucket.s3-website-us-east-1.amazonaws.com
```

### CORS Issues
- Ensure backend CORS includes your frontend domain
- Check browser console for CORS errors
- Update CORS configuration in backend if needed

## 📊 Monitoring

### Backend Monitoring
```bash
# Check environment health
eb health

# View logs
eb logs

# Check status
eb status
```

### Frontend Monitoring
```bash
# Check S3 bucket contents
aws s3 ls s3://your-bucket-name

# Check CloudFront distribution
aws cloudfront get-distribution --id your-distribution-id
```

## 🚨 Common Issues & Solutions

### Issue: WebSocket not connecting
**Solution:** Check firewall settings and ensure port 443 is open for HTTPS

### Issue: Cursors not appearing
**Solution:** Verify Socket.IO events are being sent/received in browser console

### Issue: Content not syncing
**Solution:** Check debounce settings and network connectivity

### Issue: Users not showing presence
**Solution:** Verify user authentication and room joining logic

## 📈 Performance Optimization

### Backend
- Monitor CPU and memory usage
- Scale instances if needed: `eb scale 2`
- Enable CloudWatch monitoring

### Frontend
- Use CloudFront for CDN
- Enable gzip compression
- Optimize bundle size

## 🔐 Security Considerations

- Ensure HTTPS is enabled
- Validate WebSocket connections
- Implement rate limiting for collaborative events
- Monitor for suspicious activity

## 📝 Post-Deployment Checklist

- [ ] Backend deployed and accessible
- [ ] Frontend deployed and accessible
- [ ] WebSocket connections working
- [ ] Collaborative features tested
- [ ] Performance monitoring enabled
- [ ] Security measures in place
- [ ] Documentation updated

## 🆘 Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review AWS CloudWatch logs
3. Test with browser developer tools
4. Verify all prerequisites are met

## 🎉 Success!

Once deployed successfully, you'll have:

- ✅ Live collaborative code editing
- ✅ Real-time cursor tracking
- ✅ User presence indicators
- ✅ Typing indicators
- ✅ Auto-save functionality
- ✅ Conflict detection
- ✅ Google Sheets-like experience

Your users can now collaborate on code in real-time, just like Google Sheets!
