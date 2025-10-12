# Environment Configuration Guide

This guide explains all the environment variables needed for the AWS Collaboration Platform.

## Frontend Environment Variables

### Required Configuration

Create a `.env` file in the `jellylemonshake/` directory with the following variables:

```bash
# Backend API URL - Your deployed backend endpoint
REACT_APP_API_URL=http://awsproject-backend-prod.eba-fphuu5yq.us-east-1.elasticbeanstalk.com

# Socket.IO URL (usually same as API URL)
REACT_APP_SOCKET_URL=http://awsproject-backend-prod.eba-fphuu5yq.us-east-1.elasticbeanstalk.com
```

### Optional Configuration

```bash
# Application Settings
REACT_APP_NAME="AWS Collaboration Platform"
REACT_APP_ENV=production
REACT_APP_DEBUG=false
REACT_APP_MAX_FILE_SIZE=5

# Feature Flags
REACT_APP_ENABLE_AUTH=true
REACT_APP_ENABLE_VIDEO_CALLS=true
REACT_APP_ENABLE_CODE_EXECUTION=true
REACT_APP_ENABLE_PROJECTS=true

# AWS-specific (if needed)
REACT_APP_AWS_REGION=us-east-1
```

## Backend Environment Variables

Create a `.env` file in the `backend/` directory with the following variables:

```bash
# Server Configuration
PORT=5000
NODE_ENV=production

# AWS DynamoDB Configuration
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-access-key-id
AWS_SECRET_ACCESS_KEY=your-secret-access-key

# DynamoDB Table Names
DYNAMODB_USERS_TABLE=Users
DYNAMODB_CHATROOMS_TABLE=ChatRooms
DYNAMODB_MESSAGES_TABLE=Messages
DYNAMODB_MEETINGS_TABLE=Meetings
DYNAMODB_PROJECTS_TABLE=Projects
DYNAMODB_PROJECT_FILES_TABLE=ProjectFiles

# JDoodle API (for code execution)
JDOODLE_CLIENT_ID=your-jdoodle-client-id
JDOODLE_CLIENT_SECRET=your-jdoodle-client-secret

# Session/JWT Configuration (if implementing proper auth)
JWT_SECRET=your-jwt-secret-key-change-this-in-production
SESSION_SECRET=your-session-secret-key-change-this

# CORS Configuration (already configured in code)
# Frontend URLs are configured in index.js
```

## Deployment Platform Configuration

### AWS Elastic Beanstalk (Backend)

Configure environment variables in the EB console:
1. Go to Configuration > Software
2. Add environment properties for all backend variables

### AWS S3 + CloudFront (Frontend)

Since S3 hosting doesn't support runtime environment variables:
1. Create a `.env.production` file before building
2. Run `npm run build` with the correct variables
3. Upload the build to S3

### AWS Amplify (Frontend - Alternative)

Configure in Amplify console:
1. Go to App settings > Environment variables
2. Add all REACT_APP_* variables
3. Amplify will use them during build

### Netlify (Frontend - Alternative)

Configure in Netlify:
1. Site settings > Build & deploy > Environment
2. Add all REACT_APP_* variables

### Vercel (Frontend - Alternative)

Configure in Vercel:
1. Project settings > Environment Variables
2. Add all REACT_APP_* variables
3. Set environment (Production, Preview, Development)

## Important Notes

1. **Never commit `.env` files** with real credentials to version control
2. Use `.env.example` or `.env.template` for documentation
3. All `REACT_APP_*` variables are embedded at **build time** in React
4. Restart development server after changing `.env` files
5. For production, always use HTTPS URLs
6. Update CORS configuration in backend when adding new frontend domains

## Current Deployment URLs

### Backend
- **Elastic Beanstalk**: `http://awsproject-backend-prod.eba-fphuu5yq.us-east-1.elasticbeanstalk.com`
- **API Base**: `/api`
- **Socket.IO**: Same as backend URL

