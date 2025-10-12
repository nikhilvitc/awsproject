const { dynamodb, TABLES, generateId, formatTimestamp, parseTimestamp } = require('../config/dynamodb');

class MessageService {
  // Create a new message
  async createMessage(messageData) {
    const messageId = generateId();
    const timestamp = formatTimestamp();
    
    const message = {
      messageId,
      roomId: messageData.roomId,
      user: messageData.user,
      text: messageData.text || null,
      code: messageData.code || null,
      language: messageData.language || null,
      output: messageData.output || null,
      isCode: messageData.isCode || false,
      createdAt: timestamp
    };

    const params = {
      TableName: TABLES.MESSAGES,
      Item: message
    };

    await dynamodb.put(params).promise();
    return message;
  }

  // Get messages by room ID
  async getMessagesByRoom(roomId, limit = 50, lastEvaluatedKey = null) {
    const params = {
      TableName: TABLES.MESSAGES,
      IndexName: 'RoomIdIndex',
      KeyConditionExpression: 'roomId = :roomId',
      ExpressionAttributeValues: {
        ':roomId': roomId
      },
      ScanIndexForward: false, // Sort by createdAt descending
      Limit: limit
    };

    if (lastEvaluatedKey) {
      params.ExclusiveStartKey = lastEvaluatedKey;
    }

    const result = await dynamodb.query(params).promise();
    return {
      messages: result.Items || [],
      lastEvaluatedKey: result.LastEvaluatedKey
    };
  }

  // Get message by ID
  async getMessageById(messageId) {
    const params = {
      TableName: TABLES.MESSAGES,
      Key: { messageId }
    };

    const result = await dynamodb.get(params).promise();
    return result.Item || null;
  }

  // Update message
  async updateMessage(messageId, updateData) {
    // Build update expression dynamically
    const updateExpressions = [];
    const expressionAttributeNames = {};
    const expressionAttributeValues = {};

    Object.keys(updateData).forEach(key => {
      if (key !== 'messageId') {
        updateExpressions.push(`#${key} = :${key}`);
        expressionAttributeNames[`#${key}`] = key;
        expressionAttributeValues[`:${key}`] = updateData[key];
      }
    });

    const params = {
      TableName: TABLES.MESSAGES,
      Key: { messageId },
      UpdateExpression: `SET ${updateExpressions.join(', ')}`,
      ExpressionAttributeNames: expressionAttributeNames,
      ExpressionAttributeValues: expressionAttributeValues,
      ReturnValues: 'ALL_NEW'
    };

    const result = await dynamodb.update(params).promise();
    return result.Attributes;
  }

  // Delete message
  async deleteMessage(messageId) {
    const params = {
      TableName: TABLES.MESSAGES,
      Key: { messageId }
    };

    await dynamodb.delete(params).promise();
    return true;
  }

  // Get recent messages for a room
  async getRecentMessages(roomId, limit = 20) {
    const result = await this.getMessagesByRoom(roomId, limit);
    return result.messages;
  }

  // Search messages by text content
  async searchMessages(roomId, searchText, limit = 20) {
    const params = {
      TableName: TABLES.MESSAGES,
      IndexName: 'RoomIdIndex',
      KeyConditionExpression: 'roomId = :roomId',
      FilterExpression: 'contains(text, :searchText) OR contains(code, :searchText)',
      ExpressionAttributeValues: {
        ':roomId': roomId,
        ':searchText': searchText
      },
      ScanIndexForward: false,
      Limit: limit
    };

    const result = await dynamodb.query(params).promise();
    return result.Items || [];
  }

  // Get message count for a room
  async getMessageCount(roomId) {
    const params = {
      TableName: TABLES.MESSAGES,
      IndexName: 'RoomIdIndex',
      KeyConditionExpression: 'roomId = :roomId',
      ExpressionAttributeValues: {
        ':roomId': roomId
      },
      Select: 'COUNT'
    };

    const result = await dynamodb.query(params).promise();
    return result.Count;
  }
}

module.exports = MessageService;
