const express = require('express');
const multer = require('multer');
const router = express.Router();
const { dynamodb, TABLES, generateId, formatTimestamp } = require('../config/dynamodb');
const path = require('path');

// Helper function to check and add collaborator if needed
async function ensureCollaborator(project, userId) {
  const isCollaborator = project.collaborators.some(collab => 
    collab.userId === userId || collab.email === userId
  );

  if (!isCollaborator) {
    console.log(`Adding user ${userId} as collaborator to project ${project.projectId}`);
    
    // Add user as collaborator
    project.collaborators.push({
      userId: userId,
      username: userId,
      email: userId,
      role: 'editor',
      joinedAt: formatTimestamp()
    });
    
    // Update project in DynamoDB
    const updateParams = {
      TableName: TABLES.PROJECTS,
      Key: { projectId: project.projectId },
      UpdateExpression: 'SET collaborators = :collaborators, updatedAt = :updatedAt',
      ExpressionAttributeValues: {
        ':collaborators': project.collaborators,
        ':updatedAt': formatTimestamp()
      }
    };

    await dynamodb.update(updateParams).promise();
    return true; // User was added as collaborator
  }
  
  return false; // User was already a collaborator
}

// Configure multer for file uploads
const storage = multer.memoryStorage();
const upload = multer({
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB limit
  },
  fileFilter: (req, file, cb) => {
    const allowedTypes = ['text/javascript', 'text/css', 'text/html', 'application/json', 'text/plain'];
    const allowedExtensions = ['.js', '.jsx', '.ts', '.tsx', '.css', '.html', '.json', '.md', '.txt'];
    
    const fileExt = path.extname(file.originalname).toLowerCase();
    if (allowedExtensions.includes(fileExt) || allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('File type not allowed'), false);
    }
  }
});

// Create a new project
router.post('/create', async (req, res) => {
  try {
    const { name, description, roomId, createdBy, projectType = 'react', roomMembers = [] } = req.body;

    if (!name || !roomId || !createdBy) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: name, roomId, createdBy'
      });
    }

    const projectId = generateId();
    const timestamp = formatTimestamp();

    // Start with creator as owner
    const collaborators = [{
      userId: createdBy,
      username: createdBy,
      email: createdBy,
      role: 'owner',
      joinedAt: timestamp
    }];

    // Add room members as editors if provided
    if (roomMembers && roomMembers.length > 0) {
      roomMembers.forEach(member => {
        if (member.username !== createdBy) { // Don't add creator twice
          collaborators.push({
            userId: member.username || member.email,
            username: member.username || member.email,
            email: member.email || member.username,
            role: 'editor',
            joinedAt: timestamp
          });
        }
      });
    }

    const project = {
      projectId,
      name,
      description: description || '',
      roomId,
      createdBy,
      projectType,
      collaborators,
      settings: {
        allowFileUpload: true,
        allowFileEdit: true,
        allowCompilation: true,
        maxFileSize: 5 * 1024 * 1024, // 5MB
        allowedFileTypes: ['js', 'jsx', 'ts', 'tsx', 'css', 'html', 'json', 'md', 'txt']
      },
      compilation: {
        status: 'idle',
        lastCompiled: null,
        buildOutput: null,
        errorLog: null,
        previewUrl: null
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

    res.status(201).json({
      success: true,
      message: 'Project created successfully',
      project: project
    });
  } catch (error) {
    console.error('Error creating project:', error);
    res.status(500).json({
      success: false,
      message: 'Error creating project',
      error: error.message
    });
  }
});

// Get all projects (basic endpoint)
router.get('/', async (req, res) => {
  try {
    const params = {
      TableName: TABLES.PROJECTS,
      FilterExpression: '#status = :status',
      ExpressionAttributeNames: {
        '#status': 'status'
      },
      ExpressionAttributeValues: {
        ':status': 'active'
      }
    };
    
    const result = await dynamodb.scan(params).promise();
    
    res.json({
      success: true,
      projects: result.Items || []
    });
  } catch (error) {
    console.error('Error fetching projects:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching projects',
      error: error.message
    });
  }
});

