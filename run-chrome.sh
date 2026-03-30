#!/bin/bash

# Start Xvfb if not running
if ! pgrep -x Xvfb > /dev/null; then
    echo "Starting Xvfb..."
    Xvfb :99 -ac -screen 0 1280x1024x24 &
    sleep 2
fi

# Set display
export DISPLAY=:99

# Start D-Bus if not running
if ! pgrep -x dbus-daemon > /dev/null; then
    echo "Starting D-Bus..."
    eval `dbus-launch --sh-syntax`
    export DBUS_SESSION_BUS_ADDRESS
    sleep 1
fi

# Run Chrome with proper flags for container environment
echo "Starting Google Chrome..."
google-chrome-stable \
    --no-sandbox \
    --disable-dev-shm-usage \
    --disable-gpu \
    --disable-software-rasterizer \
    --disable-setuid-sandbox \
    --disable-features=VizDisplayCompositor \
    --remote-debugging-port=9222 \
    "$@"