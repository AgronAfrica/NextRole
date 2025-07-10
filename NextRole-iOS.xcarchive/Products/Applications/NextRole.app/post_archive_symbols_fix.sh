#!/bin/bash

# Post-Archive Firebase Symbols Fix Script
# Run this script after archiving your app to fix any remaining symbol upload issues

set -e

echo "🚀 Post-Archive Firebase Symbols Fix"
echo "===================================="

# Check if we have the required tools
if ! command -v dsymutil &> /dev/null; then
    echo "❌ Error: dsymutil is not available. Please install Xcode Command Line Tools."
    exit 1
fi

# Function to process a framework
process_framework() {
    local framework_path="$1"
    local framework_name=$(basename "$framework_path")
    
    echo "🔍 Processing: $framework_name"
    
    # Get the binary name
    local binary_name=$(basename "$framework_name" .framework)
    local binary_path="$framework_path/$binary_name"
    
    if [[ ! -f "$binary_path" ]]; then
        echo "⚠️  Binary not found: $binary_path"
        return 1
    fi
    
    # Check if dSYM already exists
    local dsym_path="$framework_path/$binary_name.dSYM"
    if [[ -d "$dsym_path" ]]; then
        echo "✅ dSYM already exists for $binary_name"
        
        # Verify the dSYM structure
        if [[ -d "$dsym_path/Contents/Resources/DWARF" ]]; then
            echo "✅ dSYM structure verified for $binary_name"
        else
            echo "⚠️  dSYM structure incomplete for $binary_name, regenerating..."
            rm -rf "$dsym_path"
        fi
    fi
    
    # Generate dSYM if it doesn't exist or was incomplete
    if [[ ! -d "$dsym_path" ]]; then
        echo "🔨 Generating dSYM for $binary_name..."
        if dsymutil "$binary_path" -o "$dsym_path"; then
            echo "✅ Successfully generated dSYM for $binary_name"
            return 0
        else
            echo "❌ Failed to generate dSYM for $binary_name"
            return 1
        fi
    fi
    
    return 0
}

# Function to find and process Firebase frameworks
find_and_process_frameworks() {
    local search_path="$1"
    local processed_count=0
    
    echo "🔍 Searching for Firebase frameworks in: $search_path"
    
    # List of Firebase frameworks that commonly cause symbol upload issues
    local firebase_frameworks=(
        "FirebaseFirestoreInternal.framework"
        "absl.framework"
        "grpc.framework"
        "grpcpp.framework"
        "openssl_grpc.framework"
        "FirebaseCore.framework"
        "FirebaseAuth.framework"
        "FirebaseFirestore.framework"
        "FirebaseStorage.framework"
        "FirebaseFunctions.framework"
        "FirebaseApp.framework"
        "GoogleUtilities.framework"
        "FirebaseAuthInterop.framework"
        "FirebaseCoreInternal.framework"
        "FirebaseSharedSwift.framework"
        "FirebaseFirestoreSwift.framework"
    )
    
    for framework in "${firebase_frameworks[@]}"; do
        local framework_path="$search_path/$framework"
        if [[ -d "$framework_path" ]]; then
            if process_framework "$framework_path"; then
                ((processed_count++))
            fi
        fi
    done
    
    echo "📊 Processed $processed_count Firebase frameworks"
}

# Function to copy dSYMs to archive location
copy_dsyms_to_archive() {
    local source_path="$1"
    local archive_path="$2"
    
    echo "📋 Copying dSYMs to archive location..."
    
    if [[ -d "$source_path" ]]; then
        # Create archive dSYMs directory if it doesn't exist
        mkdir -p "$archive_path"
        
        # Copy all dSYMs
        find "$source_path" -name "*.dSYM" -type d | while read -r dsym_path; do
            dsym_name=$(basename "$dsym_path")
            target_path="$archive_path/$dsym_name"
            
            echo "📦 Copying $dsym_name to archive..."
            cp -R "$dsym_path" "$target_path"
            
            if [[ $? -eq 0 ]]; then
                echo "✅ Successfully copied $dsym_name to archive"
            else
                echo "❌ Failed to copy $dsym_name to archive"
            fi
        done
        
        echo "🎉 All dSYMs copied to archive location: $archive_path"
    else
        echo "⚠️  Source dSYMs directory not found: $source_path"
    fi
}

# Main execution
echo "📱 This script will fix Firebase framework symbol upload issues"
echo ""

# Check if we're in a build context
if [[ -n "$BUILT_PRODUCTS_DIR" ]]; then
    echo "🏗️  Build context detected"
    FRAMEWORKS_DIR="$BUILT_PRODUCTS_DIR/Frameworks"
    APP_FRAMEWORKS_DIR="$BUILT_PRODUCTS_DIR/NextRole.app/Frameworks"
    ARCHIVE_DSYMS_DIR="$BUILT_PRODUCTS_DIR/../dSYMs"
    
    if [[ -d "$FRAMEWORKS_DIR" ]]; then
        find_and_process_frameworks "$FRAMEWORKS_DIR"
    fi
    
    if [[ -d "$APP_FRAMEWORKS_DIR" ]]; then
        find_and_process_frameworks "$APP_FRAMEWORKS_DIR"
    fi
    
    # Copy dSYMs to archive location
    if [[ -d "$APP_FRAMEWORKS_DIR" ]]; then
        copy_dsyms_to_archive "$APP_FRAMEWORKS_DIR" "$ARCHIVE_DSYMS_DIR"
    fi
else
    echo "📁 No build context detected. Please run this script from Xcode or specify a path."
    echo ""
    echo "Usage examples:"
    echo "  # From Xcode build phase:"
    echo "  ./post_archive_symbols_fix.sh"
    echo ""
    echo "  # Manual execution with path:"
    echo "  ./post_archive_symbols_fix.sh /path/to/your/app/Frameworks"
    echo ""
    
    # Check if a path was provided as argument
    if [[ -n "$1" ]]; then
        if [[ -d "$1" ]]; then
            find_and_process_frameworks "$1"
        else
            echo "❌ Error: Directory not found: $1"
            exit 1
        fi
    fi
fi

echo ""
echo "🎉 Post-archive Firebase symbol fix completed!"
echo ""
echo "💡 Next steps:"
echo "   1. Upload your archive to App Store Connect"
echo "   2. The symbol upload should now succeed"
echo ""
echo "🔧 If you still encounter issues:"
echo "   1. Check that dSYMs are in the archive's dSYMs folder"
echo "   2. Verify that the UUIDs match the expected ones"
echo "   3. Try archiving again with a clean build"
echo "" 