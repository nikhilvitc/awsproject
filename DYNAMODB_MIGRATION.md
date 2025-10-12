# DynamoDB Migration Guide

This project has been migrated from MongoDB to Amazon DynamoDB for better scalability and AWS integration.

## Setup Instructions

### 1. AWS Configuration

Create a `.env` file in the backend directory with the following variables:

```env
# AWS Configuration for DynamoDB
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your_access_key_here
AWS_SECRET_ACCESS_KEY=your_secret_key_here

# Server Configuration
PORT=5000
NODE_ENV=development

# JDoodle API Configuration
JDOODLE_CLIENT_ID=your_jdoodle_client_id
JDOODLE_CLIENT_SECRET=your_jdoodle_client_secret
```

### 2. Create DynamoDB Tables

Run the table creation script:

```bash
cd backend
node scripts/createTables.js
```

This will create the following tables:
- `ChatRooms` - Stores chat room information
- `Messages` - Stores chat messages
- `Meetings` - Stores meeting information
- `Projects` - Stores project information

### 3. AWS IAM Permissions

Ensure your AWS user/role has the following DynamoDB permissions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:CreateTable",
                "dynamodb:DescribeTable",
                "dynamodb:Query",
                "dynamodb:Scan",
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:UpdateItem",
                "dynamodb:DeleteItem",
                "dynamodb:BatchGetItem",
                "dynamodb:BatchWriteItem"
            ],
            "Resource": "arn:aws:dynamodb:*:*:table/*"
        }
    ]
}
```

## Architecture Changes

### Database Models → Services

The MongoDB models have been replaced with DynamoDB service classes:

- `models/ChatRoom.js` → `services/ChatRoomService.js`
- `models/Message.js` → `services/MessageService.js`
- `models/Meeting.js` → `services/MeetingService.js`
- `models/Project.js` → `services/ProjectService.js`

### Key Changes

1. **Primary Keys**: MongoDB ObjectIds replaced with custom string IDs
2. **Relationships**: Foreign key references updated to use DynamoDB-compatible IDs
3. **Queries**: MongoDB queries replaced with DynamoDB operations
4. **Indexes**: Global Secondary Indexes created for efficient querying

### Table Structure

#### ChatRooms Table
- Primary Key: `roomId` (String)
- GSI: `NameIndex` on `name` field

#### Messages Table
- Primary Key: `messageId` (String)
- GSI: `RoomIdIndex` on `roomId` and `createdAt` fields

#### Meetings Table
- Primary Key: `meetingId` (String)
- GSI: `RoomIdIndex`, `OrganizerIndex`, `StatusIndex`, `StatusScheduledTimeIndex`, `ScheduledTimeIndex`

#### Projects Table
- Primary Key: `projectId` (String)
- GSI: `RoomIdIndex`, `CreatedByIndex`, `StatusIndex`

## Benefits of DynamoDB

1. **Serverless**: No database server management required
2. **Scalability**: Automatic scaling based on demand
3. **Performance**: Single-digit millisecond latency
4. **AWS Integration**: Native integration with other AWS services
5. **Cost-effective**: Pay only for what you use

## Migration Notes

- All existing functionality has been preserved
- Socket.IO real-time features work with DynamoDB
- API endpoints maintain the same interface
- Error handling improved with DynamoDB-specific error codes

## Testing

Test the migration by:

1. Starting the server: `npm start`
2. Creating a chat room
3. Sending messages
4. Scheduling meetings
5. Creating projects

All operations should work seamlessly with DynamoDB.
