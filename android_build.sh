#!/bin/bash

# [AI GENERATED CODE]
# Android Build Automation Script for SplashLearn
# Handles Android app builds with embedded Flutter module

# Source shared functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/shared_functions.sh"

# Function to apply flutter_app code changes inline (without patch file)
apply_flutter_inline_changes() {
    print_info "Applying inline code changes to flutter_app..."

    cd "$FLUTTER_APP_DIR"

    # File 1: book_library_dashboard_webview.dart
    local file1="$FLUTTER_APP_DIR/lib/screens/book_library/digital_library/book_library_dashboard_webview.dart"
    if [ -f "$file1" ]; then
        print_info "Updating book_library_dashboard_webview.dart..."
        # Comment out @JS() decorator
        sed -i '' 's/^@JS()$/\/\/ @JS()/g' "$file1"
        # Comment out js/js.dart import
        sed -i '' "s/^import 'package:js\/js.dart';$/\/\/ import 'package:js\/js.dart';/g" "$file1"
        print_success "book_library_dashboard_webview.dart updated"
    else
        print_warning "book_library_dashboard_webview.dart not found at: $file1"
    fi

    # File 2: printables_dashboard.dart
    local file2="$FLUTTER_APP_DIR/lib/screens/printables_dashboard.dart"
    if [ -f "$file2" ]; then
        print_info "Updating printables_dashboard.dart..."
        # Comment out @JS() decorator
        sed -i '' 's/^@JS()$/\/\/ @JS()/g' "$file2"
        # Comment out js/js.dart import
        sed -i '' "s/^import 'package:js\/js.dart';$/\/\/ import 'package:js\/js.dart';/g" "$file2"
        print_success "printables_dashboard.dart updated"
    else
        print_warning "printables_dashboard.dart not found at: $file2"
    fi

    # File 3: exception_handler_platform_interface.dart
    local file3="$FLUTTER_APP_DIR/platform_interfaces/platform_context_interface/exception_handler/exception_handler_platform_interface/lib/exception_handler_platform_interface.dart"
    if [ -f "$file3" ]; then
        print_info "Updating exception_handler_platform_interface.dart..."

        # Step 1: Comment out all throw UnimplementedError lines
        sed -i '' 's/^[[:space:]]*throw UnimplementedError/    \/\/ throw UnimplementedError/g' "$file3"

        # Step 2: Add return statements for methods with non-void return types
        # startTransaction returns Future<bool> - add return Future.value(false);
        sed -i '' '/Future<bool> startTransaction.*async {/,/^  }/ {
            /\/\/ throw UnimplementedError/a\
    return Future.value(false);
        }' "$file3"

        # getActiveTransactionIds returns Future<List<String>> - add return Future.value([]);
        sed -i '' '/Future<List<String>> getActiveTransactionIds.*async {/,/^  }/ {
            /\/\/ throw UnimplementedError/a\
    return Future.value([]);
        }' "$file3"

        # getSentryNavigatorObserver returns dynamic - add return null;
        sed -i '' '/dynamic getSentryNavigatorObserver() {/,/^  }/ {
            /\/\/ throw UnimplementedError/a\
    return null;
        }' "$file3"

        # createSentryHttpClient returns dynamic - add return baseClient;
        sed -i '' '/dynamic createSentryHttpClient.*{/,/^  }/ {
            /\/\/ throw UnimplementedError/a\
    return baseClient;
        }' "$file3"

        print_success "exception_handler_platform_interface.dart updated"
    else
        print_warning "exception_handler_platform_interface.dart not found at: $file3"
    fi

    # File 4: pubspec.yaml
    local file4="$FLUTTER_APP_DIR/pubspec.yaml"
    if [ -f "$file4" ]; then
        print_info "Updating pubspec.yaml web dependency..."
        # Update web: ^1.0.0 to web: ^1.1.1
        sed -i '' 's/web: \^1\.0\.0/web: ^1.1.1/g' "$file4"
        print_success "pubspec.yaml updated"
    else
        print_warning "pubspec.yaml not found at: $file4"
    fi

    print_success "All inline code changes applied successfully"
}

