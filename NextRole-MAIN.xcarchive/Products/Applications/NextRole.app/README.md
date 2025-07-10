# Firebase Symbol Fix Scripts

This directory contains scripts to fix Firebase framework debug symbol upload issues when submitting to the App Store.

## Problem

When uploading your app to App Store Connect, you may encounter "Upload Symbols Failed" errors for Firebase frameworks like:
- FirebaseFirestoreInternal.framework
- absl.framework
- grpc.framework
- grpcpp.framework
- openssl_grpc.framework

These errors occur because the Firebase frameworks don't include debug symbols (dSYMs) by default, which are required for crash reporting and debugging.

## Solution

We've implemented a comprehensive solution with multiple layers:

### 1. Build Settings (Already Configured)

The following build settings are configured in the Xcode project:
- `STRIP_INSTALLED_PRODUCT = NO` - Prevents stripping of debug symbols
- `STRIP_SWIFT_SYMBOLS = NO` - Prevents stripping of Swift symbols
- `COPY_PHASE_STRIP = NO` - Prevents stripping during copy phase
- `DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym"` - Generates dSYM files

### 2. Automatic Build Phase Script

**File:** Inline script in Xcode project

This script runs automatically during the build process and:
- Detects when building for device (not simulator)
- Scans for Firebase frameworks in the build output
- Generates missing dSYM files using `dsymutil`
- Verifies dSYM structure integrity
- Handles frameworks in `NextRole.app/Frameworks/` directory

**Status:** ✅ Integrated into Xcode build process (inline script)

### 3. Manual Post-Archive Script

**File:** `post_archive_symbols_fix.sh`

This script can be run manually after archiving to fix any remaining issues:
- Can be run from Terminal with a specific path
- Verifies existing dSYM structures
- Regenerates incomplete dSYMs
- Provides detailed logging

## Usage

### Automatic (Recommended)

The inline Firebase symbols fix script runs automatically during every build. No manual intervention required.

### Manual (If Needed)

If you still encounter symbol upload issues:

1. **After archiving your app:**
   ```bash
   cd /path/to/your/NextRole/project
   ./NextRole/scripts/post_archive_symbols_fix.sh
   ```

2. **With specific framework path:**
   ```bash
   ./NextRole/scripts/post_archive_symbols_fix.sh /path/to/your/app/Frameworks
   ```

3. **From Xcode build phase:**
   Add this script as a "Run Script" build phase after the "Copy Bundle Resources" phase.

## Script Details

### fix_firebase_symbols.sh

- **When it runs:** During every build
- **What it does:** Generates dSYMs for Firebase frameworks
- **Target frameworks:** All Firebase-related frameworks
- **Location:** Integrated into Xcode build process

### post_archive_symbols_fix.sh

- **When it runs:** Manually after archiving
- **What it does:** Verifies and regenerates dSYMs
- **Target frameworks:** All Firebase-related frameworks
- **Location:** Manual execution

## Troubleshooting

### If symbols still fail to upload:

1. **Check build logs:** Look for the "Fix Firebase Symbols" build phase output
2. **Verify dSYM generation:** Check that `.dSYM` files exist next to framework binaries
3. **Run manual script:** Use `post_archive_symbols_fix.sh` after archiving
4. **Check framework locations:** Ensure scripts check both possible framework locations

### Common issues:

- **dsymutil not found:** Install Xcode Command Line Tools
- **Permission denied:** Make scripts executable with `chmod +x`
- **Framework not found:** Scripts automatically scan multiple locations

## Framework Locations

The scripts check for frameworks in:
1. `$(BUILT_PRODUCTS_DIR)/Frameworks/`
2. `$(BUILT_PRODUCTS_DIR)/NextRole.app/Frameworks/`

## Supported Frameworks

The scripts handle these Firebase frameworks:
- FirebaseFirestoreInternal.framework
- absl.framework
- grpc.framework
- grpcpp.framework
- openssl_grpc.framework
- FirebaseCore.framework
- FirebaseAuth.framework
- FirebaseFirestore.framework
- FirebaseStorage.framework
- FirebaseFunctions.framework
- FirebaseApp.framework
- GoogleUtilities.framework
- FirebaseAuthInterop.framework
- FirebaseCoreInternal.framework
- FirebaseSharedSwift.framework
- FirebaseFirestoreSwift.framework

## Notes

- Scripts only run when building for device (`iphoneos` platform)
- Simulator builds are skipped to save time
- All scripts include comprehensive error handling and logging
- Scripts are idempotent - safe to run multiple times 