import { io } from 'socket.io-client';
import { getSocketUrl, config } from '../config';

class SocketService {
  constructor() {
    this.socket = null;
    this.connected = false;
  }

  connect() {
    if (this.socket && this.socket.connected) {
      console.log('Socket already connected');
      return this.socket;
    }

    if (this.socket) {
      this.socket.disconnect();
    }

    const serverUrl = getSocketUrl();
    console.log('Connecting to Socket.IO server:', serverUrl);
    
    // Add error handling for connection failures
    if (!serverUrl || serverUrl.includes('localhost:8492')) {
      console.error('Invalid server URL detected:', serverUrl);
      return null;
    }
    
    this.socket = io(serverUrl, {
      transports: ['polling', 'websocket'], // Try polling first, then websocket
      upgrade: true,
      rememberUpgrade: false,
      timeout: config.socketTimeout || 20000,
      reconnection: true,
      reconnectionDelay: config.socketReconnectionDelay || 1000,
      reconnectionDelayMax: 5000,
      reconnectionAttempts: config.socketReconnectionAttempts || 5,
      maxReconnectionAttempts: config.socketReconnectionAttempts || 5,
      forceNew: true,
      autoConnect: true,
      secure: serverUrl.startsWith('https'), // Use secure connection only for HTTPS
      rejectUnauthorized: false,
      withCredentials: true
    });

    this.socket.on('connect', () => {
      console.log('✅ Connected to Socket.IO server');
      this.connected = true;
    });

    this.socket.on('disconnect', (reason) => {
      console.log('❌ Disconnected from Socket.IO server:', reason);
      this.connected = false;
      
      // Don't auto-reconnect on certain disconnect reasons
      if (reason === 'io server disconnect') {
        console.log('Server disconnected, manual reconnection needed');
      }
    });

    this.socket.on('connect_error', (error) => {
      console.error('🔥 Socket.IO connection error:', error.message);
      this.connected = false;
      
      // Log more details about the error
      console.error('Error details:', {
        message: error.message,
        description: error.description,
        context: error.context,
        type: error.type
      });
    });

    this.socket.on('reconnect', (attemptNumber) => {
      console.log('🔄 Reconnected to Socket.IO server after', attemptNumber, 'attempts');
      this.connected = true;
    });

    this.socket.on('reconnect_error', (error) => {
      console.error('🔄❌ Reconnection failed:', error.message);
    });

    this.socket.on('reconnect_failed', () => {
      console.error('🔄❌ All reconnection attempts failed');
      this.connected = false;
    });

    return this.socket;
  }

  disconnect() {
    if (this.socket) {
      this.socket.disconnect();
      this.socket = null;
      this.connected = false;
    }
  }

  // Join a chat room
  joinRoom(roomId, user) {
    if (this.socket) {
      this.socket.emit('join-room', { roomId, user });
    }
  }

  // Leave a chat room
  leaveRoom(roomId, user) {
    if (this.socket) {
      this.socket.emit('leave-room', { roomId, user });
    }
  }

  // Send a message with retry logic
  sendMessage(messageData) {
    if (this.socket && this.socket.connected) {
      try {
        this.socket.emit('send-message', messageData);
        return true;
      } catch (error) {
        console.error('Failed to send message via socket:', error);
        return false;
      }
    } else {
      console.warn('Socket not connected, cannot send message');
      return false;
    }
  }

  // Send typing indicator
  sendTyping(roomId, user, isTyping) {
    if (this.socket) {
      this.socket.emit('typing', { roomId, user, isTyping });
    }
  }

  // Listen for new messages
  onNewMessage(callback) {
    if (this.socket) {
      this.socket.on('new-message', callback);
    }
  }

  // Listen for user typing
  onUserTyping(callback) {
    if (this.socket) {
      this.socket.on('user-typing', callback);
    }
  }

  // Listen for user joined
  onUserJoined(callback) {
    if (this.socket) {
      this.socket.on('user-joined', callback);
    }
  }

  // Listen for user left
  onUserLeft(callback) {
    if (this.socket) {
      this.socket.on('user-left', callback);
    }
  }

  // Listen for room users
  onRoomUsers(callback) {
    if (this.socket) {
      this.socket.on('room-users', callback);
    }
  }

  // Listen for users count
  onUsersCount(callback) {
    if (this.socket) {
      this.socket.on('users-count', callback);
    }
  }

