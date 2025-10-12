const { dynamodb, TABLES, generateId, formatTimestamp, parseTimestamp } = require('../config/dynamodb');

class ProjectService {
  // Create a new project
  async createProject(projectData) {
    const projectId = generateId();
    const timestamp = formatTimestamp();
    
    const project = {
      projectId,
      name: projectData.name,
      description: projectData.description || '',
      roomId: projectData.roomId,
      createdBy: projectData.createdBy,
      collaborators: projectData.collaborators || [],
      projectType: projectData.projectType || 'react',
      settings: {
        allowFileUpload: true,
        allowFileEdit: true,
        allowCompilation: true,
        maxFileSize: 5 * 1024 * 1024, // 5MB
        allowedFileTypes: ['js', 'jsx', 'ts', 'tsx', 'css', 'html', 'json', 'md', 'txt'],
        ...projectData.settings
      },
      compilation: {
        status: 'idle',
        lastCompiled: null,
        buildOutput: null,
        errorLog: null,
        previewUrl: null,
        ...projectData.compilation
      },
      status: 'active',
      createdAt: timestamp,
      updatedAt: timestamp
    };

    const params = {
      TableName: TABLES.PROJECTS,
      Item: project
    };

    await dynamodb.put(params).promise();
    return project;
  }

  // Get project by ID
  async getProjectById(projectId) {
    const params = {
      TableName: TABLES.PROJECTS,
      Key: { projectId }
    };

    const result = await dynamodb.get(params).promise();
    return result.Item || null;
  }

  // Get projects by room ID
  async getProjectsByRoom(roomId) {
    const params = {
      TableName: TABLES.PROJECTS,
      IndexName: 'RoomIdIndex',
      KeyConditionExpression: 'roomId = :roomId',
      ExpressionAttributeValues: {
        ':roomId': roomId
      },
      ScanIndexForward: false // Sort by createdAt descending
    };

    const result = await dynamodb.query(params).promise();
    return result.Items || [];
  }

  // Get projects by creator
  async getProjectsByCreator(createdBy) {
    const params = {
      TableName: TABLES.PROJECTS,
      IndexName: 'CreatedByIndex',
      KeyConditionExpression: 'createdBy = :createdBy',
      ExpressionAttributeValues: {
        ':createdBy': createdBy
      },
      ScanIndexForward: false
    };

    const result = await dynamodb.query(params).promise();
    return result.Items || [];
  }

  // Update project
  async updateProject(projectId, updateData) {
    const timestamp = formatTimestamp();
    
    // Build update expression dynamically
    const updateExpressions = [];
    const expressionAttributeNames = {};
    const expressionAttributeValues = {};

    Object.keys(updateData).forEach(key => {
      if (key !== 'projectId') {
        updateExpressions.push(`#${key} = :${key}`);
        expressionAttributeNames[`#${key}`] = key;
        expressionAttributeValues[`:${key}`] = updateData[key];
      }
    });

    updateExpressions.push('#updatedAt = :updatedAt');
    expressionAttributeNames['#updatedAt'] = 'updatedAt';
    expressionAttributeValues[':updatedAt'] = timestamp;

    const params = {
      TableName: TABLES.PROJECTS,
      Key: { projectId },
      UpdateExpression: `SET ${updateExpressions.join(', ')}`,
      ExpressionAttributeNames: expressionAttributeNames,
      ExpressionAttributeValues: expressionAttributeValues,
      ReturnValues: 'ALL_NEW'
    };

    const result = await dynamodb.update(params).promise();
    return result.Attributes;
  }

  // Add collaborator to project
  async addCollaborator(projectId, collaborator) {
    const project = await this.getProjectById(projectId);
    if (!project) return null;

    const timestamp = formatTimestamp();
    const newCollaborator = {
      ...collaborator,
      joinedAt: timestamp
    };

    const updatedCollaborators = [...project.collaborators, newCollaborator];
    return await this.updateProject(projectId, { collaborators: updatedCollaborators });
  }

  // Remove collaborator from project
  async removeCollaborator(projectId, userId) {
    const project = await this.getProjectById(projectId);
    if (!project) return null;

    const updatedCollaborators = project.collaborators.filter(c => c.userId !== userId);
    return await this.updateProject(projectId, { collaborators: updatedCollaborators });
  }

  // Update compilation status
  async updateCompilationStatus(projectId, compilationData) {
    const timestamp = formatTimestamp();
    
    const updateData = {
      compilation: {
        ...compilationData,
        lastCompiled: timestamp
      }
    };

    return await this.updateProject(projectId, updateData);
  }

  // Get projects by collaborator
  async getProjectsByCollaborator(userId) {
    const params = {
      TableName: TABLES.PROJECTS,
      IndexName: 'CollaboratorsIndex',
      KeyConditionExpression: 'collaborators.userId = :userId',
      ExpressionAttributeValues: {
        ':userId': userId
      }
    };

    const result = await dynamodb.query(params).promise();
    return result.Items || [];
  }

  // Search projects by name
  async searchProjects(searchText, limit = 20) {
    const params = {
      TableName: TABLES.PROJECTS,
      FilterExpression: 'contains(name, :searchText) OR contains(description, :searchText)',
      ExpressionAttributeValues: {
        ':searchText': searchText
      },
      Limit: limit
    };

    const result = await dynamodb.scan(params).promise();
    return result.Items || [];
  }

  // Get active projects
  async getActiveProjects(limit = 50) {
    const params = {
      TableName: TABLES.PROJECTS,
      IndexName: 'StatusIndex',
      KeyConditionExpression: '#status = :status',
      ExpressionAttributeNames: {
        '#status': 'status'
      },
      ExpressionAttributeValues: {
        ':status': 'active'
      },
      ScanIndexForward: false,
      Limit: limit
    };

    const result = await dynamodb.query(params).promise();
    return result.Items || [];
  }

  // Archive project
  async archiveProject(projectId) {
    return await this.updateProject(projectId, { status: 'archived' });
  }

  // Delete project
  async deleteProject(projectId) {
    const params = {
      TableName: TABLES.PROJECTS,
      Key: { projectId }
    };

    await dynamodb.delete(params).promise();
    return true;
  }

  // Get project statistics
  async getProjectStats(projectId) {
    const project = await this.getProjectById(projectId);
    if (!project) return null;

    return {
      projectId: project.projectId,
      name: project.name,
      collaboratorCount: project.collaborators.length,
      compilationStatus: project.compilation.status,
      lastCompiled: project.compilation.lastCompiled,
      createdAt: project.createdAt,
      updatedAt: project.updatedAt
    };
  }
}

module.exports = ProjectService;
