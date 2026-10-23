#!/usr/bin/env bash
set -e

echo "=== Firebase Cloud Function Local Verification ==="

if command -v firebase &> /dev/null; then
    echo "Firebase CLI detected. To start the emulator, run:"
    echo "  firebase emulators:start --only functions"
else
    echo "Firebase CLI not found. Install via: npm install -g firebase-tools"
fi

echo ""
echo "Running direct node test on Cloud Function handler..."
node functions/test_local.js
