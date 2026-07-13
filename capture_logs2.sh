#!/bin/bash
LOG=/home/carine/voxcordis/log_app.txt
echo "=== LOGS VOXCORDIS ===" > "$LOG"
date >> "$LOG"
echo "Backend: http://localhost:7860 (local)" >> "$LOG"
echo "" >> "$LOG"

# Capture logs for 5 minutes then stop
timeout 300 adb logcat --pid=$(adb shell pidof com.example.voxcordis_app) >> "$LOG" 2>&1