# Function to update flutter.env based on flavor
update_flutter_env() {
    local flavor=$1
    print_info "Updating flutter.env for $flavor build..."
    cd "$FLUTTER_APP_DIR"

    if [[ "$flavor" == dev* ]]; then
        # Dev/Stage configuration
        cat > flutter.env << 'EOF'
GRAPHQL_URL = "https://staging-apig.sandbox.splashlearn.com/graphql/graphql"
CURRICULUM_SERVICE_URL = "https://staging-apig.sandbox.splashlearn.com/curriculum_service"
API_GATEWAY_URL = "https://staging-apig.sandbox.splashlearn.com/"
WEB_URL = "https://staging.sandbox.splashlearn.com/"
ASSET_CDN_URL = "https://staging-cdn.splashmath.com"
WEBSOCKET_GATEWAY_URL= "wss://staging-apiw.splashlearn.com"
SPLASHMATH_SKILL_ASSETS_URL= "https://staging-splashmath-skill-images.s3.amazonaws.com"
SENTRY_KEY = ''
ENVIRONMENT = "development"
DIST = "development"
EOF
    else
        # Prod configuration
        cat > flutter.env << 'EOF'
GRAPHQL_URL = "https://apig.splashlearn.com/graphql/graphql"
CURRICULUM_SERVICE_URL = "https://apig.splashlearn.com/curriculum_service"
API_GATEWAY_URL = "https://apig.splashlearn.com/"
WEB_URL = "https://www.splashlearn.com/"
ASSET_CDN_URL = "https://cdn.splashmath.com"
WEBSOCKET_GATEWAY_URL= "wss://apiw.splashlearn.com"
SPLASHMATH_SKILL_ASSETS_URL= "https://splashmath-skill-images.s3.amazonaws.com"
SENTRY_KEY = ''
ENVIRONMENT = "production"
DIST = "production"
EOF
    fi

    print_success "flutter.env updated for $flavor"
}

# Function to recreate Flutter module (optional)
recreate_flutter_module() {
    print_info "Recreating Flutter module..."
    cd "$FLUTTER_APP_DIR"

    # Clean Flutter cache
    print_info "Cleaning Flutter pub cache..."
    flutter pub cache clean

    # Create temporary directory for new module
    local temp_module_dir="${FLUTTER_APP_DIR}_temp"

    # Create new Flutter module
    print_info "Creating new Flutter module..."
    cd "$SCRIPT_DIR"
    flutter create -t module flutter_app_temp

    # Copy .android directory
    if [ -d "${temp_module_dir}/.android" ]; then
        print_info "Copying .android directory..."
        rm -rf "$FLUTTER_APP_DIR/.android"
        cp -R "${temp_module_dir}/.android" "$FLUTTER_APP_DIR/.android"
        print_success ".android directory copied"
    fi

    # Remove temporary module
    rm -rf "$temp_module_dir"

    print_success "Flutter module recreated"
}

# Function to setup Flutter dependencies
setup_flutter_dependencies() {
    print_info "Setting up Flutter dependencies..."
    cd "$FLUTTER_APP_DIR"

    flutter pub get

    print_success "Flutter dependencies setup complete"
}

# Function to update design tokens based on environment
update_design_tokens() {
    local flavor=$1
    print_info "Updating design tokens for $flavor environment..."

    cd "$FLUTTER_APP_DIR"

    # Determine branch name based on flavor
    local design_tokens_branch
    if [ "$flavor" = "dev"* ]; then
        design_tokens_branch="staging"
    else
        design_tokens_branch="master"
    fi

    # Run initial setup
    print_info "Running design tokens manual setup..."
    if [ -f "./update_design_tokens.sh" ]; then
        ./update_design_tokens.sh --manual-setup
        print_success "Design tokens manual setup completed"
    else
        print_warning "update_design_tokens.sh not found"
    fi

    # Run update with branch
    print_info "Running design tokens update for branch: $design_tokens_branch..."
    if [ -f "./update_design_tokens.sh" ]; then
        ./update_design_tokens.sh --update --branch "$design_tokens_branch"
        print_success "Design tokens updated for $design_tokens_branch"
    else
        print_warning "update_design_tokens.sh not found"
    fi
}

