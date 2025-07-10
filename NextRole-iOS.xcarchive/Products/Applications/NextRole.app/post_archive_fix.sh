#!/bin/bash

# This script runs after archive to ensure ApplicationProperties are present
# Only run for archive builds
if [ "${ACTION}" != "install" ]; then
    exit 0
fi

# Only run for iOS builds
if [ "${PLATFORM_NAME}" != "iphoneos" ]; then
    exit 0
fi

echo "🔧 Fixing archive ApplicationProperties..."

# Get the archive path
ARCHIVE_PATH="${ARCHIVE_PATH:-${TARGET_BUILD_DIR%Build/*}}"
INFO_PLIST="${ARCHIVE_PATH}/Info.plist"

if [ ! -f "${INFO_PLIST}" ]; then
    echo "❌ Archive Info.plist not found at: ${INFO_PLIST}"
    exit 0
fi

# Check if ApplicationProperties already exists
if /usr/libexec/PlistBuddy -c "Print :ApplicationProperties" "${INFO_PLIST}" &>/dev/null; then
    echo "✅ ApplicationProperties already exists"
    exit 0
fi

echo "📝 Adding ApplicationProperties to archive..."

# Add ApplicationProperties
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties dict" "${INFO_PLIST}"
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:ApplicationPath string Applications/${PRODUCT_NAME}.app" "${INFO_PLIST}"
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:CFBundleIdentifier string ${PRODUCT_BUNDLE_IDENTIFIER}" "${INFO_PLIST}"
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:CFBundleShortVersionString string ${MARKETING_VERSION}" "${INFO_PLIST}"
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:CFBundleVersion string ${CURRENT_PROJECT_VERSION}" "${INFO_PLIST}"
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:SigningIdentity string ${CODE_SIGN_IDENTITY}" "${INFO_PLIST}"
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:Team string ${DEVELOPMENT_TEAM}" "${INFO_PLIST}"
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:Architectures array" "${INFO_PLIST}"
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:Architectures:0 string ${ARCHS}" "${INFO_PLIST}"

echo "✅ ApplicationProperties added successfully" 