// Get projects for a room
router.get('/room/:roomId', async (req, res) => {
  try {
    const { roomId } = req.params;
    const { status = 'active' } = req.query;

    const params = {
      TableName: TABLES.PROJECTS,
      IndexName: 'RoomIdIndex',
      KeyConditionExpression: 'roomId = :roomId',
      FilterExpression: '#status = :status',
      ExpressionAttributeNames: {
        '#status': 'status'
      },
      ExpressionAttributeValues: {
        ':roomId': roomId,
        ':status': status
      }
    };

    const result = await dynamodb.query(params).promise();
    const projects = result.Items.sort((a, b) => new Date(b.updatedAt) - new Date(a.updatedAt));

    res.json({
      success: true,
      projects
    });
  } catch (error) {
    console.error('Error fetching projects:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching projects',
      error: error.message
    });
  }
});

// Get project details with files
router.get('/:projectId', async (req, res) => {
  try {
    const { projectId } = req.params;

    const projectParams = {
      TableName: TABLES.PROJECTS,
      Key: { projectId }
    };

    const projectResult = await dynamodb.get(projectParams).promise();
    if (!projectResult.Item) {
      return res.status(404).json({
        success: false,
        message: 'Project not found'
      });
    }

    const filesParams = {
      TableName: TABLES.PROJECT_FILES,
      IndexName: 'ProjectIdIndex',
      KeyConditionExpression: 'projectId = :projectId',
      ExpressionAttributeValues: {
        ':projectId': projectId
      }
    };

    const filesResult = await dynamodb.query(filesParams).promise();
    const files = filesResult.Items.sort((a, b) => a.fileName.localeCompare(b.fileName));

    res.json({
      success: true,
      project: {
        ...projectResult.Item,
        files
      }
    });
  } catch (error) {
    console.error('Error fetching project:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching project',
      error: error.message
    });
  }
});

// Paste code to project
router.post('/:projectId/files/paste', async (req, res) => {
  try {
    const { projectId } = req.params;
    const { fileName, filePath, fileType, content, uploadedBy, lastModifiedBy, metadata } = req.body;

    if (!fileName || !content || !uploadedBy) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: fileName, content, uploadedBy'
      });
    }

    // Check if project exists and user has permission
    const projectParams = {
      TableName: TABLES.PROJECTS,
      Key: { projectId }
    };

    const projectResult = await dynamodb.get(projectParams).promise();
    if (!projectResult.Item) {
      return res.status(404).json({
        success: false,
        message: 'Project not found'
      });
    }

    const project = projectResult.Item;

    // Ensure user is a collaborator (add if not)
    await ensureCollaborator(project, uploadedBy);

    const fileId = generateId();
    const timestamp = formatTimestamp();

    const projectFile = {
      fileId,
      projectId,
      fileName,
      filePath: filePath || `/${fileName}`,
      fileType,
      content,
      uploadedBy,
      lastModifiedBy: lastModifiedBy || uploadedBy,
      metadata: metadata || {
        size: content.length,
        encoding: 'utf8',
        mimeType: getMimeType(fileType)
      },
      createdAt: timestamp,
      updatedAt: timestamp
    };

    const fileParams = {
      TableName: TABLES.PROJECT_FILES,
      Item: projectFile
    };

    await dynamodb.put(fileParams).promise();

    // Update project's updatedAt timestamp
    const updateParams = {
      TableName: TABLES.PROJECTS,
      Key: { projectId },
      UpdateExpression: 'SET updatedAt = :updatedAt',
      ExpressionAttributeValues: {
        ':updatedAt': timestamp
      }
    };

    await dynamodb.update(updateParams).promise();

    res.status(201).json({
      success: true,
      message: 'Code pasted and saved successfully',
      file: projectFile
    });
  } catch (error) {
    console.error('Error pasting code:', error);
    res.status(500).json({
      success: false,
      message: 'Error pasting code',
      error: error.message
    });
  }
});

// Upload file to project
router.post('/:projectId/files/upload', upload.single('file'), async (req, res) => {
  try {
    const { projectId } = req.params;
    const { uploadedBy } = req.body;

    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No file uploaded'
      });
    }

    // Check if project exists and user has permission
    const project = await Project.findOne({ projectId });
    if (!project) {
      return res.status(404).json({
        success: false,
        message: 'Project not found'
      });
    }

    // Ensure user is a collaborator (add if not)
    await ensureCollaborator(project, uploadedBy);

    const fileExt = path.extname(req.file.originalname).toLowerCase();
    const fileType = getFileType(fileExt);

    const projectFile = new ProjectFile({
      projectId,
      fileName: req.file.originalname,
      filePath: `/${req.file.originalname}`,
      fileType,
      content: req.file.buffer.toString('utf8'),
      uploadedBy,
      lastModifiedBy: uploadedBy,
      metadata: {
        size: req.file.size,
        encoding: req.file.encoding,
        mimeType: req.file.mimetype
      }
    });

    const savedFile = await projectFile.save();

    res.status(201).json({
      success: true,
      message: 'File uploaded successfully',
      file: savedFile
    });
  } catch (error) {
    console.error('Error uploading file:', error);
    res.status(500).json({
      success: false,
      message: 'Error uploading file',
      error: error.message
    });
  }
});

