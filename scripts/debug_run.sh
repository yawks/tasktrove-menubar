#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

PROJECT="tasktrove-menubar.xcodeproj"
SCHEME="tasktrove-menubar"
CONFIG="Debug"
BUILD_DIR="$(pwd)/build/${CONFIG}"
APP_NAME="tasktrove-menubar.app"
BINARY="$BUILD_DIR/$APP_NAME/Contents/MacOS/tasktrove-menubar"

NO_BUILD=0

show_help() {
  cat <<EOF
Usage: $0 [--no-build]

Options:
  --no-build    Skip the build step and run the last built binary directly.
  --help        Show this help.

Builds the app in Debug configuration and runs it in the current terminal
so that all print() / stderr output appears in the console.

Press Ctrl+C to stop the app.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-build) NO_BUILD=1; shift ;;
    --help) show_help; exit 0 ;;
    *) echo "Unknown option: $1"; show_help; exit 1 ;;
  esac
done

# Kill any already-running instance so the new one can start cleanly
pkill -x "tasktrove-menubar" 2>/dev/null && echo "Stopped existing instance." || true

if [[ $NO_BUILD -eq 0 ]]; then
  echo "Building $SCHEME ($CONFIG)..."
  xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIG" \
    CONFIGURATION_BUILD_DIR="$BUILD_DIR" \
    build \
    | grep -E "^(Build|error:|warning:|note:|CompileSwift|Ld |✓)" \
    || true
fi

if [[ ! -f "$BINARY" ]]; then
  echo "Error: binary not found at $BINARY" >&2
  echo "Run without --no-build to compile first." >&2
  exit 2
fi

echo ""
echo "Launching $APP_NAME in debug mode — logs will appear below."
echo "Press Ctrl+C to quit."
echo "────────────────────────────────────────────────────────────"

exec "$BINARY"
