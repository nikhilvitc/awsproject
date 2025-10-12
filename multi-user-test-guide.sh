#!/bin/bash

# Multi-User Collaborative Testing Guide
# This script provides comprehensive instructions for testing real-time collaboration

echo "👥 Multi-User Collaborative Testing Guide"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_tip() {
    echo -e "${PURPLE}[TIP]${NC} $1"
}

# Configuration
FRONTEND_URL="http://awsproject-frontend-1760218803.s3-website-us-east-1.amazonaws.com"
BACKEND_URL="https://awsproject-backend-prod.eba-fphuu5yq.us-east-1.elasticbeanstalk.com"

print_step "🔧 Enhanced Debugging Deployed!"
echo ""
echo "✅ Backend: Enhanced logging for room management and event broadcasting"
echo "✅ Frontend: Detailed console logging for all collaborative events"
echo "✅ Real-time: Better error handling and user feedback"
echo ""

print_step "🧪 Multi-User Testing Instructions"
echo ""
echo "🌐 Your Application URLs:"
echo "   Frontend: $FRONTEND_URL"
echo "   Room: $FRONTEND_URL/room/5862"
echo "   Backend: $BACKEND_URL"
echo ""

print_step "📱 Method 1: Multiple Browser Tabs (Easiest)"
echo ""
echo "1. Open your browser and go to: $FRONTEND_URL/room/5862"
echo "2. Log in with your account"
echo "3. Open the Collaborative Code Editor"
echo "4. Select a project and file"
echo ""
echo "5. Open a NEW browser tab (or incognito window)"
echo "6. Go to the same URL: $FRONTEND_URL/room/5862"
echo "7. Log in with a DIFFERENT account (or create a new one)"
echo "8. Open the Collaborative Code Editor"
echo "9. Select the SAME project and file"
echo ""
echo "10. Start typing in one tab - you should see live updates in the other!"
echo ""

print_step "🔍 What to Look For"
echo ""
echo "📊 In Browser Console (F12):"
echo "   Tab 1 (User A):"
echo "     - 'Sending content change to other users...'"
echo "     - 'Sending debounced content change: {...}'"
echo "     - 'Broadcasting to X other users in room 5862'"
echo ""
echo "   Tab 2 (User B):"
echo "     - '📥 Received file content update: {...}'"
echo "     - '✅ Processing file content update for current file from: userA@email.com'"
echo "     - '🎯 Received cursor update: {...}'"
echo "     - '✅ Processing cursor update for current file from: userA@email.com'"
echo ""
echo "👀 In the UI:"
echo "   - Debug counter should show 'Cursors: 1 | Users: 1'"
echo "   - Colored cursor should appear showing other user's position"
echo "   - User avatar should show other user's initial"
echo "   - Typing indicator should appear when other user types"
echo "   - Text should update in real-time as other user types"
echo ""

print_step "📱 Method 2: Multiple Devices/Browsers"
echo ""
echo "1. Use different devices (phone, tablet, computer)"
echo "2. Or use different browsers (Chrome, Firefox, Safari, Edge)"
echo "3. Follow the same steps as Method 1"
echo "4. Each device should show the other users' activity"
echo ""

print_step "🔧 Debugging Tools Available"
echo ""
echo "🧪 Test Button:"
echo "   - Click '🧪 Test' to simulate another user"
echo "   - This creates a fake 'test-user' cursor"
echo "   - Use this to verify the UI is working"
echo ""
echo "🔄 Reconnect Button:"
echo "   - Click '🔄 Reconnect' if WebSocket connection fails"
echo "   - This forces a fresh connection to the backend"
echo ""
echo "📊 Debug Counter:"
echo "   - Shows 'Cursors: X | Users: Y'"
echo "   - X = number of active cursors"
echo "   - Y = number of users in the room"
echo ""

print_step "🚨 Troubleshooting"
echo ""
echo "❌ If you see 'Cursors: 0 | Users: 0':"
echo "   1. Make sure both users are in the same room (5862)"
echo "   2. Make sure both users have selected the same project and file"
echo "   3. Check browser console for error messages"
echo "   4. Try clicking '🔄 Reconnect' button"
echo "   5. Hard refresh both tabs (Ctrl+F5)"
echo ""
echo "❌ If events are sent but not received:"
echo "   1. Check backend logs for 'Broadcasting to X other users'"
echo "   2. Verify both users are in the same WebSocket room"
echo "   3. Check if CORS is blocking the connection"
echo ""
echo "❌ If WebSocket connection fails:"
echo "   1. Check if backend is running: $BACKEND_URL"
echo "   2. Try the reconnect button"
echo "   3. Check browser console for connection errors"
echo ""

print_step "📋 Backend Logs to Check"
echo ""
echo "🔍 In backend logs, you should see:"
echo "   - 'Room 5862 now has 2 users' (when second user joins)"
echo "   - 'Broadcasting to 1 other users in room 5862'"
echo "   - 'File content broadcasted successfully to room 5862'"
echo "   - 'Cursor position broadcasted successfully'"
echo ""

print_step "🎯 Expected Behavior"
echo ""
echo "✅ Real-time collaboration should work like Google Sheets:"
echo "   - Multiple users can edit simultaneously"
echo "   - Cursors show where each user is editing"
echo "   - Text updates appear instantly for all users"
echo "   - User presence indicators show who's online"
echo "   - Typing indicators show who's actively editing"
echo ""

print_status "🎉 Ready to test multi-user collaboration!"
echo ""
echo "📋 Quick Test Checklist:"
echo "  □ Two users logged into same room"
echo "  □ Both users in Collaborative Code Editor"
echo "  □ Both users selected same project and file"
echo "  □ Browser console shows sending/receiving events"
echo "  □ UI shows cursors and user presence"
echo "  □ Text updates in real-time between users"
echo ""
echo "🚀 Start testing now! The collaborative features should work between multiple users."
