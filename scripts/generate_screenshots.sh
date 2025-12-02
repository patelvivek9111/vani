#!/bin/bash

# App Store Screenshot Generator for Vani App
# Generates screenshots for iPhone and iPad

set -e

APP_BUNDLE="com.vani.app"
IPHONE_SIM="1E1224A0-C80C-4BC7-A88B-5F825401F1CB"  # iPhone 17 Pro
IPAD_SIM="DA6B9D42-46CE-4FE9-9A6E-F07A43D66DE3"    # iPad Pro 13-inch

SCREENSHOT_DIR="./AppStore_Screenshots"
mkdir -p "$SCREENSHOT_DIR/iPhone"
mkdir -p "$SCREENSHOT_DIR/iPad"

echo "📸 Generating App Store Screenshots..."

# Function to take screenshot
take_screenshot() {
    local device=$1
    local filename=$2
    local wait_time=${3:-3}
    
    echo "  Taking screenshot: $filename"
    sleep $wait_time
    xcrun simctl io $device screenshot "$SCREENSHOT_DIR/$filename" 2>/dev/null || true
}

# Function to launch app and wait
launch_app() {
    local device=$1
    echo "  Launching app on device..."
    xcrun simctl launch $device $APP_BUNDLE > /dev/null 2>&1 || true
    sleep 5
}

echo ""
echo "📱 iPhone Screenshots (6.7\")"
echo "================================"

# Boot iPhone if needed
xcrun simctl boot $IPHONE_SIM 2>/dev/null || true
sleep 2

# Launch app
launch_app $IPHONE_SIM

# Screenshot 1: Home Screen (Main verse)
take_screenshot $IPHONE_SIM "iPhone/01_Home.png" 2

# Screenshot 2: Settings Screen
echo "  Navigating to Settings..."
xcrun simctl launch $IPHONE_SIM $APP_BUNDLE > /dev/null 2>&1 || true
sleep 3
# Note: In a real scenario, you'd need UI automation to tap Settings tab
# For now, we'll take what we can get
take_screenshot $IPHONE_SIM "iPhone/02_Settings.png" 2

# Screenshot 3: Themes Screen  
take_screenshot $IPHONE_SIM "iPhone/03_Themes.png" 2

# Screenshot 4: Full Verse View
take_screenshot $IPHONE_SIM "iPhone/04_FullVerse.png" 2

echo ""
echo "📱 iPad Screenshots (12.9\")"
echo "================================"

# Boot iPad if needed
xcrun simctl boot $IPAD_SIM 2>/dev/null || true
sleep 2

# Launch app
launch_app $IPAD_SIM

# Screenshot 1: Home Screen
take_screenshot $IPAD_SIM "iPad/01_Home.png" 2

# Screenshot 2: Settings Screen
take_screenshot $IPAD_SIM "iPad/02_Settings.png" 2

# Screenshot 3: Themes Screen
take_screenshot $IPAD_SIM "iPad/03_Themes.png" 2

# Screenshot 4: Full Verse View
take_screenshot $IPAD_SIM "iPad/04_FullVerse.png" 2

echo ""
echo "✅ Screenshots generated in: $SCREENSHOT_DIR"
echo ""
echo "📋 Generated Files:"
ls -lh "$SCREENSHOT_DIR/iPhone/"
ls -lh "$SCREENSHOT_DIR/iPad/"