# Function to modify pubspec.yaml files
modify_pubspec_files() {
    print_info "Modifying pubspec.yaml files..."

    cd "$FLUTTER_APP_DIR"

    # 1. Remove sentry_flutter from main pubspec.yaml
    print_info "Removing sentry_flutter from main pubspec.yaml..."
    sed -i.bak '/sentry_flutter/d' ./pubspec.yaml
    rm pubspec.yaml.bak
    print_success "sentry_flutter removed from main pubspec.yaml"

    # 2. Remove sentry_flutter from exception_handler_web pubspec.yaml
    print_info "Removing sentry_flutter from exception_handler_web pubspec.yaml..."
    local exception_handler_web="./platform_interfaces/platform_context_interface/exception_handler/exception_handler_web/pubspec.yaml"
    if [ -f "$exception_handler_web" ]; then
        sed -i.bak '/sentry_flutter/d' "$exception_handler_web"
        rm "${exception_handler_web}.bak"
        print_success "sentry_flutter removed from exception_handler_web pubspec.yaml"
    else
        print_warning "exception_handler_web pubspec.yaml not found"
    fi

    # 3. Uncomment drift in context_plugin_ios pubspec.yaml
    print_info "Uncommenting drift in context_plugin_ios pubspec.yaml..."
    local context_plugin_ios="./platform_interfaces/platform_context_interface/context_plugin/context_plugin_ios/pubspec.yaml"
    if [ -f "$context_plugin_ios" ]; then
        sed -i.bak 's/# drift: \^2.26.0/drift: \^2.26.0/' "$context_plugin_ios"
        rm "${context_plugin_ios}.bak"
        print_success "drift uncommented in context_plugin_ios pubspec.yaml"
    else
        print_warning "context_plugin_ios pubspec.yaml not found"
    fi

    # 4. Update web version from ^0.5.1 to ^1.0.0 in main pubspec.yaml
    print_info "Updating web version in main pubspec.yaml..."
    sed -i.bak 's/web: \^0.5.1/web: ^1.0.0/' ./pubspec.yaml
    rm pubspec.yaml.bak
    print_success "web version updated to ^1.0.0"

    # 5. Run flutter pub get
    print_info "Running flutter pub get..."
    flutter pub get
    print_success "Flutter pub get completed"
}

