const { v4: uuidv4 } = require('uuid');

class User {
  constructor(data) {
    this.userId = data.userId || uuidv4();
    this.email = data.email;
    this.username = data.username;
    this.password = data.password; // In production, this should be hashed
    this.createdAt = data.createdAt || new Date().toISOString();
    this.updatedAt = data.updatedAt || new Date().toISOString();
    this.isActive = data.isActive !== undefined ? data.isActive : true;
    this.lastLogin = data.lastLogin;
    this.profile = data.profile || {
      firstName: '',
      lastName: '',
      avatar: '',
      bio: ''
    };
  }

  // Save user to DynamoDB
  async save() {
    const { dynamodb } = require('../config/dynamodb');
    
    const params = {
      TableName: 'Users',
      Item: {
        userId: this.userId,
        email: this.email,
        username: this.username,
        password: this.password, // In production, hash this
        createdAt: this.createdAt,
        updatedAt: this.updatedAt,
        isActive: this.isActive,
        lastLogin: this.lastLogin,
        profile: this.profile
      }
    };

    try {
      await dynamodb.put(params).promise();
      return this;
    } catch (error) {
      console.error('Error saving user:', error);
      throw error;
    }
  }

  // Find user by email
  static async findByEmail(email) {
    const { dynamodb } = require('../config/dynamodb');
    
    const params = {
      TableName: 'Users',
      IndexName: 'EmailIndex',
      KeyConditionExpression: 'email = :email',
      ExpressionAttributeValues: {
        ':email': email
      }
    };

    try {
      const result = await dynamodb.query(params).promise();
      return result.Items.length > 0 ? new User(result.Items[0]) : null;
    } catch (error) {
      console.error('Error finding user by email:', error);
      throw error;
    }
  }

  // Find user by username
  static async findByUsername(username) {
    const { dynamodb } = require('../config/dynamodb');
    
    const params = {
      TableName: 'Users',
      IndexName: 'UsernameIndex',
      KeyConditionExpression: 'username = :username',
      ExpressionAttributeValues: {
        ':username': username
      }
    };

    try {
      const result = await dynamodb.query(params).promise();
      return result.Items.length > 0 ? new User(result.Items[0]) : null;
    } catch (error) {
      console.error('Error finding user by username:', error);
      throw error;
    }
  }

  // Find user by ID
  static async findById(userId) {
    const { dynamodb } = require('../config/dynamodb');
    
    const params = {
      TableName: 'Users',
      Key: {
        userId: userId
      }
    };

    try {
      const result = await dynamodb.get(params).promise();
      return result.Item ? new User(result.Item) : null;
    } catch (error) {
      console.error('Error finding user by ID:', error);
      throw error;
    }
  }

  // Update user
  async update(updateData) {
    const { dynamodb } = require('../config/dynamodb');
    
    const updateExpressions = [];
    const expressionAttributeNames = {};
    const expressionAttributeValues = {};

    Object.keys(updateData).forEach(key => {
      if (key !== 'userId' && updateData[key] !== undefined) {
        updateExpressions.push(`#${key} = :${key}`);
        expressionAttributeNames[`#${key}`] = key;
        expressionAttributeValues[`:${key}`] = updateData[key];
      }
    });

    updateExpressions.push('#updatedAt = :updatedAt');
    expressionAttributeNames['#updatedAt'] = 'updatedAt';
    expressionAttributeValues[':updatedAt'] = new Date().toISOString();

    const params = {
      TableName: 'Users',
      Key: {
        userId: this.userId
      },
      UpdateExpression: `SET ${updateExpressions.join(', ')}`,
      ExpressionAttributeNames: expressionAttributeNames,
      ExpressionAttributeValues: expressionAttributeValues,
      ReturnValues: 'ALL_NEW'
    };

    try {
      const result = await dynamodb.update(params).promise();
      Object.assign(this, result.Attributes);
      return this;
    } catch (error) {
      console.error('Error updating user:', error);
      throw error;
    }
  }

  // Delete user
  async delete() {
    const { dynamodb } = require('../config/dynamodb');
    
    const params = {
      TableName: 'Users',
      Key: {
        userId: this.userId
      }
    };

    try {
      await dynamodb.delete(params).promise();
      return true;
    } catch (error) {
      console.error('Error deleting user:', error);
      throw error;
    }
  }

  // Get user without password
  toJSON() {
    const userObj = { ...this };
    delete userObj.password;
    return userObj;
  }

  // Validate password (simple comparison for now - should use bcrypt in production)
  validatePassword(password) {
    return this.password === password;
  }

  // Update last login
  async updateLastLogin() {
    await this.update({ lastLogin: new Date().toISOString() });
  }
}

module.exports = User;
