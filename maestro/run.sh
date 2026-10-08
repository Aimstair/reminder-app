#!/usr/bin/env bash
# Runs the Maestro suite on the EMULATOR ONLY. Flows use clearState (wipes app data), so this
# refuses any physical device. Usage: maestro/run.sh [flow.yaml]   (default: whole suite)
set -euo pipefail
export MSYS_NO_PATHCONV=1
ADB="${ANDROID_HOME:-$LOCALAPPDATA/Android/Sdk}/platform-tools/adb.exe"
DEVICE=$("$ADB" devices | awk '/^emulator-[0-9]+\tdevice$/ {print $1; exit}')
if [ -z "$DEVICE" ]; then echo "No running emulator — start one first (emulator -avd ...)." >&2; exit 1; fi
cd "$(dirname "$0")"
export JAVA_HOME="${JAVA_HOME:-/c/Program Files/Android/Android Studio/jbr}"
cmd /c "%USERPROFILE%\.maestro\bin\maestro.bat --device $DEVICE test ${1:-.}"