# [AI GENERATED CODE]
# Function to validate sp-android project structure
validate_project_structure() {
    print_info "Validating sp-android project structure..."
    cd "$SP_ANDROID_DIR"

    # Required modules for successful build
    local required_modules=(
        "app"
        "lvl_library"
        "unityLibrary"
        "play_assets"
        "common_assets"
        "gradek_assets"
        "grade1_assets"
        "grade2_assets"
        "grade3_assets"
        "grade4_assets"
        "grade5_assets"
        "UnityDataAssetPack"
    )

    local missing_modules=()

    for module in "${required_modules[@]}"; do
        if [ ! -f "$module/build.gradle" ]; then
            missing_modules+=("$module")
        fi
    done

    if [ ${#missing_modules[@]} -gt 0 ]; then
        print_warning "Missing modules: ${missing_modules[*]}"
        print_warning "Build may fail if required modules are not available"
    else
        print_success "All required modules found"
    fi

    # Check for critical files
    if [ ! -f "build.gradle" ] || [ ! -f "settings.gradle" ] || [ ! -f "dependencies.gradle" ]; then
        print_error "Critical files missing (build.gradle, settings.gradle, dependencies.gradle)"
        return 1
    fi

    print_success "Project structure validation complete"
    return 0
}

# [AI GENERATED CODE]
# Function to prepare Android build
prepare_android_build() {
    local flavor=$1
    local export_type=$2
    print_info "Preparing Android project for build..."

    # Check and copy sentry.properties if missing
    local sentry_dest="$SP_ANDROID_DIR/sentry.properties"
    local sentry_src="$SCRIPT_DIR/sentry.properties"
    if [ ! -f "$sentry_dest" ]; then
        print_warning "sentry.properties not found in $SP_ANDROID_DIR, copying from $sentry_src..."
        if [ -f "$sentry_src" ]; then
            if cp "$sentry_src" "$sentry_dest"; then
                print_success "sentry.properties copied successfully"
            else
                print_error "Failed to copy sentry.properties from $sentry_src to $sentry_dest"
                return 1
            fi
        else
            print_error "Source sentry.properties not found at $sentry_src"
            return 1
        fi
    else
        print_info "sentry.properties already exists in $SP_ANDROID_DIR, skipping copy"
    fi

    cd "$SP_ANDROID_DIR"
    # Validate project structure
    if ! validate_project_structure; then
        print_error "Project structure validation failed"
        return 1
    fi
    # Run gradle clean with build cache
    print_info "Running gradle clean..."
    if ! ./gradlew clean; then
        print_error "Gradle clean failed"
        return 1
    fi
    # Delete libil2cpp.so files for AAB builds
    if [ "$export_type" = "aab" ]; then
        print_info "Deleting libil2cpp.so files for AAB build..."
        if find unityLibrary -name "libil2cpp.so" -type f -delete; then
            print_success "Deleted all libil2cpp.so files"
        fi
    fi
    # Comment out applicationIdSuffix for dev Android builds only
    if [ "$flavor" = "devandroid" ]; then
        print_info "Commenting out applicationIdSuffix for dev Android build..."
        local build_gradle="app/build.gradle"
        if [ -f "$build_gradle" ]; then
            sed -i.bak "s|^\([[:space:]]*\)applicationIdSuffix '.debug1'|            // applicationIdSuffix '.debug1'|" "$build_gradle"
            rm -f "$build_gradle.bak"
            print_success "applicationIdSuffix commented out"
        fi
    fi
    # Validate asset packs configuration
    print_info "Validating asset packs configuration..."
    local asset_packs=("play_assets" "UnityDataAssetPack" "common_assets" "gradek_assets" "grade1_assets" "grade2_assets" "grade3_assets" "grade4_assets" "grade5_assets")
    for pack in "${asset_packs[@]}"; do
        if [ ! -d "$pack" ]; then
            print_warning "Asset pack not found: $pack"
        fi
    done
    print_success "Android project preparation complete"
    return 0
}

# Function to restore build.gradle after build
restore_build_gradle() {
    local flavor=$1

    if [ "$flavor" = "devandroid" ]; then
        print_info "Restoring applicationIdSuffix in build.gradle..."
        cd "$SP_ANDROID_DIR"
        local build_gradle="app/build.gradle"
        if [ -f "$build_gradle" ]; then
            sed -i.bak "s|^\([[:space:]]*\)// applicationIdSuffix '.debug1'|            applicationIdSuffix '.debug1'|" "$build_gradle"
            rm -f "$build_gradle.bak"
            print_success "applicationIdSuffix restored"
        fi
    fi
}

# [AI GENERATED CODE]
# Function to build Android app
build_android_app() {
    local flavor=$1
    local build_type=$2
    local export_type=$3

    print_info "Building Android app..."
    cd "$SP_ANDROID_DIR"

    # Validate build parameters
    if [ -z "$flavor" ] || [ -z "$build_type" ] || [ -z "$export_type" ]; then
        print_error "Invalid build parameters: flavor=$flavor, build_type=$build_type, export_type=$export_type"
        return 1
    fi

    # Capitalize first letter for Gradle task
    local flavor_cap="$(tr '[:lower:]' '[:upper:]' <<< ${flavor:0:1})${flavor:1}"
    local build_type_cap="$(tr '[:lower:]' '[:upper:]' <<< ${build_type:0:1})${build_type:1}"

    local gradle_task
    if [ "$export_type" = "apk" ]; then
        gradle_task="assemble${flavor_cap}${build_type_cap}"
    else
        gradle_task="bundle${flavor_cap}${build_type_cap}"
    fi

    print_info "Running: ./gradlew $gradle_task"

    # Execute gradle task with error handling
    if ./gradlew "$gradle_task"; then
        print_success "Build completed successfully"
        return 0
    else
        print_error "Gradle build failed with exit code: $?"
        return 1
    fi
}

# [AI GENERATED CODE]
# Function to validate signing configuration
validate_signing_config() {
    local build_type=$1
    print_info "Validating signing configuration for $build_type build..."
    cd "$SP_ANDROID_DIR"

    if [ "$build_type" = "release" ] || [ "$build_type" = "profile" ]; then
        if [ ! -f "app/keystore/my-release-key.keystore" ]; then
            print_warning "Release keystore file not found: app/keystore/my-release-key.keystore"
            print_warning "Ensure keystore file exists for release builds"
        else
            print_success "Release keystore validated"
        fi
    fi

    if [ "$build_type" = "debug" ]; then
        if [ ! -f "app/keystore/my.debug.keystore" ]; then
            print_warning "Debug keystore file not found: app/keystore/my.debug.keystore"
        else
            print_success "Debug keystore validated"
        fi
    fi
}

# [AI GENERATED CODE]
# Function to copy build output
copy_build_output() {
    local flavor=$1
    local build_type=$2
    local export_type=$3

    print_info "Copying build output to $BUILD_OUTPUT_DIR..."
    cd "$SP_ANDROID_DIR"

    # Create base output directory structure
    mkdir -p "$BUILD_OUTPUT_DIR"

    # Capitalize first letter for Gradle path
    local flavor_cap="$(tr '[:lower:]' '[:upper:]' <<< ${flavor:0:1})${flavor:1}"
    local build_type_cap="$(tr '[:lower:]' '[:upper:]' <<< ${build_type:0:1})${build_type:1}"

    # Determine source path based on export type
    local build_dir="app/build/outputs"
    if [ "$export_type" = "apk" ]; then
        local source_path="$build_dir/apk/$flavor/$build_type/"
        local file_pattern="*.apk"
    else
        local source_path="$build_dir/bundle/${flavor_cap}${build_type_cap}/"
        local file_pattern="*.aab"
    fi

    # Copy build artifacts with organized directory structure
    if [ -d "$source_path" ]; then
        local build_date=$(date +"%Y-%m-%d")
        local build_time=$(date +"%H%M%S")
        local dest_dir="$BUILD_OUTPUT_DIR/${build_date}/${flavor}/${build_type}_${export_type}_${build_time}"
        mkdir -p "$dest_dir"

        if find "$source_path" -name "$file_pattern" -exec cp {} "$dest_dir/" \;; then
            print_success "Build output copied to: $dest_dir"

            # Display copied files with details
            print_info "Build files:"
            ls -lh "$dest_dir"

            return 0
        else
            print_error "Failed to copy build output files"
            return 1
        fi
    else
        print_error "Build output directory not found: $source_path"
        print_info "Expected APK output: $build_dir/apk/$flavor/$build_type/"
        print_info "Expected AAB output: $build_dir/bundle/${flavor_cap}${build_type_cap}/"
        return 1
    fi
}

# Main Android build function
main_android_build() {
    print_message "$GREEN" "================================================"
    print_message "$GREEN" "  Android Build Automation Script"
    print_message "$GREEN" "  SplashLearn - Flutter Embedded App"
    print_message "$GREEN" "================================================"
    echo ""

    # Verify directories exist
    if [ ! -d "$SP_ANDROID_DIR" ]; then
        print_error "sp-android directory not found at: $SP_ANDROID_DIR"
        exit 1
    fi

    if [ ! -d "$FLUTTER_APP_DIR" ]; then
        print_error "flutter_app directory not found at: $FLUTTER_APP_DIR"
        exit 1
    fi

    # Prompt for build configuration
    print_message "$YELLOW" "Build Configuration"
    echo ""

    SP_ANDROID_BRANCH=$(prompt_input "Enter branch name for sp-android" "nov25-release-1")
    FLUTTER_APP_BRANCH=$(prompt_input "Enter branch name for flutter_app" "android_nov_25_1")

    echo ""
    # Select environment flavor (dev/prod)
    print_info "Select build flavor (environment):"
    echo "  1) dev   (Staging environment - .debug1 app ID suffix)"
    echo "  2) prod  (Production environment)"
    printf "${BLUE}Enter choice [1-2]${NC}: "
    read flavor_choice

    case $flavor_choice in
        1) BUILD_FLAVOR="dev" ;;
        2) BUILD_FLAVOR="prod" ;;
        *) print_error "Invalid choice"; exit 1 ;;
    esac

    echo ""
    # Select store dimension (Android Play Store vs Amazon Appstore)
    print_info "Select target store:"
    echo "  1) android  (Google Play Store)"
    echo "  2) amazon   (Amazon Appstore)"
    printf "${BLUE}Enter choice [1-2]${NC}: "
    read store_choice

    case $store_choice in
        1) BUILD_STORE="android" ;;
        2) BUILD_STORE="amazon" ;;
        *) print_error "Invalid choice"; exit 1 ;;
    esac

    # Combine flavor dimensions for complete variant name
    BUILD_FLAVOR="${BUILD_FLAVOR}${BUILD_STORE}"

    echo ""
    # Select build type (debug, profile, release)
    print_info "Select build type:"
    echo "  1) debug    (Debuggable, no minification)"
    echo "  2) profile  (Minified, debuggable, Firebase profiling enabled)"
    echo "  3) release  (Minified, shrunk, no debugging)"
    printf "${BLUE}Enter choice [1-3]${NC}: "
    read build_type_choice

    case $build_type_choice in
        1) BUILD_TYPE="debug" ;;
        2) BUILD_TYPE="profile" ;;
        3) BUILD_TYPE="release" ;;
        *) print_error "Invalid choice"; exit 1 ;;
    esac

    echo ""
    # Select export type (APK vs AAB)
    print_info "Select export type:"
    echo "  1) apk  (Direct APK file, immediate installation)"
    echo "  2) aab  (Android App Bundle, for store upload)"
    printf "${BLUE}Enter choice [1-2]${NC}: "
    read export_choice

    case $export_choice in
        1) EXPORT_TYPE="apk" ;;
        2) EXPORT_TYPE="aab" ;;
        *) print_error "Invalid choice"; exit 1 ;;
    esac

    echo ""
    if prompt_yes_no "Do you want to recreate Flutter module? (optional, time-consuming)"; then
        RECREATE_FLUTTER=true
    else
        RECREATE_FLUTTER=false
    fi

    # Build Summary
    echo ""
    print_message "$YELLOW" "Build Summary"
    echo "  sp-android branch:     $SP_ANDROID_BRANCH"
    echo "  flutter_app branch:    $FLUTTER_APP_BRANCH"
    echo "  Build flavor:          $BUILD_FLAVOR (environment: ${BUILD_FLAVOR%android*}${BUILD_FLAVOR%amazon*}, store: $BUILD_STORE)"
    echo "  Build type:            $BUILD_TYPE"
    echo "  Export type:           $EXPORT_TYPE"
    echo "  Recreate Flutter:      $RECREATE_FLUTTER"
    echo "  Output directory:      $BUILD_OUTPUT_DIR"
    echo ""
    print_info "sp-android Project Configuration:"
    echo "  Multi-module:          Yes (13 modules including asset packs)"
    echo "  Build flavors:         2D: environment (prod/dev) × store (android/amazon)"
    echo "  Build types:           debug, profile, release"
    echo "  NDK version:           26.1.10909125"
    echo "  Min SDK:               26"
    echo "  Target SDK:            36"
    echo "  Kotlin:                2.1.0"
    echo "  AGP (Gradle Plugin):   8.9.1"
    echo ""

    if ! prompt_yes_no "Proceed with build?"; then
        print_warning "Build cancelled by user"
        exit 0
    fi

    echo ""
    print_message "$GREEN" "Starting build process..."
    echo ""

    # Step 1: Clean repositories
    clean_git_repo "$SP_ANDROID_DIR" "sp-android"
    clean_git_repo "$FLUTTER_APP_DIR" "flutter_app"

    # Step 2: Checkout branches
    checkout_branch "$SP_ANDROID_DIR" "$SP_ANDROID_BRANCH" "sp-android"
    checkout_branch "$FLUTTER_APP_DIR" "$FLUTTER_APP_BRANCH" "flutter_app"

    # Step 3: Apply Flutter code changes (inline)
    apply_flutter_inline_changes

    # Step 4: Update flutter.env
    update_flutter_env "$BUILD_FLAVOR"

    # Step 5: Recreate Flutter module (optional)
    if [ "$RECREATE_FLUTTER" = true ]; then
        recreate_flutter_module
    fi

    # Step 6: Setup Flutter dependencies
    setup_flutter_dependencies

    # Step 7: Update design tokens based on environment
    update_design_tokens "$BUILD_FLAVOR"

    # Step 8: Modify pubspec.yaml files
    modify_pubspec_files

    # Step 9: Prepare Android build
    if ! prepare_android_build "$BUILD_FLAVOR" "$EXPORT_TYPE"; then
        print_error "Android project preparation failed"
        exit 1
    fi

    # Step 10: Validate signing configuration
    validate_signing_config "$BUILD_TYPE"

    # Step 11: Build Android app
    if ! build_android_app "$BUILD_FLAVOR" "$BUILD_TYPE" "$EXPORT_TYPE"; then
        print_error "Android app build failed"
        exit 1
    fi

    # Step 12: Copy build output
    if ! copy_build_output "$BUILD_FLAVOR" "$BUILD_TYPE" "$EXPORT_TYPE"; then
        print_error "Failed to copy build output"
        exit 1
    fi

    # Step 13: Restore build.gradle (cleanup)
    restore_build_gradle "$BUILD_FLAVOR"

    echo ""
    print_message "$GREEN" "================================================"
    print_success "Build process completed successfully!"
    print_message "$GREEN" "================================================"
    echo ""
    print_info "Build output location: $BUILD_OUTPUT_DIR"
}