### Frontend
- **To be deployed**: Configure the URL in backend CORS after deployment
- Supported platforms: S3, CloudFront, Amplify, Netlify, Vercel

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/profile` - Get current user profile
- `PUT /api/auth/profile` - Update user profile
- `PUT /api/auth/change-password` - Change password

### Chat Rooms
- `POST /api/rooms` - Create room
- `GET /api/rooms` - Get all rooms
- `GET /api/rooms/:roomName` - Get room by name
- `POST /api/rooms/:roomId/join` - Join room
- `GET /api/rooms/:roomId/messages` - Get messages
- `POST /api/rooms/:roomId/messages` - Send message
- `DELETE /api/rooms/:roomId/messages/:messageId` - Delete message

### Meetings
- `POST /api/meetings/create` - Create meeting
- `GET /api/meetings/room/:roomId` - Get meetings by room
- `GET /api/meetings/:meetingId` - Get meeting by ID
- `PATCH /api/meetings/:meetingId/status` - Update meeting status
- `DELETE /api/meetings/:meetingId` - Delete meeting
- `POST /api/meetings/:meetingId/notify` - Send meeting notification

### Projects
- `POST /api/projects/create` - Create project
- `GET /api/projects/room/:roomId` - Get projects by room
- `GET /api/projects/:projectId` - Get project details
- `POST /api/projects/:projectId/files/paste` - Paste code
- `POST /api/projects/:projectId/files/upload` - Upload file
- `PUT /api/projects/:projectId/files/:fileId` - Update file
- `POST /api/projects/:projectId/compile` - Compile project
- `GET /api/projects/:projectId/preview` - Preview compiled project

### Code Execution
- `POST /api/jdoodle/execute` - Execute code

### Admin Functions
- `GET /api/rooms/:roomId/members` - Get room members
- `DELETE /api/rooms/:roomId/members/:username` - Remove member
- `POST /api/rooms/:roomId/admins` - Promote to admin
- `DELETE /api/rooms/:roomId/admins/:username` - Demote admin
- `POST /api/rooms/:roomId/invite-admin` - Invite admin
- `PATCH /api/rooms/:roomId/settings` - Update room settings
- `PATCH /api/rooms/:roomId/name` - Update room name
- `PATCH /api/rooms/:roomId/color` - Update room color
- `GET /api/rooms/:roomId/permissions/:username` - Get permissions

### Health Check
- `GET /api/health` - Backend health check
- `GET /health` - Simple health check
- `GET /test` - Test endpoint

## Socket.IO Events

### Client -> Server
- `join-room` - Join a chat room
- `leave-room` - Leave a chat room
- `send-message` - Send a message
- `typing` - Typing indicator
- `user-joined-video` - User joined video call
- `user-left-video` - User left video call
- `webrtc-offer` - WebRTC offer
- `webrtc-answer` - WebRTC answer
- `webrtc-ice-candidate` - ICE candidate
- `video-call-started` - Video call started
- `video-call-active` - Video call active status

### Server -> Client
- `new-message` - New message received
- `user-joined` - User joined room
- `user-left` - User left room
- `user-typing` - User is typing
- `room-users` - List of users in room
- `users-count` - Number of users in room
- `message-deleted` - Message was deleted
- `error` - Error occurred
- (All video call events are also sent from server to client)

## Testing

### Health Check
```bash
# Backend health check
curl http://awsproject-backend-prod.eba-fphuu5yq.us-east-1.elasticbeanstalk.com/api/health

# Expected response:
{
  "success": true,
  "message": "Backend is running",
  "timestamp": "2025-10-11T...",
  "cors": {
    "origin": "...",
    "allowed": true
  }
}
```

### Test API Endpoint
```bash
curl http://awsproject-backend-prod.eba-fphuu5yq.us-east-1.elasticbeanstalk.com/test

# Expected response:
{
  "message": "Test endpoint working",
  "timestamp": "2025-10-11T..."
}
```

## Troubleshooting

### CORS Issues
1. Check if your frontend URL is in the backend CORS configuration
2. Verify the frontend is using the correct backend URL
3. Check browser console for specific CORS errors

### Socket.IO Connection Issues
1. Verify backend URL is correct in socketService.js
2. Check if Socket.IO is enabled on the backend
3. Check browser console for connection errors
4. Try polling transport first (already configured)

### API Call Failures
1. Verify backend is running (health check)
2. Check API URL is correct in api.js
3. Check network tab in browser for failed requests
4. Verify authentication tokens if required

### Database Connection Issues
1. Verify AWS credentials are configured
2. Check DynamoDB tables exist
3. Verify IAM permissions for DynamoDB access
4. Check backend logs for connection errors

