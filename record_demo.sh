#!/bin/bash

# Demo Recording Script for GitIsland
# This script automates mouse movements to demo the notch app

# Reset the loading animation flag so it plays again
echo "Resetting loading animation flag..."
defaults delete com.saurabh.gitisland hasSeenContributionLoadingAnimation 2>/dev/null || true

# Check if cliclick is installed
if ! command -v cliclick &> /dev/null; then
    echo "cliclick is not installed. Installing via Homebrew..."
    if command -v brew &> /dev/null; then
        brew install cliclick
    else
        echo "Homebrew is not installed. Please install cliclick manually:"
        echo "  brew install cliclick"
        exit 1
    fi
fi

# Get screen dimensions (in points, not pixels - for Retina displays)
SCREEN_BOUNDS=$(osascript -e 'tell application "Finder" to get bounds of window of desktop')
SCREEN_WIDTH=$(echo $SCREEN_BOUNDS | cut -d',' -f3 | tr -d ' ')
SCREEN_HEIGHT=$(echo $SCREEN_BOUNDS | cut -d',' -f4 | tr -d ' ')

# Calculate notch position (center of screen, near top)
NOTCH_X=$((SCREEN_WIDTH / 2))
NOTCH_Y=15  # Just below the very top, in the notch area

# Click outside position (menu bar area, far left - avoids "Show Desktop" trigger)
OUTSIDE_X=50
OUTSIDE_Y=12

echo "Screen size (points): ${SCREEN_WIDTH}x${SCREEN_HEIGHT}"
echo "Notch position: ${NOTCH_X}, ${NOTCH_Y}"
echo ""
echo "Starting demo recording automation..."
echo "You have 5 seconds to start your screen recording!"
echo ""

# Countdown
for i in 5 4 3 2 1; do
    echo -ne "\rStarting in $i seconds... "
    sleep 1
done
echo -e "\rStarting now!          "

# Move to notch with visible animation (1 second movement)
echo "Moving to notch..."
cliclick -e 200 m:$NOTCH_X,$NOTCH_Y
sleep 0.2
echo "Clicking..."
cliclick c:$NOTCH_X,$NOTCH_Y

# Wait 4 seconds to show the expanded state
echo "Waiting 4 seconds..."
sleep 4

# Move away and click outside to close
echo "Moving away and clicking to close..."
cliclick m:$OUTSIDE_X,$OUTSIDE_Y
sleep 0.1
cliclick c:.

# Wait 2 seconds
echo "Waiting 2 seconds..."
sleep 2

# Move instantly back to notch and click to reopen
echo "Moving to notch and clicking to reopen..."
cliclick m:$NOTCH_X,$NOTCH_Y c:$NOTCH_X,$NOTCH_Y

echo ""
echo "Demo automation complete!"
