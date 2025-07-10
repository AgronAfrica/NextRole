#!/bin/bash

# Comprehensive script to fix Firebase framework symbol upload issues
# This script should be run after archiving and before uploading to App Store Connect

set -e

echo "🚀 Firebase Symbol Upload Fix Script"
echo "====================================="

# Check if we have the required tools
if ! command -v dsymutil &> /dev/null; then
    echo "❌ Error: dsymutil is not available. Please install Xcode Command Line Tools."
    exit 1
fi

if ! command -v xcrun &> /dev/null; then
    echo "❌ Error: xcrun is not available. Please install Xcode Command Line Tools."
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
        return 0
    fi
    
    # Generate dSYM
    echo "🔨 Generating dSYM for $binary_name..."
    if dsymutil "$binary_path" -o "$dsym_path"; then
        echo "✅ Successfully generated dSYM for $binary_name"
        return 0
    else
        echo "❌ Failed to generate dSYM for $binary_name"
        return 1
    fi
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

# Main execution
echo "📱 This script will fix Firebase framework symbol upload issues"
echo ""

# Check if we're in a build context
if [[ -n "$BUILT_PRODUCTS_DIR" ]]; then
    echo "🏗️  Build context detected"
    FRAMEWORKS_DIR="$BUILT_PRODUCTS_DIR/Frameworks"
    
    if [[ -d "$FRAMEWORKS_DIR" ]]; then
        find_and_process_frameworks "$FRAMEWORKS_DIR"
    else
        echo "⚠️  Frameworks directory not found: $FRAMEWORKS_DIR"
    fi
else
    echo "📁 No build context detected. Please run this script from Xcode or specify a path."
    echo ""
    echo "Usage examples:"
    echo "  # From Xcode build phase:"
    echo "  ./upload_symbols_fix.sh"
    echo ""
    echo "  # Manual execution with path:"
    echo "  ./upload_symbols_fix.sh /path/to/your/app/Frameworks"
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
echo "🎉 Firebase symbol fix completed!"
echo ""
echo "💡 Next steps:"
echo "   1. Archive your app again"
echo "   2. Upload to App Store Connect"
echo "   3. The symbol upload should now succeed"
echo "" 