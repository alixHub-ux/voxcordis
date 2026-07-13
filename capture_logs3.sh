#!/bin/bash
LOG=/home/carine/voxcordis/log_app2.txt
echo "=== LOGS VOXCORDIS ===" > "$LOG"
date >> "$LOG"
echo "" >> "$LOG"
timeout 180 adb logcat -v time | grep -v "ThermalManager\|crashlytics\|WVCdm\|PerformanceData\|ImeTracker\|InputMethodManager\|InputConnectionAdaptor\|InsetsController\|AssistStructure\|BLASTBufferQueue\|CoreBackPreview\|AidlConversionCpp" >> "$LOG" 2>&1
