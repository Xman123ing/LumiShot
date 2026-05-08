#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build"
RELEASE_DIR="${PROJECT_ROOT}/release"
APP_NAME="LumiShot.app"
BIN_NAME="LumiShot"
DMG_NAME="LumiShot.dmg"
APP_BUNDLE_ID="com.lumishot.app"
ICON_SOURCE="${PROJECT_ROOT}/Assets/LumiShot.icns"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:-}"
SIGNING_IDENTITY="${CODESIGN_IDENTITY:--}"

mkdir -p "${RELEASE_DIR}"

xcodebuild \
  -workspace "${PROJECT_ROOT}/.swiftpm/xcode/package.xcworkspace" \
  -scheme LumiShot \
  -configuration Release \
  -destination "platform=macOS" \
  -derivedDataPath "${BUILD_DIR}" \
  build

APP_PATH="$(/usr/bin/find "${BUILD_DIR}" -path "*Release/${APP_NAME}" -print -quit || true)"
BIN_PATH="$(/usr/bin/find "${BUILD_DIR}" -path "*Release/${BIN_NAME}" -type f -perm -111 -print -quit || true)"

STAGE_DIR="${RELEASE_DIR}/dmg-stage"
rm -rf "${STAGE_DIR}"
mkdir -p "${STAGE_DIR}"
BUNDLE_DIR="${STAGE_DIR}/${APP_NAME}"

if [[ -n "${APP_PATH}" ]]; then
  cp -R "${APP_PATH}" "${BUNDLE_DIR}"
elif [[ -n "${BIN_PATH}" ]]; then
  mkdir -p "${BUNDLE_DIR}/Contents/MacOS" "${BUNDLE_DIR}/Contents/Resources"
  cp "${BIN_PATH}" "${BUNDLE_DIR}/Contents/MacOS/LumiShot"
  chmod +x "${BUNDLE_DIR}/Contents/MacOS/LumiShot"

  if [[ -f "${ICON_SOURCE}" ]]; then
    cp "${ICON_SOURCE}" "${BUNDLE_DIR}/Contents/Resources/LumiShot.icns"
  fi

  cat > "${BUNDLE_DIR}/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>LumiShot</string>
    <key>CFBundleIdentifier</key>
    <string>${APP_BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>LumiShot</string>
    <key>CFBundleDisplayName</key>
    <string>LumiShot</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
EOF

  if [[ -f "${ICON_SOURCE}" ]]; then
    cat >> "${BUNDLE_DIR}/Contents/Info.plist" <<'EOF'
    <key>CFBundleIconFile</key>
    <string>LumiShot</string>
EOF
  fi

  cat >> "${BUNDLE_DIR}/Contents/Info.plist" <<'EOF'
</dict>
</plist>
EOF
else
  echo "Release app or executable not found."
  exit 1
fi

PLIST_PATH="${BUNDLE_DIR}/Contents/Info.plist"
if [[ ! -f "${PLIST_PATH}" ]]; then
  echo "Info.plist not found at ${PLIST_PATH}"
  exit 1
fi

/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier ${APP_BUNDLE_ID}" "${PLIST_PATH}" || \
  /usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string ${APP_BUNDLE_ID}" "${PLIST_PATH}"

if [[ -f "${ICON_SOURCE}" ]]; then
  cp "${ICON_SOURCE}" "${BUNDLE_DIR}/Contents/Resources/LumiShot.icns"
  /usr/libexec/PlistBuddy -c "Set :CFBundleIconFile LumiShot" "${PLIST_PATH}" || \
    /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string LumiShot" "${PLIST_PATH}"
fi

if [[ "${SIGNING_IDENTITY}" == "-" ]]; then
  cat <<'EOF'
Warning: CODESIGN_IDENTITY is not set. Falling back to ad-hoc signing (-).
This build can be installed and run, but macOS may treat reinstall as a new app and ask for screen/audio permissions again.
For better permission persistence, package with a stable identity:
  CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./Scripts/package_dmg.sh
EOF
fi

echo "Signing app with identity: ${SIGNING_IDENTITY}"
codesign --force --deep --sign "${SIGNING_IDENTITY}" "${BUNDLE_DIR}"
codesign --verify --deep --strict "${BUNDLE_DIR}"

ln -s /Applications "${STAGE_DIR}/Applications"

FINAL_DMG_PATH="${RELEASE_DIR}/${DMG_NAME}"
rm -f "${FINAL_DMG_PATH}"

hdiutil create \
  -volname "LumiShot" \
  -srcfolder "${STAGE_DIR}" \
  -ov \
  -format UDZO \
  "${FINAL_DMG_PATH}"

echo "DMG created at ${FINAL_DMG_PATH}"