  // Listen for errors
  onError(callback) {
    if (this.socket) {
      this.socket.on('error', callback);
    }
  }

  // Remove all listeners
  removeAllListeners() {
    if (this.socket) {
      this.socket.removeAllListeners();
    }
  }

  // Check if connected
  isConnected() {
    return this.connected && this.socket && this.socket.connected;
  }

  // Generic event listener
  on(event, callback) {
    if (this.socket) {
      this.socket.on(event, callback);
    } else {
      console.warn('Socket not available, cannot listen to event:', event);
    }
  }

  // Generic event emitter
  emit(event, data) {
    if (this.socket && this.socket.connected) {
      try {
        this.socket.emit(event, data);
        return true;
      } catch (error) {
        console.error('Failed to emit event:', event, error);
        return false;
      }
    } else {
      console.warn('Socket not connected, cannot emit event:', event);
      return false;
    }
  }

  // Remove specific event listener
  off(event, callback) {
    if (this.socket) {
      this.socket.off(event, callback);
    }
  }

  // === LIVE COLLABORATIVE EDITING METHODS ===

  // Send file content changes for live editing
  sendFileContentChange(data) {
    if (this.socket && this.socket.connected) {
      try {
        this.socket.emit('file-content-change', data);
        return true;
      } catch (error) {
        console.error('Failed to send file content change:', error);
        return false;
      }
    } else {
      console.warn('Socket not connected, cannot send file content change');
      return false;
    }
  }

  // Send cursor position updates
  sendCursorPosition(data) {
    if (this.socket && this.socket.connected) {
      try {
        this.socket.emit('cursor-position', data);
        return true;
      } catch (error) {
        console.error('Failed to send cursor position:', error);
        return false;
      }
    } else {
      console.warn('Socket not connected, cannot send cursor position');
      return false;
    }
  }

  // Send user selection/highlighting
  sendUserSelection(data) {
    if (this.socket && this.socket.connected) {
      try {
        this.socket.emit('user-selection', data);
        return true;
      } catch (error) {
        console.error('Failed to send user selection:', error);
        return false;
      }
    } else {
      console.warn('Socket not connected, cannot send user selection');
      return false;
    }
  }

  // Join file editing session
  joinFileEdit(data) {
    if (this.socket && this.socket.connected) {
      try {
        this.socket.emit('join-file-edit', data);
        return true;
      } catch (error) {
        console.error('Failed to join file edit:', error);
        return false;
      }
    } else {
      console.warn('Socket not connected, cannot join file edit');
      return false;
    }
  }

  // Leave file editing session
  leaveFileEdit(data) {
    if (this.socket && this.socket.connected) {
      try {
        this.socket.emit('leave-file-edit', data);
        return true;
      } catch (error) {
        console.error('Failed to leave file edit:', error);
        return false;
      }
    } else {
      console.warn('Socket not connected, cannot leave file edit');
      return false;
    }
  }

  // Send code typing indicator
  sendCodeTyping(data) {
    if (this.socket && this.socket.connected) {
      try {
        this.socket.emit('code-typing', data);
        return true;
      } catch (error) {
        console.error('Failed to send code typing:', error);
        return false;
      }
    } else {
      console.warn('Socket not connected, cannot send code typing');
      return false;
    }
  }

  // === EVENT LISTENERS FOR COLLABORATIVE EDITING ===

  // Listen for file content updates
  onFileContentUpdated(callback) {
    if (this.socket) {
      this.socket.on('file-content-updated', callback);
    }
  }

  // Listen for cursor position updates
  onUserCursorUpdated(callback) {
    if (this.socket) {
      this.socket.on('user-cursor-updated', callback);
    }
  }

  // Listen for user selection updates
  onUserSelectionUpdated(callback) {
    if (this.socket) {
      this.socket.on('user-selection-updated', callback);
    }
  }

  // Listen for user editing file
  onUserEditingFile(callback) {
    if (this.socket) {
      this.socket.on('user-editing-file', callback);
    }
  }

  // Listen for user stopped editing file
  onUserStoppedEditingFile(callback) {
    if (this.socket) {
      this.socket.on('user-stopped-editing-file', callback);
    }
  }

  // Listen for code typing indicator
  onUserCodeTyping(callback) {
    if (this.socket) {
      this.socket.on('user-code-typing', callback);
    }
  }
}

// Create singleton instance
const socketService = new SocketService();
export default socketService;
