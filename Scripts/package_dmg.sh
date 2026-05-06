#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build"
RELEASE_DIR="${PROJECT_ROOT}/release"
APP_NAME="LumiShot.app"
BIN_NAME="LumiShotApp"
DMG_NAME="LumiShot.dmg"

mkdir -p "${RELEASE_DIR}"

xcodebuild \
  -scheme LumiShotApp \
  -configuration Release \
  -destination "platform=macOS" \
  -derivedDataPath "${BUILD_DIR}" \
  build

APP_PATH="$(/usr/bin/find "${BUILD_DIR}" -path "*Release/${APP_NAME}" -print -quit || true)"
BIN_PATH="$(/usr/bin/find "${BUILD_DIR}" -path "*Release/${BIN_NAME}" -type f -perm -111 -print -quit || true)"

STAGE_DIR="${RELEASE_DIR}/dmg-stage"
rm -rf "${STAGE_DIR}"
mkdir -p "${STAGE_DIR}"

if [[ -n "${APP_PATH}" ]]; then
  cp -R "${APP_PATH}" "${STAGE_DIR}/${APP_NAME}"
elif [[ -n "${BIN_PATH}" ]]; then
  cp "${BIN_PATH}" "${STAGE_DIR}/LumiShot"
  chmod +x "${STAGE_DIR}/LumiShot"
else
  echo "Release app or executable not found."
  exit 1
fi

ln -s /Applications "${STAGE_DIR}/Applications"

hdiutil create \
  -volname "LumiShot" \
  -srcfolder "${STAGE_DIR}" \
  -ov \
  -format UDZO \
  "${RELEASE_DIR}/${DMG_NAME}"

echo "DMG created at ${RELEASE_DIR}/${DMG_NAME}"
