#!/bin/bash
# Script de capture des logs ADB pour Voxcordis
# Usage: ./capture_logs.sh [fichier_sortie]
# Par défaut : /tmp/voxcordis_logs_$(date +%Y%m%d_%H%M%S).txt

APP_PACKAGE="com.example.voxcordis_app"
OUTPUT_FILE="${1:-/tmp/voxcordis_logs_$(date +%Y%m%d_%H%M%S).txt}"

echo "=== Capture des logs Voxcordis ===" > "$OUTPUT_FILE"
echo "Date: $(date)" >> "$OUTPUT_FILE"
echo "Appareil: $(adb devices -l | grep device | head -1)" >> "$OUTPUT_FILE"
echo "APK Version: $(adb shell dumpsys package $APP_PACKAGE | grep versionName)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Arrêter et relancer l'app proprement
echo "Redémarrage de l'app..." | tee -a "$OUTPUT_FILE"
adb shell am force-stop $APP_PACKAGE
sleep 2
adb shell am start -n ${APP_PACKAGE}/.MainActivity
sleep 5

echo "" >> "$OUTPUT_FILE"
echo "=== Navigation vers l'écran de login ===" >> "$OUTPUT_FILE"
adb shell input tap 360 1464
sleep 2

echo "" >> "$OUTPUT_FILE"
echo "=== Début capture logs Flutter ===" >> "$OUTPUT_FILE"

# Lancer la capture en arrière-plan
LOGCAT_PID=""
adb logcat -v brief --pid=$(adb shell ps | grep $APP_PACKAGE | awk '{print $2}') \
  | tee -a "$OUTPUT_FILE" &
LOGCAT_PID=$!

echo "Capture PID: $LOGCAT_PID" >> "$OUTPUT_FILE"
echo "Logs écrits dans: $OUTPUT_FILE"
echo ""
echo "Interagissez avec l'app, puis appuyez sur Ctrl+C pour arrêter la capture."
echo ""

# Attendre
wait $LOGCAT_PID 2>/dev/null
