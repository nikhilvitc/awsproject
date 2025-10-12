import React, { useState, useEffect, useRef, useCallback } from 'react';
import { useAuth } from './AuthContext';
import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter';
import { tomorrow } from 'react-syntax-highlighter/dist/esm/styles/prism';
import socketService from '../services/socketService';
import '../styles/components/CollaborativeEditor.css';

function CollaborativeEditor({ roomId, onClose, participants = [] }) {
  const { user, isAuthenticated } = useAuth();
  const [projects, setProjects] = useState([]);
  const [selectedProject, setSelectedProject] = useState(null);
  const [files, setFiles] = useState([]);
  const [selectedFile, setSelectedFile] = useState(null);
  const [fileContent, setFileContent] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [compilationStatus, setCompilationStatus] = useState('idle');
  const [previewUrl, setPreviewUrl] = useState('');
  const [showCodePaste, setShowCodePaste] = useState(false);
  const [pastedCode, setPastedCode] = useState('');
  const [selectedLanguage, setSelectedLanguage] = useState('nodejs');
  const [fileName, setFileName] = useState('');
  const [showSyntaxHighlighting, setShowSyntaxHighlighting] = useState(true);
  const [showScrollToTop, setShowScrollToTop] = useState(false);
  const [showSideScroller, setShowSideScroller] = useState(false);
  const [scrollProgress, setScrollProgress] = useState(0);
  
  // Live collaborative editing state
  const [editingUsers, setEditingUsers] = useState(new Map()); // userId -> { position, selection, color, timestamp }
  const [userCursors, setUserCursors] = useState(new Map()); // userId -> cursor info
  const [isTyping, setIsTyping] = useState(false);
  const [typingUsers, setTypingUsers] = useState(new Map()); // userId -> typing info
  const [autoSaveEnabled, setAutoSaveEnabled] = useState(true);
  const [lastSaved, setLastSaved] = useState(null);
  const [fileVersion, setFileVersion] = useState(0);
  const [hasConflicts, setHasConflicts] = useState(false);
  
  const fileInputRef = useRef(null);
  const contentRef = useRef(null);
  const textareaRef = useRef(null);
  const typingTimeoutRef = useRef(null);
  const autoSaveTimeoutRef = useRef(null);
  const cursorUpdateTimeoutRef = useRef(null);

  useEffect(() => {
    if (roomId) {
      loadProjects();
      setupCollaborativeEditing();
    }
    
    // Clean up when editor is closed
    return () => {
      cleanupCollaborativeEditing();
    };
  }, [roomId]);

  // Setup collaborative editing WebSocket listeners
  const setupCollaborativeEditing = useCallback(() => {
    console.log('Setting up collaborative editing...');
    console.log('Socket connected:', socketService.isConnected());
    console.log('Room ID:', roomId);
    console.log('User:', user);
    
    if (!socketService.isConnected()) {
      console.log('Connecting to socket...');
      socketService.connect();
    }

    // Add a small delay to ensure socket is connected
    setTimeout(() => {
      console.log('Socket connection status after delay:', socketService.isConnected());
    }, 1000);

    // Listen for file content updates from other users
    socketService.onFileContentUpdated((data) => {
      console.log('📥 Received file content update:', data);
      console.log('Current project:', selectedProject?.projectId);
      console.log('Current file:', selectedFile?._id);
      console.log('Current user:', user?.email || user?.username);
      console.log('Update from user:', data.userId);
      
      if (data.projectId === selectedProject?.projectId && 
          data.fileId === selectedFile?._id && 
          data.userId !== (user?.email || user?.username)) {
        
        console.log('✅ Processing file content update for current file from:', data.userId);
        
        // Simple conflict resolution: if local version is newer, show conflict warning
        if (data.timestamp < Date.now() - 5000) { // 5 second tolerance
          setHasConflicts(true);
          console.warn('Potential conflict detected with remote changes');
        }
        
        setFileContent(data.content);
        setLastSaved(new Date());
        setFileVersion(prev => prev + 1);
      } else {
        console.log('❌ Ignoring file content update (not matching project/file or from self)');
      }
    });

    // Listen for cursor position updates
    socketService.onUserCursorUpdated((data) => {
      console.log('🎯 Received cursor update:', data);
      console.log('Current project:', selectedProject?.projectId);
      console.log('Current file:', selectedFile?._id);
      console.log('Current user:', user?.email || user?.username);
      console.log('Cursor from user:', data.userId);
      
      // Accept cursor updates if:
      // 1. Same project and file (exact match)
      // 2. Same project but no file selected (show cursor for any file in project)
      // 3. No project selected but received project matches available projects
      // 4. Different user (not from self)
      const isSameProject = data.projectId === selectedProject?.projectId;
      const isSameFile = data.fileId === (selectedFile?._id || selectedFile?.id || selectedFile?.fileId);
      const isDifferentUser = data.userId !== (user?.email || user?.username);
      
      // Check if the received project ID matches any available project
      const hasMatchingProject = projects.some(project => project.projectId === data.projectId);
      
      // More permissive logic - accept cursor updates if:
      // 1. Different user AND
      // 2. Either same project/file OR no project selected but project exists in available projects
      if (isDifferentUser && (
        (isSameProject && isSameFile) || 
        (isSameProject && !selectedFile) ||
        (!selectedProject && hasMatchingProject) ||
        (!selectedProject && !selectedFile) // Accept any cursor if no project/file selected
      )) {
        console.log('✅ Processing cursor update for current file from:', data.userId);
        setUserCursors(prev => {
          const newCursors = new Map(prev);
          newCursors.set(data.userId, {
            position: data.position,
            selection: data.selection,
            timestamp: data.timestamp
          });
          console.log('Updated cursors:', newCursors);
          return newCursors;
        });
      } else {
        console.log('❌ Ignoring cursor update:', {
          isDifferentUser,
          isSameProject,
          isSameFile,
          hasSelectedFile: !!selectedFile,
          hasSelectedProject: !!selectedProject,
          hasMatchingProject,
          reason: !isDifferentUser ? 'from self' : !isSameProject && !hasMatchingProject ? 'different project' : 'different file',
          receivedProjectId: data.projectId,
          currentProjectId: selectedProject?.projectId,
          availableProjects: projects.map(p => p.projectId),
          receivedData: data
        });
      }
    });

    // Listen for user selection updates
    socketService.onUserSelectionUpdated((data) => {
      if (data.projectId === selectedProject?.projectId && 
          data.fileId === selectedFile?._id && 
          data.userId !== user?.email) {
        setEditingUsers(prev => {
          const newUsers = new Map(prev);
          newUsers.set(data.userId, {
            selection: data.selection,
            color: data.color,
            timestamp: data.timestamp
          });
          return newUsers;
        });
      }
    });

    // Listen for users editing files
    socketService.onUserEditingFile((data) => {
      if (data.projectId === selectedProject?.projectId && 
          data.fileId === selectedFile?._id && 
          data.userId !== user?.email) {
        console.log(`User ${data.userId} is editing file ${data.fileId}`);
      }
    });

    // Listen for users stopping file editing
    socketService.onUserStoppedEditingFile((data) => {
      if (data.projectId === selectedProject?.projectId && 
          data.fileId === selectedFile?._id && 
          data.userId !== user?.email) {
        setUserCursors(prev => {
          const newCursors = new Map(prev);
          newCursors.delete(data.userId);
          return newCursors;
        });
        setEditingUsers(prev => {
          const newUsers = new Map(prev);
          newUsers.delete(data.userId);
          return newUsers;
        });
      }
    });

    // Listen for code typing indicators
    socketService.onUserCodeTyping((data) => {
      if (data.projectId === selectedProject?.projectId && 
          data.fileId === selectedFile?._id && 
          data.userId !== user?.email) {
        setTypingUsers(prev => {
          const newTyping = new Map(prev);
          if (data.isTyping) {
            newTyping.set(data.userId, {
              timestamp: data.timestamp,
              fileId: data.fileId
            });
          } else {
            newTyping.delete(data.userId);
          }
          return newTyping;
        });
      }
    });
  }, [selectedProject, selectedFile, user]);

  // Cleanup collaborative editing
  const cleanupCollaborativeEditing = useCallback(() => {
    if (selectedProject && selectedFile && user) {
      socketService.leaveFileEdit({
        roomId,
        projectId: selectedProject.projectId,
        fileId: selectedFile._id,
        userId: user.email || user.username
      });
    }
    
    // Clear timeouts
    if (typingTimeoutRef.current) {
      clearTimeout(typingTimeoutRef.current);
    }
    if (autoSaveTimeoutRef.current) {
      clearTimeout(autoSaveTimeoutRef.current);
    }
    if (cursorUpdateTimeoutRef.current) {
      clearTimeout(cursorUpdateTimeoutRef.current);
    }
  }, [selectedProject, selectedFile, user, roomId]);

  // Handle scroll events for scroll buttons
  useEffect(() => {
    const handleScroll = () => {
      if (contentRef.current) {
        const scrollTop = contentRef.current.scrollTop;
        const scrollHeight = contentRef.current.scrollHeight;
        const clientHeight = contentRef.current.clientHeight;
        
        // Show scroll to top button when scrolled down
        setShowScrollToTop(scrollTop > 200);
        
        // Show side scroller when content is scrollable
        setShowSideScroller(scrollHeight > clientHeight);
        
        // Calculate scroll progress
        const progress = (scrollTop / (scrollHeight - clientHeight)) * 100;
        setScrollProgress(Math.min(100, Math.max(0, progress)));
      }
    };

    const contentElement = contentRef.current;
    if (contentElement) {
      // Use passive event listener for better performance
      contentElement.addEventListener('scroll', handleScroll, { passive: true });
      return () => contentElement.removeEventListener('scroll', handleScroll);
    }
  }, [selectedProject, files]);

  // Fix scroll position when content changes
  useEffect(() => {
    if (contentRef.current && selectedFile) {
      // Small delay to ensure content is rendered
      setTimeout(() => {
        if (contentRef.current) {
          contentRef.current.scrollTop = 0;
        }
      }, 100);
    }
  }, [selectedFile]);

  const loadProjects = async () => {
    try {
      const apiUrl = process.env.REACT_APP_API_URL || 'http://localhost:5000';
      const response = await fetch(`${apiUrl}/api/projects/room/${roomId}`);
      const data = await response.json();
      
      if (data.success) {
        setProjects(data.projects);
      }
    } catch (err) {
      console.error('Error loading projects:', err);
    }
  };

  const createProject = async () => {
    const projectName = prompt('Enter project name:');
    if (!projectName) return;

    setLoading(true);
    setError('');

    try {
      const apiUrl = process.env.REACT_APP_API_URL || 'http://localhost:5000';
      const response = await fetch(`${apiUrl}/api/projects/create`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          name: projectName,
          description: `Collaborative project for room ${roomId}`,
          roomId,
          createdBy: user?.email || user?.username,
          projectType: 'react',
          roomMembers: participants.map(p => ({
            username: p.username,
            email: p.email || p.username
          }))
        })
      });

      const data = await response.json();
      if (data.success) {
        setSuccess('Project created successfully!');
        loadProjects();
        setSelectedProject(data.project);
        loadProjectFiles(data.project.projectId);
      } else {
        setError(data.message || 'Failed to create project');
      }
    } catch (err) {
      setError('Failed to create project');
      console.error('Error creating project:', err);
    } finally {
      setLoading(false);
    }
  };

  const loadProjectFiles = async (projectId) => {
    try {
      const apiUrl = process.env.REACT_APP_API_URL || 'http://localhost:5000';
      const response = await fetch(`${apiUrl}/api/projects/${projectId}`);
      const data = await response.json();
      
      if (data.success) {
        setFiles(data.project.files || []);
        if (data.project.files && data.project.files.length > 0) {
          setSelectedFile(data.project.files[0]);
          setFileContent(data.project.files[0].content);
        }
      }
    } catch (err) {
      console.error('Error loading project files:', err);
    }
  };

  const handleFileUpload = async (event) => {
    const file = event.target.files[0];
    if (!file || !selectedProject) {
      setError('Please select a project and file to upload');
      return;
    }

    // Validate file type
    const allowedTypes = ['.js', '.jsx', '.ts', '.tsx', '.css', '.html', '.json', '.md', '.txt'];
    const fileExtension = '.' + file.name.split('.').pop().toLowerCase();
    if (!allowedTypes.includes(fileExtension)) {
      setError(`File type ${fileExtension} is not supported. Allowed types: ${allowedTypes.join(', ')}`);
      return;
    }

    // Validate file size (max 1MB)
    if (file.size > 1024 * 1024) {
      setError('File size must be less than 1MB');
      return;
    }

    setLoading(true);
    setError('');
    setSuccess('');

    try {
      const formData = new FormData();
      formData.append('file', file);
      formData.append('uploadedBy', user?.email || user?.username);
      formData.append('lastModifiedBy', user?.email || user?.username);

      const apiUrl = process.env.REACT_APP_API_URL || 'http://localhost:5000';
      const response = await fetch(`${apiUrl}/api/projects/${selectedProject.projectId}/files/upload`, {
        method: 'POST',
        body: formData
      });

      if (!response.ok) {
        throw new Error(`Upload failed with status: ${response.status}`);
      }

      const data = await response.json();
      if (data.success) {
        setSuccess(`File "${file.name}" uploaded successfully!`);
        loadProjectFiles(selectedProject.projectId);
        // Clear the file input
        event.target.value = '';
      } else {
        setError(data.message || 'Failed to upload file');
      }
    } catch (err) {
      setError(`Failed to upload file: ${err.message}`);
      console.error('Error uploading file:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleFileSelect = (file) => {
    console.log('🔍 File selected:', file);
    console.log('File ID:', file?._id);
    console.log('File name:', file?.fileName);
    console.log('File type:', file?.fileType);
    console.log('All file properties:', Object.keys(file || {}));
    
    // Check if file has _id, if not, try to use id or generate one
    let fileId = file?._id;
    if (!fileId) {
      fileId = file?.id || file?.fileId || `file_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      console.log('⚠️ File missing _id, using generated ID:', fileId);
    }
    
    // Leave current file editing session if any
    if (selectedFile && selectedProject && user) {
      console.log('Leaving current file editing session...');
      socketService.leaveFileEdit({
        roomId,
        projectId: selectedProject.projectId,
        fileId: selectedFile._id || selectedFile.id || selectedFile.fileId,
        userId: user.email || user.username
      });
    }

    setSelectedFile(file);
    setFileContent(file.content);

    // Join new file editing session
    if (file && selectedProject && user && socketService.isConnected()) {
      console.log('Joining new file editing session...', {
        roomId,
        projectId: selectedProject.projectId,
        fileId: fileId,
        userId: user.email || user.username
      });
      
      socketService.joinFileEdit({
        roomId,
        projectId: selectedProject.projectId,
        fileId: fileId,
        userId: user.email || user.username
      });
    } else {
      console.log('Cannot join file editing session:', {
        file: !!file,
        selectedProject: !!selectedProject,
        user: !!user,
        socketConnected: socketService.isConnected(),
        fileId: fileId
      });
    }
  };

  const handleFileDelete = async (fileId) => {
    if (!selectedProject || !fileId) {
      setError('No file selected for deletion');
      return;
    }

    if (!confirm('Are you sure you want to delete this file?')) {
      return;
    }

    setLoading(true);
    setError('');
    setSuccess('');

    try {
      const apiUrl = process.env.REACT_APP_API_URL || 'http://localhost:5000';
      const response = await fetch(`${apiUrl}/api/projects/${selectedProject.projectId}/files/${fileId}`, {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) {
        throw new Error(`Delete failed with status: ${response.status}`);
      }

      const data = await response.json();
      if (data.success) {
        setSuccess('File deleted successfully!');
        loadProjectFiles(selectedProject.projectId);
        // Clear selection if deleted file was selected
        if (selectedFile && selectedFile._id === fileId) {
          setSelectedFile(null);
          setFileContent('');
        }
      } else {
        setError(data.message || 'Failed to delete file');
      }
    } catch (err) {
      setError(`Failed to delete file: ${err.message}`);
      console.error('Error deleting file:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleFileSave = async () => {
    if (!selectedFile || !selectedProject) {
      setError('No file selected to save');
      return;
    }

    setLoading(true);
    setError('');
    setSuccess('');

    try {
      const apiUrl = process.env.REACT_APP_API_URL || 'http://localhost:5000';
      const response = await fetch(`${apiUrl}/api/projects/${selectedProject.projectId}/files/${selectedFile._id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          content: fileContent,
          lastModifiedBy: user?.email || user?.username
        })
      });

      if (!response.ok) {
        throw new Error(`Save failed with status: ${response.status}`);
      }

      const data = await response.json();
      if (data.success) {
        setSuccess('File saved successfully!');
        loadProjectFiles(selectedProject.projectId);
      } else {
        setError(data.message || 'Failed to save file');
      }
    } catch (err) {
      setError(`Failed to save file: ${err.message}`);
      console.error('Error saving file:', err);
    } finally {
      setLoading(false);
    }
  };

  // Generate user color based on userId
  const getUserColor = useCallback((userId) => {
    const colors = [
      '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7',
      '#DDA0DD', '#98D8C8', '#F7DC6F', '#BB8FCE', '#85C1E9'
    ];
    let hash = 0;
    for (let i = 0; i < userId.length; i++) {
      hash = userId.charCodeAt(i) + ((hash << 5) - hash);
    }
    return colors[Math.abs(hash) % colors.length];
  }, []);

  // Debounced function to send file content changes
  const debouncedSendContentChange = useCallback((data) => {
    if (autoSaveTimeoutRef.current) {
      clearTimeout(autoSaveTimeoutRef.current);
    }
    
    autoSaveTimeoutRef.current = setTimeout(() => {
      if (data && socketService.isConnected()) {
        console.log('Sending debounced content change:', data);
        socketService.sendFileContentChange(data);
      }
    }, 300); // 300ms debounce
  }, []);

  // Debounced function to send cursor position
  const debouncedSendCursorPosition = useCallback((position, selection) => {
    if (cursorUpdateTimeoutRef.current) {
      clearTimeout(cursorUpdateTimeoutRef.current);
    }
    
    cursorUpdateTimeoutRef.current = setTimeout(() => {
      if (selectedProject && selectedFile && user && socketService.isConnected()) {
        const fileId = selectedFile._id || selectedFile.id || selectedFile.fileId;
        if (fileId) {
          socketService.sendCursorPosition({
            roomId,
            projectId: selectedProject.projectId,
            fileId: fileId,
            userId: user.email || user.username,
            position,
            selection
          });
        }
      }
    }, 100); // 100ms debounce for cursor updates
  }, [selectedProject, selectedFile, user, roomId]);

  // Handle typing indicator
  const handleTyping = useCallback(() => {
    if (!isTyping) {
      setIsTyping(true);
      if (selectedProject && selectedFile && user && socketService.isConnected()) {
        const fileId = selectedFile._id || selectedFile.id || selectedFile.fileId;
        if (fileId) {
          socketService.sendCodeTyping({
            roomId,
            projectId: selectedProject.projectId,
            fileId: fileId,
            userId: user.email || user.username,
            isTyping: true
          });
        }
      }
    }

    // Clear existing timeout
    if (typingTimeoutRef.current) {
      clearTimeout(typingTimeoutRef.current);
    }

    // Set new timeout to stop typing indicator
    typingTimeoutRef.current = setTimeout(() => {
      setIsTyping(false);
      if (selectedProject && selectedFile && user && socketService.isConnected()) {
        const fileId = selectedFile._id || selectedFile.id || selectedFile.fileId;
        if (fileId) {
          socketService.sendCodeTyping({
            roomId,
            projectId: selectedProject.projectId,
            fileId: fileId,
            userId: user.email || user.username,
            isTyping: false
          });
        }
      }
    }, 1000);
  }, [isTyping, selectedProject, selectedFile, user, roomId]);

  const handleFileContentChange = (content) => {
    console.log('📝 File content changed:', content.length, 'characters');
    console.log('📁 Selected file:', selectedFile);
    console.log('📁 Selected file ID:', selectedFile?._id);
    console.log('📁 Selected project:', selectedProject);
    console.log('👤 User:', user);
    setFileContent(content);
    
    // Get file ID with fallback
    const fileId = selectedFile?._id || selectedFile?.id || selectedFile?.fileId;
    console.log('📁 Using file ID:', fileId);
    
    // Send live update to other users
    if (selectedProject && selectedFile && user && socketService.isConnected() && fileId) {
      console.log('📤 Sending content change to other users...', {
        roomId,
        projectId: selectedProject.projectId,
        fileId: fileId,
        userId: user.email || user.username
      });
      
      debouncedSendContentChange({
        roomId,
        projectId: selectedProject.projectId,
        fileId: fileId,
        content: content,
        userId: user.email || user.username,
        timestamp: Date.now()
      });
    } else {
      console.log('❌ Cannot send content change:', {
        selectedProject: !!selectedProject,
        selectedFile: !!selectedFile,
        user: !!user,
        socketConnected: socketService.isConnected(),
        fileId: fileId
      });
    }
    
    // Handle typing indicator
    handleTyping();
    
    // Auto-save if enabled
    if (autoSaveEnabled) {
      // Auto-save will be handled by the debounced function above
    }
  };

  // Handle cursor position changes
  const handleCursorChange = (event) => {
    const textarea = event.target;
    const position = textarea.selectionStart;
    const selection = {
      start: textarea.selectionStart,
      end: textarea.selectionEnd
    };
    
    console.log('🎯 Cursor position changed:', position, selection);
    console.log('📁 Selected file ID:', selectedFile?._id);
    console.log('📁 Selected project ID:', selectedProject?.projectId);
    console.log('👤 User:', user?.email || user?.username);
    
    // Get file ID with fallback
    const fileId = selectedFile?._id || selectedFile?.id || selectedFile?.fileId;
    console.log('📁 Using file ID:', fileId);
    
    if (selectedProject && selectedFile && user && fileId) {
      console.log('📤 Sending cursor position...');
      debouncedSendCursorPosition(position, selection);
    } else {
      console.log('❌ Cannot send cursor position:', {
        selectedProject: !!selectedProject,
        selectedFile: !!selectedFile,
        user: !!user,
        fileId: fileId
      });
    }
  };

  // Handle selection changes
  const handleSelectionChange = (event) => {
    const textarea = event.target;
    const selection = {
      start: textarea.selectionStart,
      end: textarea.selectionEnd
    };
    
    if (selectedProject && selectedFile && user && socketService.isConnected()) {
      socketService.sendUserSelection({
        roomId,
        projectId: selectedProject.projectId,
        fileId: selectedFile._id,
        userId: user.email || user.username,
        selection,
        color: getUserColor(user.email || user.username)
      });
    }
  };

  const saveFileContent = async () => {
    if (!selectedFile || !selectedProject) return;

    setLoading(true);
    setError('');

    try {
      const apiUrl = process.env.REACT_APP_API_URL || 'http://localhost:5000';
      const response = await fetch(`${apiUrl}/api/projects/${selectedProject.projectId}/files/${selectedFile._id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          content: fileContent,
          lastModifiedBy: user?.email || user?.username
        })
      });

      const data = await response.json();
      if (data.success) {
        setSuccess('File saved successfully!');
        loadProjectFiles(selectedProject.projectId);
      } else {
        setError(data.message || 'Failed to save file');
      }
    } catch (err) {
      setError('Failed to save file');
      console.error('Error saving file:', err);
    } finally {
      setLoading(false);
    }
  };

  const compileProject = async () => {
    if (!selectedProject) {
      setError('Please select a project first');
      return;
    }

    if (files.length === 0) {
      setError('No files to compile. Please upload some files first.');
      return;
    }

    setCompilationStatus('compiling');
    setError('');
    setSuccess('');

    try {
      const apiUrl = process.env.REACT_APP_API_URL || 'http://localhost:5000';
      const response = await fetch(`${apiUrl}/api/projects/${selectedProject.projectId}/compile`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          compiledBy: user?.email || user?.username
        })
      });

      if (!response.ok) {
        throw new Error(`Compilation failed with status: ${response.status}`);
      }
      
      const data = await response.json();

      if (data.success && data.compilation) {
        setCompilationStatus('success');
        
        // Try to use the preview URL first
        const fullPreviewUrl = `${apiUrl}${data.compilation.previewUrl}`;
        
        // Test if the preview URL is accessible
        try {
          const testResponse = await fetch(fullPreviewUrl, { method: 'HEAD' });
          if (testResponse.ok) {
            setPreviewUrl(fullPreviewUrl);
          } else {
            // Fallback to data URL
            const dataUrl = `data:text/html;charset=utf-8,${encodeURIComponent(data.compilation.output)}`;
            setPreviewUrl(dataUrl);
          }
        } catch (urlError) {
          // Fallback to data URL if preview URL fails
          const dataUrl = `data:text/html;charset=utf-8,${encodeURIComponent(data.compilation.output)}`;
          setPreviewUrl(dataUrl);
        }
        
        setSuccess('Project compiled successfully!');
      } else {
        setCompilationStatus('error');
        setError(data.message || 'Compilation failed');
      }
    } catch (err) {
      setCompilationStatus('error');
      setError(`Failed to compile project: ${err.message}`);
      console.error('Error compiling project:', err);
    }
  };

  const handleCodePaste = () => {
    setShowCodePaste(true);
    setPastedCode('');
    setFileName('');
    setSelectedLanguage('javascript');
  };

  // Scroll functions
  const scrollToTop = () => {
    if (contentRef.current) {
      contentRef.current.scrollTo({
        top: 0,
        behavior: 'smooth'
      });
    }
  };

  const scrollToSection = (sectionId) => {
    const element = document.getElementById(sectionId);
    if (element) {
      element.scrollIntoView({
        behavior: 'smooth',
        block: 'start'
      });
    }
  };

  const scrollToPreview = () => {
    const previewSection = document.querySelector('.preview-section');
    if (previewSection) {
      previewSection.scrollIntoView({
        behavior: 'smooth',
        block: 'start'
      });
    }
  };

  const savePastedCode = async () => {
    if (!pastedCode.trim() || !fileName.trim() || !selectedProject) {
      setError('Please provide code, filename, and select a project');
      return;
    }

    setLoading(true);
    setError('');

    try {
      const apiUrl = process.env.REACT_APP_API_URL || 'http://localhost:5000';
      
      // Create a file object for the pasted code
      const fileData = {
        projectId: selectedProject.projectId,
        fileName: fileName,
        filePath: `/${fileName}`,
        fileType: selectedLanguage,
        content: pastedCode,
        uploadedBy: user?.email || user?.username,
        lastModifiedBy: user?.email || user?.username,
        metadata: {
          size: pastedCode.length,
          encoding: 'utf8',
          mimeType: getMimeType(selectedLanguage)
        }
      };

      const response = await fetch(`${apiUrl}/api/projects/${selectedProject.projectId}/files/paste`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(fileData)
      });

      const data = await response.json();
      if (data.success) {
        setSuccess('Code pasted and saved successfully!');
        setShowCodePaste(false);
        setPastedCode('');
        setFileName('');
        loadProjectFiles(selectedProject.projectId);
      } else {
        setError(data.message || 'Failed to save pasted code');
      }
    } catch (err) {
      setError('Failed to save pasted code');
      console.error('Error saving pasted code:', err);
    } finally {
      setLoading(false);
    }
  };

  const getMimeType = (language) => {
    const mimeTypes = {
      'nodejs': 'text/javascript',
      'css': 'text/css',
      'html': 'text/html',
      'json': 'application/json'
    };
    return mimeTypes[language] || 'text/plain';
  };

  const getFileExtension = (language) => {
    const extensions = {
      'nodejs': '.js',
      'css': '.css',
      'html': '.html',
      'json': '.json'
    };
    return extensions[language] || '.txt';
  };

  const handleLanguageChange = (language) => {
    setSelectedLanguage(language);
    if (!fileName || fileName === '') {
      setFileName(`file${getFileExtension(language)}`);
    } else if (!fileName.includes('.')) {
      setFileName(`${fileName}${getFileExtension(language)}`);
    }
  };

  if (!isAuthenticated) {
    return (
      <div className="collaborative-editor-overlay" onClick={onClose}>
        <div className="collaborative-editor-container" onClick={e => e.stopPropagation()}>
          <div className="error-message">
            Please log in to use the collaborative editor.
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="collaborative-editor-overlay" onClick={onClose}>
      <div className="collaborative-editor-container" onClick={e => e.stopPropagation()}>
        <div className="collaborative-editor-header">
          <h2>🚀 Collaborative Code Editor</h2>
          <div className="header-controls">
            <div className={`collaborative-status ${socketService.isConnected() ? 'connected' : 'disconnected'}`}>
              <div className="status-indicator"></div>
              <span>{socketService.isConnected() ? 'Live Collaboration Active' : 'Disconnected'}</span>
              <span style={{ fontSize: '10px', marginLeft: '10px' }}>
                Socket: {socketService.isConnected() ? '✅' : '❌'} | 
                Room: {roomId ? '✅' : '❌'} | 
                User: {user ? '✅' : '❌'}
              </span>
            </div>
            <button className="close-btn" onClick={onClose}>×</button>
          </div>
        </div>
        
        <div className="collaborative-editor-content" ref={contentRef}>
          {error && <div className="error-message">{error}</div>}
          {success && <div className="success-message">{success}</div>}
          {/* Project Selection */}
          <div id="project-section" className="project-section">
            <div className="section-header">
              <h3>📁 Projects</h3>
              <button onClick={createProject} className="btn-primary" disabled={loading}>
                + New Project
              </button>
            </div>
            
            <div className="projects-list">
              {projects.map(project => (
                <div 
                  key={project.projectId}
                  className={`project-item ${selectedProject?.projectId === project.projectId ? 'active' : ''}`}
                  onClick={() => {
                    setSelectedProject(project);
                    loadProjectFiles(project.projectId);
                  }}
                >
                  <div className="project-name">{project.name}</div>
                  <div className="project-meta">
                    {project.collaborators.length} collaborator{project.collaborators.length !== 1 ? 's' : ''}
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* File Management */}
          {selectedProject && (
            <div id="files-section" className="files-section">
              <div className="section-header">
                <h3>📄 Files</h3>
                <div className="file-actions">
                  <input
                    type="file"
                    ref={fileInputRef}
                    onChange={handleFileUpload}
                    accept=".js,.jsx,.ts,.tsx,.css,.html,.json,.md,.txt"
                    style={{ display: 'none' }}
                  />
                  <button 
                    onClick={() => fileInputRef.current?.click()}
                    className="btn-secondary"
                    disabled={loading}
                  >
                    📤 Upload File
                  </button>
                  <button 
                    onClick={handleCodePaste}
                    className="btn-secondary"
                    disabled={loading}
                  >
                    📝 Paste Code
                  </button>
                  <button 
                    onClick={compileProject}
                    className="btn-primary"
                    disabled={loading || compilationStatus === 'compiling'}
                  >
                    {compilationStatus === 'compiling' ? '⏳ Compiling...' : '🔨 Compile'}
                  </button>
                </div>
              </div>

              <div className="files-grid">
                <div className="files-list">
                  {files.map(file => (
                    <div 
                      key={file._id}
                      className={`file-item ${selectedFile?._id === file._id ? 'active' : ''}`}
                    >
                      <div className="file-content" onClick={() => handleFileSelect(file)}>
                        <div className="file-icon">
                          {file.fileType === 'javascript' ? '📜' : 
                           file.fileType === 'css' ? '🎨' : 
                           file.fileType === 'html' ? '🌐' : '📄'}
                        </div>
                        <div className="file-info">
                          <div className="file-name">{file.fileName}</div>
                          <div className="file-meta">
                            {file.fileType} • {file.metadata?.size ? Math.round(file.metadata.size / 1024) + 'KB' : 'Unknown size'}
                          </div>
                        </div>
                      </div>
                      <div className="file-actions">
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            handleFileDelete(file._id);
                          }}
                          className="delete-btn"
                          title="Delete file"
                          disabled={loading}
                        >
                          🗑️
                        </button>
                      </div>
                    </div>
                  ))}
                </div>

                {selectedFile && (
                  <div className="file-editor">
                    <div className="editor-header">
                      <span className="file-name">{selectedFile.fileName}</span>
                      <div className="editor-controls">
                        {/* User presence indicators */}
                        <div className="user-presence">
                          {Array.from(editingUsers.keys()).map(userId => (
                            <div 
                              key={userId} 
                              className="user-indicator"
                              style={{ backgroundColor: getUserColor(userId) }}
                              title={`${userId} is editing`}
                            >
                              {userId.charAt(0).toUpperCase()}
                            </div>
                          ))}
                          {Array.from(typingUsers.keys()).map(userId => (
                            <div 
                              key={`typing-${userId}`} 
                              className="typing-indicator"
                              title={`${userId} is typing...`}
                            >
                              ✏️
                            </div>
                          ))}
                        </div>
                        <label className="checkbox-label">
                          <input
                            type="checkbox"
                            checked={autoSaveEnabled}
                            onChange={(e) => setAutoSaveEnabled(e.target.checked)}
                          />
                          Auto-save
                        </label>
                        {lastSaved && (
                          <span className="last-saved">
                            Last saved: {lastSaved.toLocaleTimeString()}
                          </span>
                        )}
                        {hasConflicts && (
                          <span className="conflict-warning" title="Potential conflicts detected">
                            ⚠️ Conflicts
                          </span>
                        )}
                        <span className="debug-info" style={{ fontSize: '10px', color: '#666' }}>
                          Cursors: {userCursors.size} | Users: {editingUsers.size}
                        </span>
                        <button 
                          onClick={handleFileSave}
                          className="btn-save"
                          disabled={loading}
                        >
                          💾 Save
                        </button>
                        <button 
                          onClick={() => {
                            console.log('Testing collaborative features...');
                            console.log('Socket connected:', socketService.isConnected());
                            console.log('Selected project:', selectedProject?.projectId);
                            console.log('Selected file:', selectedFile?._id);
                            console.log('User:', user?.email);
                            console.log('Room ID:', roomId);
                            
                            // Force reconnect if not connected
                            if (!socketService.isConnected()) {
                              console.log('Forcing socket reconnection...');
                              socketService.connect();
                            }
                            
                            // Test sending a cursor position
                            if (selectedProject && selectedFile && user) {
                              socketService.sendCursorPosition({
                                roomId,
                                projectId: selectedProject.projectId,
                                fileId: selectedFile._id,
                                userId: user.email || user.username,
                                position: 10,
                                selection: { start: 10, end: 10 }
                              });
                              console.log('Test cursor position sent');
                              
                              // Also simulate receiving a cursor from another user
                              setTimeout(() => {
                                console.log('Simulating cursor from another user...');
                                setUserCursors(prev => {
                                  const newCursors = new Map(prev);
                                  newCursors.set('test-user', {
                                    position: 25,
                                    selection: { start: 25, end: 25 },
                                    timestamp: Date.now()
                                  });
                                  console.log('Added test cursor:', newCursors);
                                  return newCursors;
                                });
                                
                                // Also simulate editing users
                                setEditingUsers(prev => {
                                  const newUsers = new Map(prev);
                                  newUsers.set('test-user', {
                                    selection: { start: 25, end: 30 },
                                    color: '#FF6B6B',
                                    timestamp: Date.now()
                                  });
                                  console.log('Added test editing user:', newUsers);
                                  return newUsers;
                                });
                                
                                // Simulate typing
                                setTypingUsers(prev => {
                                  const newTyping = new Map(prev);
                                  newTyping.set('test-user', {
                                    timestamp: Date.now(),
                                    fileId: selectedFile._id
                                  });
                                  console.log('Added test typing user:', newTyping);
                                  return newTyping;
                                });
                              }, 1000);
                            }
                          }}
                          className="btn-secondary"
                          style={{ fontSize: '12px', padding: '4px 8px' }}
                        >
                          🧪 Test
                        </button>
                        <button 
                          onClick={() => {
                            console.log('Force reconnecting socket...');
                            socketService.disconnect();
                            setTimeout(() => {
                              socketService.connect();
                              console.log('Socket reconnected');
                            }, 1000);
                          }}
                          className="btn-secondary"
                          style={{ fontSize: '12px', padding: '4px 8px' }}
                        >
                          🔄 Reconnect
                        </button>
                      </div>
                    </div>
                    <div className="editor-container">
                      <textarea
                        ref={textareaRef}
                        value={fileContent}
                        onChange={(e) => handleFileContentChange(e.target.value)}
                        onSelect={handleSelectionChange}
                        onKeyUp={handleCursorChange}
                        onMouseUp={handleCursorChange}
                        className="code-editor"
                        placeholder="Start coding..."
                        spellCheck={false}
                      />
                      {/* User cursors overlay */}
                      <div className="cursors-overlay">
                        {console.log('Rendering cursors:', Array.from(userCursors.entries()))}
                        {Array.from(userCursors.entries()).map(([userId, cursorInfo]) => {
                          // Calculate approximate cursor position
                          const lines = fileContent.split('\n');
                          let currentPos = 0;
                          let lineIndex = 0;
                          let charIndex = 0;
                          
                          for (let i = 0; i < lines.length; i++) {
                            if (currentPos + lines[i].length >= cursorInfo.position) {
                              lineIndex = i;
                              charIndex = cursorInfo.position - currentPos;
                              break;
                            }
                            currentPos += lines[i].length + 1; // +1 for newline
                          }
                          
                          const top = lineIndex * 21; // Approximate line height
                          const left = charIndex * 8.4; // Approximate character width
                          
                          return (
                            <div
                              key={userId}
                              className="user-cursor"
                              style={{
                                top: `${top}px`,
                                left: `${left}px`,
                                backgroundColor: getUserColor(userId)
                              }}
                              title={`${userId}'s cursor`}
                            >
                              <div className="cursor-line"></div>
                              <div className="cursor-label">{userId}</div>
                            </div>
                          );
                        })}
                      </div>
                    </div>
                  </div>
                )}
              </div>
            </div>
          )}


          {/* Compilation Status */}
          {compilationStatus === 'success' && previewUrl && (
            <div className="preview-section">
              <h3>👀 Live Preview</h3>
              <div className="preview-container">
                <div className="preview-wrapper">
                  {previewUrl.startsWith('data:') ? (
                    <iframe
                      src={previewUrl}
                      className="preview-iframe"
                      title="Project Preview"
                      onLoad={() => {
                        console.log('Data URL iframe loaded:', previewUrl);
                        console.log('Iframe content loaded successfully');
                      }}
                      onError={(e) => {
                        console.error('Data URL iframe error:', e);
                        console.log('Falling back to direct content display');
                      }}
                      style={{ 
                        width: '100%', 
                        height: '600px', 
                        border: '2px solid #007bff', 
                        borderRadius: '8px',
                        backgroundColor: '#fff',
                        boxShadow: '0 4px 12px rgba(0,0,0,0.1)'
                      }}
                    />
                  ) : (
                    <iframe
                      src={previewUrl}
                      className="preview-iframe"
                      title="Project Preview"
                      sandbox="allow-scripts allow-same-origin allow-forms allow-popups allow-top-navigation"
                      allow="camera; microphone; fullscreen"
                      onLoad={() => {
                        console.log('Preview iframe loaded:', previewUrl);
                        console.log('Iframe content loaded successfully');
                      }}
                      onError={(e) => {
                        console.error('Preview iframe error:', e);
                        console.log('Falling back to direct content display');
                      }}
                      style={{ 
                        width: '100%', 
                        height: '600px', 
                        border: '2px solid #007bff', 
                        borderRadius: '8px',
                        backgroundColor: '#fff',
                        boxShadow: '0 4px 12px rgba(0,0,0,0.1)'
                      }}
                    />
                  )}
                </div>
              </div>
              <div className="preview-actions">
                <button 
                  onClick={() => {
                    const iframe = document.querySelector('.preview-iframe');
                    if (iframe) {
                      iframe.src = iframe.src; // Force refresh
                    }
                  }}
                  className="btn-primary"
                >
                  🔄 Refresh Preview
                </button>
                <button 
                  onClick={() => window.open(previewUrl, '_blank')}
                  className="btn-secondary"
                >
                  🔗 Open in New Tab
                </button>
                <button 
                  onClick={() => setPreviewUrl('')}
                  className="btn-secondary"
                >
                  ❌ Close Preview
                </button>
              </div>
            </div>
          )}
        </div>

        {/* Code Paste Modal */}
        {showCodePaste && (
          <div className="code-paste-overlay">
            <div className="code-paste-modal">
              <div className="code-paste-header">
                <h3>📝 Paste Code</h3>
                <button 
                  onClick={() => setShowCodePaste(false)}
                  className="close-btn"
                >
                  ×
                </button>
              </div>

              <div className="code-paste-content">
                <div className="paste-form">
                  <div className="form-group">
                    <label>File Name:</label>
                    <input
                      type="text"
                      value={fileName}
                      onChange={(e) => setFileName(e.target.value)}
                      placeholder="Enter filename (e.g., script.js)"
                      className="form-input"
                    />
                  </div>

                  <div className="form-group">
                    <label>Language:</label>
                    <select
                      value={selectedLanguage}
                      onChange={(e) => handleLanguageChange(e.target.value)}
                      className="form-select"
                    >
                      <option value="nodejs">JavaScript</option>
                      <option value="css">CSS</option>
                      <option value="html">HTML</option>
                      <option value="json">JSON</option>
                    </select>
                  </div>

                  <div className="form-group">
                    <label>Code:</label>
                    <div className="code-editor-container">
                      {showSyntaxHighlighting ? (
                        <SyntaxHighlighter
                          language={selectedLanguage}
                          style={tomorrow}
                          className="code-highlighter"
                          showLineNumbers={true}
                          wrapLines={true}
                        >
                          {pastedCode || '// Paste your code here...'}
                        </SyntaxHighlighter>
                      ) : (
                        <textarea
                          value={pastedCode}
                          onChange={(e) => setPastedCode(e.target.value)}
                          placeholder="Paste your code here..."
                          className="code-textarea"
                          rows={15}
                        />
                      )}
                    </div>
                    <div className="editor-controls">
                      <label className="checkbox-label">
                        <input
                          type="checkbox"
                          checked={showSyntaxHighlighting}
                          onChange={(e) => setShowSyntaxHighlighting(e.target.checked)}
                        />
                        Syntax Highlighting
                      </label>
                    </div>
                  </div>

                  <div className="paste-actions">
                    <button 
                      onClick={savePastedCode}
                      className="btn-primary"
                      disabled={loading || !pastedCode.trim() || !fileName.trim()}
                    >
                      {loading ? '⏳ Saving...' : '💾 Save Code'}
                    </button>
                    <button 
                      onClick={() => setShowCodePaste(false)}
                      className="btn-secondary"
                    >
                      Cancel
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Scroll Progress Indicator */}
        <div className={`scroll-progress ${showSideScroller ? 'visible' : ''}`}>
          <div 
            className="scroll-progress-bar" 
            style={{ width: `${scrollProgress}%` }}
          ></div>
        </div>

        {/* Scroll to Top Button */}
        <button
          className={`scroll-to-top ${showScrollToTop ? 'visible' : ''}`}
          onClick={scrollToTop}
          title="Scroll to top"
        >
          ↑
        </button>

        {/* Side Scroller */}
        <div className={`side-scroller ${showSideScroller ? 'visible' : ''}`}>
          <button
            className="scroll-button"
            onClick={() => scrollToSection('project-section')}
            title="Go to Projects"
          >
            📁
          </button>
          <button
            className="scroll-button"
            onClick={() => scrollToSection('files-section')}
            title="Go to Files"
          >
            📄
          </button>
          <button
            className="scroll-button"
            onClick={scrollToPreview}
            title="Go to Preview"
          >
            👀
          </button>
        </div>
        </div>
      </div>
  );
}

export default CollaborativeEditor;
