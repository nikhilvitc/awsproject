#!/bin/bash

# Collaborative Features Test Script
# This script helps you test the collaborative editing features

echo "🧪 Testing Collaborative Features on AWS..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Configuration
BACKEND_URL="https://awsproject-backend-prod.eba-fphuu5yq.us-east-1.elasticbeanstalk.com"

print_step "Testing AWS Backend..."

# Test basic connectivity
if curl -s --connect-timeout 10 "$BACKEND_URL" > /dev/null; then
    print_status "✅ Backend is accessible"
else
    print_error "❌ Backend is not accessible"
    print_warning "The backend might still be starting up. Wait a few minutes and try again."
fi

echo ""
print_step "Manual Testing Instructions:"
echo ""
echo "🌐 To test collaborative features:"
echo ""
echo "1. Open your frontend application in your browser"
echo "2. Log in to your account"
echo "3. Navigate to a chat room"
echo "4. Click the '🚀 Collaborative Code Editor' button"
echo "5. Look for these indicators:"
echo "   - 'Live Collaboration Active' status (should be green)"
echo "   - Debug info showing: Socket: ✅ | Room: ✅ | User: ✅"
echo ""
echo "6. Create or select a project"
echo "7. Upload or create a file"
echo "8. Click the '🧪 Test' button in the editor"
echo "9. Check the browser console (F12) for debug messages"
echo ""
echo "🔍 What to look for in the console:"
echo "   - 'Setting up collaborative editing...'"
echo "   - 'Socket connected: true'"
echo "   - 'Simulating cursor from another user...'"
echo "   - 'Added test cursor: Map {...}'"
echo ""
echo "👀 What to see in the UI:"
echo "   - Colored cursor appearing in the editor"
echo "   - User avatar showing 'T' (for test-user)"
echo "   - Typing indicator (✏️)"
echo "   - Debug counter showing 'Cursors: 1 | Users: 1'"
echo ""
echo "🚨 If nothing appears:"
echo "   1. Check browser console for errors"
echo "   2. Try clicking '🔄 Reconnect' button"
echo "   3. Refresh the page and try again"
echo "   4. Check if your frontend is using HTTPS"
echo ""
echo "📱 Test with multiple users:"
echo "   1. Open your app in multiple browser tabs"
echo "   2. Log in with different accounts"
echo "   3. Open the same project and file"
echo "   4. Start editing - you should see live updates!"
echo ""

print_status "🎉 Ready to test! Follow the instructions above."
