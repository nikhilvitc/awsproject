const AWS = require('aws-sdk');
require('dotenv').config();

// Configure AWS SDK
AWS.config.update({
  region: process.env.AWS_REGION || 'us-east-1',
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
});

// Create DynamoDB instance
const dynamodb = new AWS.DynamoDB.DocumentClient();

// Table names
const TABLES = {
  CHAT_ROOMS: 'ChatRooms',
  MESSAGES: 'Messages',
  MEETINGS: 'Meetings',
  CHAT_MESSAGES: 'ChatMessages',
  LIVE_CODE: 'LiveCode',
  PROJECTS: 'Projects',
  PROJECT_FILES: 'ProjectFiles'
};

// Helper function to generate unique IDs
const generateId = () => {
  return Date.now().toString() + Math.random().toString(36).substr(2, 9);
};

// Helper function to format timestamps
const formatTimestamp = (date = new Date()) => {
  return date.toISOString();
};

// Helper function to parse timestamps
const parseTimestamp = (timestamp) => {
  return new Date(timestamp);
};

module.exports = {
  dynamodb,
  TABLES,
  generateId,
  formatTimestamp,
  parseTimestamp
};
