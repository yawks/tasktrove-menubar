#!/usr/bin/env bash
set -euo pipefail

# build_release_dmg.sh
# Small helper script to build the Xcode project in Release and create a compressed DMG.
# Usage examples:
#  ./scripts/build_release_dmg.sh            # perform build and create DMG to ~/Desktop/TaskTroveMenuBar.dmg
#  ./scripts/build_release_dmg.sh --dry-run # show commands that would run without executing them
#  ./scripts/build_release_dmg.sh --no-clean --dmg-name MyApp --output ./dist/MyApp.dmg
#  CODESIGN_ID="Developer ID Application: Name (TEAMID)" ./scripts/build_release_dmg.sh --sign

PROJECT="tasktrove-menubar.xcodeproj"
SCHEME="tasktrove-menubar"
CONFIG="Release"
BUILD_DIR="$(pwd)/build/${CONFIG}"
APP_NAME="tasktrove-menubar.app"
APP_BUNDLE_PATH="$BUILD_DIR/$APP_NAME"
DMG_NAME="${DMG_NAME:-TaskTroveMenuBar}"
DMG_OUTPUT="${DMG_OUTPUT:-$HOME/Desktop/${DMG_NAME}.dmg}"
STAGING_DIR="$(pwd)/dist/staging"

DRY_RUN=0
CLEAN=1
CODESIGN_ID="${CODESIGN_ID:-}"

show_help() {
  cat <<EOF
Usage: $0 [--dry-run] [--no-clean] [--dmg-name NAME] [--output PATH] [--sign]

Options:
  --dry-run         Print commands without executing them.
  --no-clean        Skip 'xcodebuild clean' step.
  --dmg-name NAME   Volume name used for the DMG (default: TaskTroveMenuBar).
  --output PATH     Output path for the DMG (default: ~/Desktop/<name>.dmg).
  --sign            If CODESIGN_ID is set in environment, sign the .app in staging.
  --help            Show this help.

Environment:
  CODESIGN_ID       Code signing identity, e.g. "Developer ID Application: Name (TEAMID)".

Examples:
  $0
  CODESIGN_ID="Developer ID Application: Foo (TEAMID)" $0 --sign --dmg-name MyApp
  $0 --dry-run
EOF
}

run() {
  echo "+ $*"
  if [[ $DRY_RUN -eq 0 ]]; then
    eval "$@"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --no-clean) CLEAN=0; shift ;;
    --dmg-name) DMG_NAME="$2"; DMG_OUTPUT="${DMG_OUTPUT:-$HOME/Desktop/${DMG_NAME}.dmg}"; shift 2 ;;
    --output) DMG_OUTPUT="$2"; shift 2 ;;
    --sign) # noop here: reading CODESIGN_ID from env
      shift ;;
    --help) show_help; exit 0 ;;
    *) echo "Unknown option: $1"; show_help; exit 1 ;;
  esac
done

echo "Project: $PROJECT"
echo "Scheme:  $SCHEME"
echo "Config:  $CONFIG"
echo "Build dir: $BUILD_DIR"
echo "App bundle: $APP_BUNDLE_PATH"
echo "DMG output: $DMG_OUTPUT"
echo

if [[ $CLEAN -eq 1 ]]; then
  run xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration "$CONFIG" CONFIGURATION_BUILD_DIR="$BUILD_DIR" clean
fi

run xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration "$CONFIG" CONFIGURATION_BUILD_DIR="$BUILD_DIR" build

if [[ $DRY_RUN -eq 0 && ! -d "$APP_BUNDLE_PATH" ]]; then
  echo "Error: built app not found at $APP_BUNDLE_PATH" >&2
  exit 2
fi

run rm -rf "$STAGING_DIR"
run mkdir -p "${STAGING_DIR}"
run cp -R "$APP_BUNDLE_PATH" "$STAGING_DIR/"

if [[ -n "$CODESIGN_ID" ]]; then
  echo "Codesigning with identity: $CODESIGN_ID"
  run codesign --deep --force --timestamp --sign "$CODESIGN_ID" "$STAGING_DIR/$APP_NAME"
fi

echo "Creating DMG..."
run hdiutil create -volname "$DMG_NAME" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_OUTPUT"

if [[ $DRY_RUN -eq 0 ]]; then
  echo "Done. DMG written to: $DMG_OUTPUT"
else
  echo "Dry-run: no DMG created. Re-run without --dry-run to execute." 
fi

exit 0
