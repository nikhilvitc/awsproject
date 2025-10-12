#!/bin/bash

# Comprehensive Debugging Guide for Collaborative Features
# This script provides step-by-step debugging instructions

echo "🔍 Comprehensive Debugging Guide for Collaborative Features"
echo "========================================================="

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
echo "✅ Frontend: Comprehensive console logging with emojis"
echo "✅ Backend: Room size tracking and event broadcasting logs"
echo "✅ Real-time: Detailed error handling and validation"
echo ""

print_step "🧪 Step-by-Step Debugging Process"
echo ""
echo "🌐 Go to: $FRONTEND_URL/room/5862"
echo ""

print_step "1️⃣ Open Browser Console (F12)"
echo ""
echo "📊 Look for these console messages:"
echo "   🔍 'File selected: {...}' - When you click a file"
echo "   📝 'File content changed: X characters' - When you type"
echo "   🎯 'Cursor position changed: X' - When you move cursor"
echo "   📤 'Sending content change to other users...' - When sending events"
echo "   ❌ 'Cannot send content change:' - If something is missing"
echo ""

print_step "2️⃣ Test File Selection"
echo ""
echo "1. Open Collaborative Code Editor"
echo "2. Select a project (like 'ffk' or 'meow')"
echo "3. Click on a file (like 'index.html')"
echo "4. Check console for:"
echo "   - '🔍 File selected: {...}'"
echo "   - 'File ID: [some-id]' (should NOT be undefined)"
echo "   - 'Joining new file editing session...'"
echo ""

print_step "3️⃣ Test Content Changes"
echo ""
echo "1. Start typing in the editor"
echo "2. Check console for:"
echo "   - '📝 File content changed: X characters'"
echo "   - '📁 Selected file ID: [some-id]' (should NOT be undefined)"
echo "   - '📤 Sending content change to other users...'"
echo "   - 'Sending debounced content change: {...}'"
echo ""

print_step "4️⃣ Test Cursor Movement"
echo ""
echo "1. Click and move your cursor in the editor"
echo "2. Check console for:"
echo "   - '🎯 Cursor position changed: X'"
echo "   - '📁 Selected file ID: [some-id]' (should NOT be undefined)"
echo "   - '📤 Sending cursor position...'"
echo ""

print_step "5️⃣ Test the Test Button"
echo ""
echo "1. Click the '🧪 Test' button"
echo "2. Check console for:"
echo "   - 'Testing collaborative features...'"
echo "   - 'Simulating cursor from another user...'"
echo "   - 'Added test cursor: Map {...}'"
echo "3. Check UI for:"
echo "   - Debug counter should show 'Cursors: 1 | Users: 1'"
echo "   - Colored cursor should appear"
echo ""

print_step "🚨 Common Issues and Solutions"
echo ""
echo "❌ Issue: 'File ID: undefined'"
echo "   Solution: File object doesn't have _id property"
echo "   Check: File structure in console when selecting"
echo ""
echo "❌ Issue: 'Cannot send content change'"
echo "   Solution: Missing selectedFile, selectedProject, or user"
echo "   Check: All three should be truthy in console"
echo ""
echo "❌ Issue: 'Socket: ❌' in UI"
echo "   Solution: WebSocket connection failed"
echo "   Try: Click '🔄 Reconnect' button"
echo ""
echo "❌ Issue: 'Cursors: 0 | Users: 0'"
echo "   Solution: No collaborative events are being sent/received"
echo "   Check: Console for error messages"
echo ""

print_step "📋 Backend Logs to Check"
echo ""
echo "🔍 In backend logs, you should see:"
echo "   - 'Room 5862 now has 1 users' (when you join)"
echo "   - 'File content change in room 5862, project X, file [file-id]'"
echo "   - 'Broadcasting to 0 other users in room 5862'"
echo "   - 'File content broadcasted successfully to room 5862'"
echo ""

print_step "🎯 Expected Console Output"
echo ""
echo "✅ When everything works, you should see:"
echo ""
echo "🔍 File selected: {_id: 'abc123', fileName: 'index.html', ...}"
echo "File ID: abc123"
echo "Joining new file editing session..."
echo ""
echo "📝 File content changed: 150 characters"
echo "📁 Selected file ID: abc123"
echo "📤 Sending content change to other users..."
echo "Sending debounced content change: {roomId: '5862', projectId: '...', fileId: 'abc123', ...}"
echo ""
echo "🎯 Cursor position changed: 25"
echo "📁 Selected file ID: abc123"
echo "📤 Sending cursor position..."
echo ""

print_step "🔧 Debugging Commands"
echo ""
echo "📊 Check backend logs:"
echo "   cd backend && tail -f .elasticbeanstalk/logs/latest/i-*/var/log/web.stdout.log"
echo ""
echo "🌐 Test backend connectivity:"
echo "   curl -s '$BACKEND_URL'"
echo ""
echo "🔍 Check frontend deployment:"
echo "   curl -s '$FRONTEND_URL' | grep -o 'main.*\.js'"
echo ""

print_status "🎉 Ready to debug! Follow the steps above."
echo ""
echo "📋 Debug Checklist:"
echo "  □ Browser console open (F12)"
echo "  □ File selection shows proper file ID"
echo "  □ Content changes show sending events"
echo "  ✅ Cursor movement shows sending events"
echo "  ✅ Test button creates fake cursor"
echo "  ✅ UI shows 'Cursors: 1 | Users: 1'"
echo ""
echo "🚀 Start debugging now! The enhanced logging will show exactly what's happening."
