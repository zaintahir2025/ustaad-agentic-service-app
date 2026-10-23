#!/usr/bin/env bash
set -e

echo "=== Firestore Security Rules Verification ==="

if ! command -v java &> /dev/null; then
    echo "Java is required to run the Firestore emulator. Please install OpenJDK 11+."
    exit 1
fi

echo "Launching Firebase Emulator Suite for Firestore rules verification..."
firebase emulators:exec --only firestore "node scripts/test_firestore_rules.js"
