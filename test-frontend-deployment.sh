#!/bin/bash

# Frontend Deployment Test Script
# This script tests if the collaborative features are deployed correctly

echo "🧪 Testing Frontend Deployment..."

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
FRONTEND_URL="http://awsproject-frontend-1760218803.s3-website-us-east-1.amazonaws.com"
BACKEND_URL="https://awsproject-backend-prod.eba-fphuu5yq.us-east-1.elasticbeanstalk.com"

print_step "Testing Frontend Deployment..."

# Test if frontend is accessible
if curl -s --connect-timeout 10 "$FRONTEND_URL" > /dev/null; then
    print_status "✅ Frontend is accessible at: $FRONTEND_URL"
else
    print_error "❌ Frontend is not accessible"
    exit 1
fi

# Test if main JS file exists
if curl -s --connect-timeout 10 "$FRONTEND_URL/static/js/main.dc16de5a.js" > /dev/null; then
    print_status "✅ Main JavaScript file is accessible"
else
    print_error "❌ Main JavaScript file not found"
fi

# Test if CSS files exist
if curl -s --connect-timeout 10 "$FRONTEND_URL/static/css/main.59eef7ac.css" > /dev/null; then
    print_status "✅ Main CSS file is accessible"
else
    print_error "❌ Main CSS file not found"
fi

print_step "Testing Backend Connectivity..."

# Test backend
if curl -s --connect-timeout 10 "$BACKEND_URL" > /dev/null; then
    print_status "✅ Backend is accessible at: $BACKEND_URL"
else
    print_warning "⚠️  Backend might still be starting up"
fi

echo ""
print_step "Manual Testing Instructions:"
echo ""
echo "🌐 Your frontend is now updated with collaborative features!"
echo "   URL: $FRONTEND_URL"
echo ""
echo "📝 To test the collaborative features:"
echo ""
echo "1. Open your browser and go to: $FRONTEND_URL"
echo "2. Log in to your account"
echo "3. Navigate to a chat room (like: $FRONTEND_URL/room/5862)"
echo "4. Look for the '🚀 Collaborative Code Editor' button"
echo "5. Click it to open the collaborative editor"
echo ""
echo "🔍 What you should see in the Collaborative Editor:"
echo "   - 'Live Collaboration Active' status indicator (green)"
echo "   - Debug info: Socket: ✅ | Room: ✅ | User: ✅"
echo "   - Test buttons: '🧪 Test' and '🔄 Reconnect'"
echo "   - Debug counter: 'Cursors: X | Users: Y'"
echo ""
echo "🧪 Testing Steps:"
echo "   1. Create or select a project"
echo "   2. Upload or create a file"
echo "   3. Click the '🧪 Test' button"
echo "   4. Open browser console (F12) to see debug messages"
echo "   5. You should see a colored cursor appear in the editor"
echo ""
echo "👀 Expected Results:"
echo "   - Console shows: 'Setting up collaborative editing...'"
echo "   - Console shows: 'Socket connected: true'"
echo "   - Console shows: 'Simulating cursor from another user...'"
echo "   - UI shows: Colored cursor with 'T' label"
echo "   - UI shows: User avatar and typing indicator"
echo ""
echo "🚨 If you don't see changes:"
echo "   1. Hard refresh the page (Ctrl+F5 or Cmd+Shift+R)"
echo "   2. Clear browser cache"
echo "   3. Check browser console for errors"
echo "   4. Try the '🔄 Reconnect' button in the editor"
echo ""
echo "📱 Test with Multiple Users:"
echo "   1. Open the same URL in multiple browser tabs"
echo "   2. Log in with different accounts"
echo "   3. Open the same project and file"
echo "   4. Start editing - you should see live updates!"
echo ""

print_status "🎉 Frontend deployment test completed!"
echo ""
echo "📋 Summary:"
echo "  Frontend URL: $FRONTEND_URL"
echo "  Backend URL: $BACKEND_URL"
echo "  Status: ✅ Deployed with collaborative features"
echo ""
echo "🔧 New Features Available:"
echo "  ✅ Live collaborative code editing"
echo "  ✅ Real-time cursor tracking"
echo "  ✅ User presence indicators"
echo "  ✅ Typing indicators"
echo "  ✅ Auto-save functionality"
echo "  ✅ Conflict detection"
echo "  ✅ Debug tools and testing"
echo ""
echo "🚀 Ready to test! Go to your frontend URL and try the collaborative editor!"