// Update file content
router.put('/:projectId/files/:fileId', async (req, res) => {
  try {
    const { projectId, fileId } = req.params;
    const { content, lastModifiedBy } = req.body;

    if (!content || !lastModifiedBy) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: content, lastModifiedBy'
      });
    }

    // Check if project exists and user has permission
    const project = await Project.findOne({ projectId });
    if (!project) {
      return res.status(404).json({
        success: false,
        message: 'Project not found'
      });
    }

    // Ensure user is a collaborator (add if not)
    await ensureCollaborator(project, lastModifiedBy);

    const updatedFile = await ProjectFile.findOneAndUpdate(
      { _id: fileId, projectId },
      { 
        content,
        lastModifiedBy,
        updatedAt: Date.now()
      },
      { new: true }
    );

    if (!updatedFile) {
      return res.status(404).json({
        success: false,
        message: 'File not found'
      });
    }

    res.json({
      success: true,
      message: 'File updated successfully',
      file: updatedFile
    });
  } catch (error) {
    console.error('Error updating file:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating file',
      error: error.message
    });
  }
});

// Compile project
router.post('/:projectId/compile', async (req, res) => {
  try {
    const { projectId } = req.params;
    const { compiledBy } = req.body;

    // Get project from DynamoDB
    const projectParams = {
      TableName: TABLES.PROJECTS,
      Key: { projectId }
    };
    const projectResult = await dynamodb.get(projectParams).promise();
    
    if (!projectResult.Item) {
      return res.status(404).json({
        success: false,
        message: 'Project not found'
      });
    }

    const project = projectResult.Item;

    // Update compilation status
    const updateParams = {
      TableName: TABLES.PROJECTS,
      Key: { projectId },
      UpdateExpression: 'SET compilation.#status = :status, compilation.lastCompiled = :timestamp',
      ExpressionAttributeNames: {
        '#status': 'status'
      },
      ExpressionAttributeValues: {
        ':status': 'compiling',
        ':timestamp': formatTimestamp()
      }
    };
    await dynamodb.update(updateParams).promise();

    // Get all files for compilation
    const filesParams = {
      TableName: TABLES.PROJECT_FILES,
      FilterExpression: 'projectId = :projectId',
      ExpressionAttributeValues: {
        ':projectId': projectId
      }
    };
    const filesResult = await dynamodb.scan(filesParams).promise();
    const files = filesResult.Items || [];
    
    // Simulate compilation process
    const compilationResult = await compileProject(project, files);

    // Update compilation result
    const finalUpdateParams = {
      TableName: TABLES.PROJECTS,
      Key: { projectId },
      UpdateExpression: 'SET compilation.#status = :status, compilation.buildOutput = :output, compilation.errorLog = :error, compilation.previewUrl = :previewUrl',
      ExpressionAttributeNames: {
        '#status': 'status'
      },
      ExpressionAttributeValues: {
        ':status': compilationResult.success ? 'success' : 'error',
        ':output': compilationResult.output || null,
        ':error': compilationResult.error || null,
        ':previewUrl': compilationResult.previewUrl || null
      }
    };
    await dynamodb.update(finalUpdateParams).promise();

    res.json({
      success: true,
      message: 'Project compiled successfully',
      compilation: compilationResult
    });
  } catch (error) {
    console.error('Error compiling project:', error);
    res.status(500).json({
      success: false,
      message: 'Error compiling project',
      error: error.message
    });
  }
});

// Helper function to determine file type
function getFileType(extension) {
  const typeMap = {
    '.js': 'javascript',
    '.jsx': 'jsx',
    '.ts': 'typescript',
    '.tsx': 'tsx',
    '.css': 'css',
    '.html': 'html',
    '.json': 'json',
    '.md': 'other',
    '.txt': 'other'
  };
  return typeMap[extension] || 'other';
}

