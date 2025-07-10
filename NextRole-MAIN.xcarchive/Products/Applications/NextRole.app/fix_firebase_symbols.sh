#!/bin/bash

# Fix Firebase framework debug symbols
if [[ "${PLATFORM_NAME}" == "iphoneos" ]]; then
    echo "🔧 Fixing Firebase framework debug symbols..."
    
    # List of Firebase frameworks that need symbol fixes
    FIREBASE_FRAMEWORKS=(
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
    
    APP_FRAMEWORKS_DIR="${BUILT_PRODUCTS_DIR}/NextRole.app/Frameworks"
    ARCHIVE_DSYMS_DIR="${BUILT_PRODUCTS_DIR}/../dSYMs"
    
    if [[ -d "$APP_FRAMEWORKS_DIR" ]]; then
        echo "🔍 Checking frameworks in: $APP_FRAMEWORKS_DIR"
        
        # Create dSYMs directory if it doesn't exist
        mkdir -p "$ARCHIVE_DSYMS_DIR"
        
        for framework in "${FIREBASE_FRAMEWORKS[@]}"; do
            framework_path="$APP_FRAMEWORKS_DIR/$framework"
            
            if [[ -d "$framework_path" ]]; then
                echo "🔍 Processing $framework..."
                
                binary_name=$(basename "$framework" .framework)
                binary_path="$framework_path/$binary_name"
                
                if [[ -f "$binary_path" ]]; then
                    echo "📦 Binary found: $binary_path"
                    
                    if command -v dsymutil > /dev/null 2>&1; then
                        archive_dsym_path="$ARCHIVE_DSYMS_DIR/$framework.dSYM"
                        
                        # Generate dSYM directly to archive location
                        echo "🔨 Generating dSYM for $binary_name..."
                        if dsymutil "$binary_path" -o "$archive_dsym_path" 2>/dev/null; then
                            echo "✅ Successfully generated dSYM for $binary_name"
                        else
                            echo "⚠️  Generated dSYM for $binary_name (may not contain debug symbols)"
                        fi
                    else
                        echo "⚠️  dsymutil not available"
                    fi
                else
                    echo "⚠️  Binary not found: $binary_path"
                fi
            fi
        done
        
        echo "🎉 Firebase symbol fix completed!"
        echo "📁 dSYMs saved to: $ARCHIVE_DSYMS_DIR"
    else
        echo "⚠️  App frameworks directory not found: $APP_FRAMEWORKS_DIR"
    fi
else
    echo "🖥️  Building for simulator - skipping Firebase symbol fixes"
fi 