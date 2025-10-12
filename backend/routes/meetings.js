const express = require('express');
const router = express.Router();
const MeetingService = require('../services/MeetingService');
const ChatRoomService = require('../services/ChatRoomService');

// Create service instances
const meetingService = new MeetingService();
const chatRoomService = new ChatRoomService();

// Create a new meeting
router.post('/create', async (req, res) => {
  try {
    console.log('Meeting creation request received:', req.body);
    
    const {
      title,
      description,
      roomId,
      organizer,
      participants,
      scheduledTime,
      duration,
      settings,
      isRecurring,
      recurringSettings
    } = req.body;

    // Validate required fields
    if (!title || !roomId || !organizer || !scheduledTime) {
      console.log('Validation failed - missing required fields:', { title, roomId, organizer, scheduledTime });
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: title, roomId, organizer, scheduledTime'
      });
    }

    console.log('Creating meeting with data:', {
      title,
      roomId,
      organizer,
      participants: participants?.length || 0,
      scheduledTime: new Date(scheduledTime)
    });

    const meetingData = {
      title,
      description,
      roomId,
      organizer,
      participants: participants || [],
      scheduledTime,
      duration: duration || 60,
      settings: {
        allowScreenShare: settings?.allowScreenShare !== false,
        allowChat: settings?.allowChat !== false,
        requirePassword: settings?.requirePassword || false,
        password: settings?.password || '',
        maxParticipants: settings?.maxParticipants || 50
      },
      isRecurring: isRecurring || false,
      recurringSettings: recurringSettings || {}
    };

    const meeting = await meetingService.createMeeting(meetingData);
    console.log('Meeting created successfully:', meeting.meetingId);

    res.status(201).json({
      success: true,
      message: 'Meeting created successfully',
      meeting: {
        id: meeting.meetingId,
        meetingId: meeting.meetingId,
        title: meeting.title,
        description: meeting.description,
        roomId: meeting.roomId,
        organizer: meeting.organizer,
        participants: meeting.participants,
        scheduledTime: meeting.scheduledTime,
        duration: meeting.duration,
        meetingUrl: `/meet/${meeting.meetingId}`,
        settings: meeting.settings,
        status: meeting.status,
        createdAt: meeting.createdAt
      }
    });
  } catch (error) {
    console.error('Error creating meeting:', error);
    res.status(500).json({
      success: false,
      message: 'Error creating meeting',
      error: error.message
    });
  }
});

// Get meetings for a specific room
router.get('/room/:roomId', async (req, res) => {
  try {
    const { roomId } = req.params;
    const { status } = req.query;

    console.log('Fetching meetings for room:', roomId, 'with status filter:', status);

    let query = { roomId };
    if (status) {
      query.status = status;
    }

    const meetings = await meetingService.getMeetingsByRoom(roomId, status);

    console.log('Found meetings:', meetings.length);

    // Return meetings directly as array (not wrapped in success object)
    res.json(meetings);
  } catch (error) {
    console.error('Error fetching meetings:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching meetings',
      error: error.message
    });
  }
});

// Get meeting by ID
router.get('/:meetingId', async (req, res) => {
  try {
    const { meetingId } = req.params;

    const meeting = await meetingService.getMeetingById(meetingId);

    if (!meeting) {
      return res.status(404).json({
        success: false,
        message: 'Meeting not found'
      });
    }

    res.json({
      success: true,
      meeting
    });
  } catch (error) {
    console.error('Error fetching meeting:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching meeting',
      error: error.message
    });
  }
});

// Update meeting status
router.patch('/:meetingId/status', async (req, res) => {
  try {
    const { meetingId } = req.params;
    const { status } = req.body;

    if (!['scheduled', 'active', 'completed', 'cancelled'].includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid status. Must be one of: scheduled, active, completed, cancelled'
      });
    }

    const meeting = await meetingService.updateMeetingStatus(meetingId, status);

    if (!meeting) {
      return res.status(404).json({
        success: false,
        message: 'Meeting not found'
      });
    }

    res.json({
      success: true,
      message: 'Meeting status updated successfully',
      meeting
    });
  } catch (error) {
    console.error('Error updating meeting status:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating meeting status',
      error: error.message
    });
  }
});

// Delete meeting
router.delete('/:meetingId', async (req, res) => {
  try {
    const { meetingId } = req.params;

    const meeting = await meetingService.deleteMeeting(meetingId);

    if (!meeting) {
      return res.status(404).json({
        success: false,
        message: 'Meeting not found'
      });
    }

    res.json({
      success: true,
      message: 'Meeting deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting meeting:', error);
    res.status(500).json({
      success: false,
      message: 'Error deleting meeting',
      error: error.message
    });
  }
});

// Get upcoming meetings for a user
router.get('/user/:organizer/upcoming', async (req, res) => {
  try {
    const { organizer } = req.params;

    const meetings = await meetingService.getUpcomingMeetings(organizer);

    res.json({
      success: true,
      meetings
    });
  } catch (error) {
    console.error('Error fetching upcoming meetings:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching upcoming meetings',
      error: error.message
    });
  }
});


// Debug endpoint to list all meetings
router.get('/debug/all', async (req, res) => {
  try {
    const meetings = await meetingService.getAllMeetings();
    console.log('All meetings in database:', meetings.length);
    res.json({
      success: true,
      count: meetings.length,
      meetings: meetings.map(m => ({
        id: m._id,
        meetingId: m.meetingId,
        title: m.title,
        roomId: m.roomId,
        organizer: m.organizer,
        scheduledTime: m.scheduledTime,
        status: m.status,
        createdAt: m.createdAt
      }))
    });
  } catch (error) {
    console.error('Error fetching all meetings:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching meetings',
      error: error.message
    });
  }
});

// Send meeting notification to room participants
router.post('/:meetingId/notify', async (req, res) => {
  try {
    const { meetingId } = req.params;
    const { type, organizer, message } = req.body;

    console.log('Meeting notification request:', { meetingId, type, organizer, message });

    // Find the meeting
    const meeting = await meetingService.getMeetingById(meetingId);
    if (!meeting) {
      return res.status(404).json({ success: false, message: 'Meeting not found' });
    }

    // Find the associated room
    const room = await ChatRoom.findOne({ name: meeting.roomId });
    if (!room) {
      return res.status(404).json({ success: false, message: 'Room not found' });
    }

    // Create notification message
    const notificationMessage = {
      _id: new Date().getTime().toString(),
      text: message || `${organizer} has started a video call`,
      user: {
        username: organizer,
        email: organizer,
        name: organizer,
        color: '#007bff'
      },
      timestamp: new Date().toISOString(),
      createdAt: new Date().toISOString(),
      room: meeting.roomId,
      isNotification: true,
      notificationType: 'meeting_started',
      meetingId: meetingId,
      meetingUrl: `/meet/${meetingId}`
    };

    // Here you would typically send this via Socket.IO to all room participants
    // For now, we'll just log it
    console.log('Meeting notification created:', notificationMessage);

    res.json({
      success: true,
      message: 'Notification sent successfully',
      notification: notificationMessage
    });
  } catch (error) {
    console.error('Error sending meeting notification:', error);
    res.status(500).json({
      success: false,
      message: 'Error sending notification',
      error: error.message
    });
  }
});

module.exports = router;