// Helper function to get MIME type
function getMimeType(fileType) {
  const mimeMap = {
    'javascript': 'application/javascript',
    'jsx': 'application/javascript',
    'typescript': 'application/typescript',
    'tsx': 'application/typescript',
    'css': 'text/css',
    'html': 'text/html',
    'json': 'application/json',
    'other': 'text/plain'
  };
  return mimeMap[fileType] || 'text/plain';
}

// Preview endpoint to serve compiled HTML
router.get('/:projectId/preview', async (req, res) => {
  try {
    const { projectId } = req.params;
    
    // Get project and files from DynamoDB
    const projectParams = {
      TableName: TABLES.PROJECTS,
      Key: { projectId }
    };
    const projectResult = await dynamodb.get(projectParams).promise();
    
    if (!projectResult.Item) {
      return res.status(404).send('Project not found');
    }
    
    const project = projectResult.Item;
    
    const filesParams = {
      TableName: TABLES.PROJECT_FILES,
      FilterExpression: 'projectId = :projectId',
      ExpressionAttributeValues: {
        ':projectId': projectId
      }
    };
    const filesResult = await dynamodb.scan(filesParams).promise();
    const files = filesResult.Items || [];
    
    if (files.length === 0) {
      return res.status(404).send('No files found in project');
    }
    
    // Compile the project
    const compilation = await compileProject(project, files);
    
    if (!compilation.success) {
      return res.status(400).send(`Compilation Error: ${compilation.error}`);
    }
    
    // Set content type and send HTML
    res.setHeader('Content-Type', 'text/html');
    res.send(compilation.output);
    
  } catch (error) {
    console.error('Error serving preview:', error);
    res.status(500).send('Error serving preview');
  }
});

// Serve individual project files (CSS, JS, etc.)
router.get('/:projectId/:filename', async (req, res) => {
  try {
    const { projectId, filename } = req.params;

    const project = await Project.findOne({ projectId });
    if (!project) {
      return res.status(404).send('Project not found');
    }

    const file = await ProjectFile.findOne({ 
      projectId, 
      fileName: filename 
    });

    if (!file) {
      return res.status(404).send('File not found');
    }

    // Set appropriate content type based on file extension
    const ext = filename.split('.').pop().toLowerCase();
    let contentType = 'text/plain';
    
    switch (ext) {
      case 'css':
        contentType = 'text/css';
        break;
      case 'js':
        contentType = 'application/javascript';
        break;
      case 'html':
        contentType = 'text/html';
        break;
      case 'json':
        contentType = 'application/json';
        break;
      default:
        contentType = 'text/plain';
    }

    res.setHeader('Content-Type', contentType);
    res.send(file.content);

  } catch (error) {
    console.error('Error serving file:', error);
    res.status(500).send('Error serving file');
  }
});

// Helper function to compile project
async function compileProject(project, files) {
  try {
    // This is a simplified compilation process
    // In a real implementation, you would use tools like Webpack, Vite, or custom compilers
    
    const htmlFile = files.find(f => f.fileType === 'html');
    const cssFiles = files.filter(f => f.fileType === 'css');
    const jsFiles = files.filter(f => f.fileType === 'javascript' || f.fileType === 'jsx');

    if (!htmlFile) {
      return {
        success: false,
        error: 'No HTML file found. Please upload an index.html file.',
        output: '',
        previewUrl: null
      };
    }

    // Combine CSS files
    const combinedCSS = cssFiles.map(f => f.content).join('\n');
    
    // Combine JS files
    const combinedJS = jsFiles.map(f => f.content).join('\n');

    // Create compiled HTML with proper structure
    const compiledHTML = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${project.name}</title>
    <style>
        body {
            margin: 0;
            padding: 20px;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        ${combinedCSS}
    </style>
</head>
<body>
    <div class="container">
        ${htmlFile.content}
    </div>
    <script>
        // Add error handling for JavaScript
        try {
            ${combinedJS}
        } catch (error) {
            console.error('JavaScript Error:', error);
            document.body.innerHTML += '<div style="color: red; padding: 10px; background: #ffe6e6; border: 1px solid red; margin: 10px; border-radius: 4px;">JavaScript Error: ' + error.message + '</div>';
        }
    </script>
</body>
</html>
    `;

    // Generate preview URL (in production, this would be a real URL)
    const previewUrl = `/api/projects/${project.projectId}/preview`;

    return {
      success: true,
      output: compiledHTML,
      error: null,
      previewUrl
    };
  } catch (error) {
    return {
      success: false,
      output: '',
      error: error.message,
      previewUrl: null
    };
  }
}

module.exports = router;
