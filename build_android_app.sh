#!/bin/bash

# [AI GENERATED CODE]
# Automated Android Build Script for SplashLearn
# This script automates the build process for the Android app with embedded Flutter module
# Location: android_build_automation/build_android_app.sh (parallel to sp-android and flutter_app)

set -e  # Exit on error

# Enable echo to interpret escape sequences
shopt -s xpg_echo 2>/dev/null || true

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SP_ANDROID_DIR="$SCRIPT_DIR/../sp-android"
FLUTTER_APP_DIR="$SCRIPT_DIR/../flutter_app"
# [AI GENERATED CODE] Build outputs now go to android_build_automation/builds directory
BUILD_OUTPUT_DIR="$SCRIPT_DIR/builds"

# WWW Build paths (for different system)
OMNIJS_DIR="$SCRIPT_DIR/../omnijs"
OMNI_CONTENT_DIR="$SCRIPT_DIR/../omni-content"
CONTENT_GAMES_DIR="$SCRIPT_DIR/../content-games"
WWW_SOURCE_DIR="$HOME/Documents/.jenkins/DEV/iOS/www"
WWW_BUILDS_DIR="$SCRIPT_DIR/../www_builds"

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    printf "${color}${message}${NC}\n"
}

print_success() {
    print_message "$GREEN" "✓ $1"
}

print_error() {
    print_message "$RED" "✗ $1"
}

print_info() {
    print_message "$BLUE" "ℹ $1"
}

print_warning() {
    print_message "$YELLOW" "⚠ $1"
}

# Function to prompt for input
prompt_input() {
    local prompt_message=$1
    local default_value=$2
    local user_input

    if [ -n "$default_value" ]; then
        printf "${BLUE}${prompt_message}${NC} [${default_value}]: " >&2
        read user_input
        echo "${user_input:-$default_value}"
    else
        printf "${BLUE}${prompt_message}${NC}: " >&2
        read user_input
        echo "$user_input"
    fi
}

# Function to prompt for yes/no
prompt_yes_no() {
    local prompt_message=$1
    local response
    printf "${BLUE}${prompt_message}${NC} [y/N]: " >&2
    read response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Function to clean git repository
clean_git_repo() {
    local repo_dir=$1
    local repo_name=$2

    print_info "Cleaning $repo_name repository..."
    cd "$repo_dir"

    # Stash any changes
    if [[ -n $(git status -s) ]]; then
        print_info "Stashing changes in $repo_name..."
        git stash
    fi

    # Restore staged changes
    git restore --staged . 2>/dev/null || true

    # Restore unstaged changes
    git restore . 2>/dev/null || true

    # Clean untracked files
    git clean -df

    print_success "$repo_name repository cleaned"
}

# Function to checkout branch
checkout_branch() {
    local repo_dir=$1
    local branch_name=$2
    local repo_name=$3

    print_info "Checking out branch '$branch_name' in $repo_name..."
    cd "$repo_dir"

    git fetch origin
    git checkout "$branch_name"
    git pull origin "$branch_name"

    print_success "Switched to branch '$branch_name' in $repo_name"
}

# Function to apply flutter_app code changes using patch file
apply_flutter_changes() {
    print_info "Applying code changes to flutter_app using patch file..."

    # Patch file is in the same directory as the script
    local patch_file="$SCRIPT_DIR/patch_for_build_creation.patch"

    if [ ! -f "$patch_file" ]; then
        print_error "Patch file not found: $patch_file"
        exit 1
    fi

    cd "$FLUTTER_APP_DIR"

    # Apply the patch
    if git apply "$patch_file"; then
        print_success "Patch applied successfully"
    else
        print_error "Failed to apply patch file"
        print_warning "Attempting to apply with --reject flag..."
        if git apply --reject "$patch_file"; then
            print_warning "Patch applied with some rejections. Check .rej files."
        else
            print_error "Patch application failed completely"
            exit 1
        fi
    fi

    print_success "All code changes applied successfully"
}

# Function to update flutter.env based on flavor
update_flutter_env() {
    local flavor=$1
    print_info "Updating flutter.env for $flavor build..."
    cd "$FLUTTER_APP_DIR"

    if [ "$flavor" = "dev" ]; then
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
    flutter pub upgrade

    print_success "Flutter dependencies setup complete"
}

# [AI GENERATED CODE]
# Function to validate sp-android project structure
# Ensures all required modules are present and build.gradle files exist
validate_project_structure() {
    print_info "Validating sp-android project structure..."
    cd "$SP_ANDROID_DIR"

    # [AI GENERATED CODE] Required modules for successful build
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

    # [AI GENERATED CODE] Check for critical files
    if [ ! -f "build.gradle" ] || [ ! -f "settings.gradle" ] || [ ! -f "dependencies.gradle" ]; then
        print_error "Critical files missing (build.gradle, settings.gradle, dependencies.gradle)"
        return 1
    fi

    print_success "Project structure validation complete"
    return 0
}

# [AI GENERATED CODE]
# Function to prepare Android build
# Handles:
# - Gradle clean and cache management
# - Unity native library handling (libil2cpp.so for AAB)
# - Application ID suffix management for dev builds
# - Asset pack preparation
prepare_android_build() {
    local flavor=$1
    local export_type=$2

    print_info "Preparing Android project for build..."
    cd "$SP_ANDROID_DIR"

    # [AI GENERATED CODE] Validate project structure
    if ! validate_project_structure; then
        print_error "Project structure validation failed"
        return 1
    fi

    # [AI GENERATED CODE] Run gradle clean with build cache
    print_info "Running gradle clean..."
    if ! ./gradlew clean; then
        print_error "Gradle clean failed"
        return 1
    fi

    # [AI GENERATED CODE] Delete libil2cpp.so files for AAB builds
    # These native libraries from Unity should not be packaged in AAB
    # Asset packs will handle delivery separately
    if [ "$export_type" = "aab" ]; then
        print_info "Deleting libil2cpp.so files for AAB build..."
        if find unityLibrary -name "libil2cpp.so" -type f -delete; then
            print_success "Deleted all libil2cpp.so files"
        fi
    fi

    # [AI GENERATED CODE] Comment out applicationIdSuffix for dev builds
    # Required for certain build configurations
    if [ "$flavor" = "dev" ]; then
        print_info "Commenting out applicationIdSuffix for dev build..."
        local build_gradle="app/build.gradle"
        if [ -f "$build_gradle" ]; then
            sed -i.bak "s|^\([[:space:]]*\)applicationIdSuffix '.debug1'|            // applicationIdSuffix '.debug1'|" "$build_gradle"
            rm -f "$build_gradle.bak"
            print_success "applicationIdSuffix commented out"
        fi
    fi

    # [AI GENERATED CODE] Validate asset packs configuration
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

    if [ "$flavor" = "dev" ]; then
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
# Supports multi-module architecture with various asset packs
# Handles flavor combinations (prod/dev × android/amazon)
# Supports multiple build types (debug, profile, release)
# Generates both APK and AAB outputs
build_android_app() {
    local flavor=$1
    local build_type=$2
    local export_type=$3

    print_info "Building Android app..."
    cd "$SP_ANDROID_DIR"

    # [AI GENERATED CODE] Validate build parameters
    if [ -z "$flavor" ] || [ -z "$build_type" ] || [ -z "$export_type" ]; then
        print_error "Invalid build parameters: flavor=$flavor, build_type=$build_type, export_type=$export_type"
        return 1
    fi

    # [AI GENERATED CODE] Capitalize first letter for Gradle task
    # Supports combined flavor dimensions: {dev|prod} × {android|amazon}
    local flavor_cap="$(tr '[:lower:]' '[:upper:]' <<< ${flavor:0:1})${flavor:1}"
    local build_type_cap="$(tr '[:lower:]' '[:upper:]' <<< ${build_type:0:1})${build_type:1}"

    local gradle_task
    if [ "$export_type" = "apk" ]; then
        # [AI GENERATED CODE] APK build: assemble{Flavor}{BuildType}
        # Example: assembleProdAndroidRelease, assembleDevAmazonDebug
        gradle_task="assemble${flavor_cap}${build_type_cap}"
    else
        # [AI GENERATED CODE] AAB build: bundle{Flavor}{BuildType}
        # Example: bundleProdAndroidRelease, bundleDevAmazonDebug
        gradle_task="bundle${flavor_cap}${build_type_cap}"
    fi

    print_info "Running: ./gradlew $gradle_task"

    # [AI GENERATED CODE] Execute gradle task with error handling
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
# Ensures keystore files exist and are accessible
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
# Handles both APK and AAB outputs from different build variants
# Supports combined flavors (prod/dev × android/amazon)
# Creates organized output directories in android_build_automation/builds
# Structure: builds/{date}/{flavor}/{build_type}_{export_type}/
copy_build_output() {
    local flavor=$1
    local build_type=$2
    local export_type=$3

    print_info "Copying build output to $BUILD_OUTPUT_DIR..."
    cd "$SP_ANDROID_DIR"

    # [AI GENERATED CODE] Create base output directory structure
    mkdir -p "$BUILD_OUTPUT_DIR"

    # [AI GENERATED CODE] Capitalize first letter for Gradle path
    # Handles combined flavor format: {prod|dev}{android|amazon}
    local flavor_cap="$(tr '[:lower:]' '[:upper:]' <<< ${flavor:0:1})${flavor:1}"
    local build_type_cap="$(tr '[:lower:]' '[:upper:]' <<< ${build_type:0:1})${build_type:1}"

    # [AI GENERATED CODE] Determine source path based on export type
    local build_dir="app/build/outputs"
    if [ "$export_type" = "apk" ]; then
        # [AI GENERATED CODE] APK output structure: apk/{flavor}/{buildType}/*.apk
        local source_path="$build_dir/apk/$flavor/$build_type/"
        local file_pattern="*.apk"
    else
        # [AI GENERATED CODE] AAB output structure: bundle/{FlavorCombination}/*.aab
        # Example: bundleProdAndroidRelease → bundle/ProdAndroid/Release/*.aab
        local source_path="$build_dir/bundle/${flavor_cap}${build_type_cap}/"
        local file_pattern="*.aab"
    fi

    # [AI GENERATED CODE] Copy build artifacts with organized directory structure
    if [ -d "$source_path" ]; then
        # [AI GENERATED CODE] Create organized folder structure: builds/{date}/{flavor}/{build_type}_{export_type}
        local build_date=$(date +"%Y-%m-%d")
        local build_time=$(date +"%H%M%S")
        local dest_dir="$BUILD_OUTPUT_DIR/${build_date}/${flavor}/${build_type}_${export_type}_${build_time}"
        mkdir -p "$dest_dir"

        # [AI GENERATED CODE] Copy all matching files to organized location
        if find "$source_path" -name "$file_pattern" -exec cp {} "$dest_dir/" \;; then
            print_success "Build output copied to: $dest_dir"

            # [AI GENERATED CODE] Display copied files with details
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

# ============================================
# WWW Build Functions
# ============================================

# Function to clean all three repos for www build
clean_www_repos() {
    print_info "Cleaning all repositories for www build..."

    clean_git_repo "$OMNIJS_DIR" "omnijs"
    clean_git_repo "$OMNI_CONTENT_DIR" "omni-content"
    clean_git_repo "$CONTENT_GAMES_DIR" "content-games"

    print_success "All repositories cleaned"
}

# Function to checkout branches for www build
checkout_www_branches() {
    local omnijs_branch=$1
    local omni_content_branch=$2
    local content_games_branch=$3

    print_info "Checking out branches in all repositories..."

    checkout_branch "$OMNIJS_DIR" "$omnijs_branch" "omnijs"
    checkout_branch "$OMNI_CONTENT_DIR" "$omni_content_branch" "omni-content"
    checkout_branch "$CONTENT_GAMES_DIR" "$content_games_branch" "content-games"

    print_success "All repositories switched to their respective branches"
}

# Function to build content-games
build_content_games() {
    print_info "Building content-games..."
    cd "$CONTENT_GAMES_DIR"

    print_info "Running: npm run build:app_common"
    npm run build:app_common

    print_success "content-games build completed"
}

# Function to restore omnijs
restore_omnijs() {
    print_info "Restoring omnijs repository..."
    cd "$OMNIJS_DIR"

    git checkout .

    print_success "omnijs repository restored"
}

# Function to compress and move www folder
compress_and_move_www() {
    print_info "Compressing and moving www folder..."

    # Check if www folder exists
    if [ ! -d "$WWW_SOURCE_DIR" ]; then
        print_error "www folder not found at: $WWW_SOURCE_DIR"
        exit 1
    fi

    # Create www_builds directory if it doesn't exist
    mkdir -p "$WWW_BUILDS_DIR"

    # Create timestamped filename
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local zip_filename="www_${timestamp}.zip"
    local zip_path="$WWW_BUILDS_DIR/$zip_filename"

    # Compress www folder
    print_info "Compressing www folder to $zip_filename..."
    cd "$(dirname "$WWW_SOURCE_DIR")"
    zip -r "$zip_path" "$(basename "$WWW_SOURCE_DIR")"

    print_success "www folder compressed and moved to: $zip_path"

    # Show file size
    print_info "Compressed file size:"
    ls -lh "$zip_path"
}

# Main function for Android build
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
    # [AI GENERATED CODE] Select environment flavor (dev/prod)
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
    # [AI GENERATED CODE] Select store dimension (Android Play Store vs Amazon Appstore)
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

    # [AI GENERATED CODE] Combine flavor dimensions for complete variant name
    BUILD_FLAVOR="${BUILD_FLAVOR}${BUILD_STORE}"

    echo ""
    # [AI GENERATED CODE] Select build type (debug, profile, release)
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
    # [AI GENERATED CODE] Select export type (APK vs AAB)
    # APK: Direct installation, immediate testing
    # AAB: Play Store/Amazon Appstore distribution, optimized delivery
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

    # [AI GENERATED CODE] Build Summary
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

    # Step 3: Apply Flutter code changes
    apply_flutter_changes

    # Step 4: Update flutter.env
    update_flutter_env "$BUILD_FLAVOR"

    # Step 5: Recreate Flutter module (optional)
    if [ "$RECREATE_FLUTTER" = true ]; then
        recreate_flutter_module
    fi

    # Step 6: Setup Flutter dependencies
    setup_flutter_dependencies

    # Step 7: Prepare Android build
    if ! prepare_android_build "$BUILD_FLAVOR" "$EXPORT_TYPE"; then
        print_error "Android project preparation failed"
        exit 1
    fi

    # [AI GENERATED CODE] Step 8: Validate signing configuration
    validate_signing_config "$BUILD_TYPE"

    # Step 9: Build Android app
    if ! build_android_app "$BUILD_FLAVOR" "$BUILD_TYPE" "$EXPORT_TYPE"; then
        print_error "Android app build failed"
        exit 1
    fi

    # Step 10: Copy build output
    if ! copy_build_output "$BUILD_FLAVOR" "$BUILD_TYPE" "$EXPORT_TYPE"; then
        print_error "Failed to copy build output"
        exit 1
    fi

    # Step 11: Restore build.gradle (cleanup)
    restore_build_gradle "$BUILD_FLAVOR"

    echo ""
    print_message "$GREEN" "================================================"
    print_success "Build process completed successfully!"
    print_message "$GREEN" "================================================"
    echo ""
    print_info "Build output location: $BUILD_OUTPUT_DIR"
}

# Main function for WWW build
main_www_build() {
    print_message "$GREEN" "================================================"
    print_message "$GREEN" "  WWW Build Automation Script"
    print_message "$GREEN" "  SplashLearn - iOS Content Build"
    print_message "$GREEN" "================================================"
    echo ""

    # Verify directories exist
    if [ ! -d "$OMNIJS_DIR" ]; then
        print_error "omnijs directory not found at: $OMNIJS_DIR"
        exit 1
    fi

    if [ ! -d "$OMNI_CONTENT_DIR" ]; then
        print_error "omni-content directory not found at: $OMNI_CONTENT_DIR"
        exit 1
    fi

    if [ ! -d "$CONTENT_GAMES_DIR" ]; then
        print_error "content-games directory not found at: $CONTENT_GAMES_DIR"
        exit 1
    fi

    # Prompt for branch names
    print_message "$YELLOW" "Build Configuration"
    echo ""

    OMNIJS_BRANCH=$(prompt_input "Enter branch name for omnijs")
    OMNI_CONTENT_BRANCH=$(prompt_input "Enter branch name for omni-content")
    CONTENT_GAMES_BRANCH=$(prompt_input "Enter branch name for content-games")

    # Summary
    echo ""
    print_message "$YELLOW" "Build Summary"
    echo "  omnijs branch:        $OMNIJS_BRANCH"
    echo "  omni-content branch:  $OMNI_CONTENT_BRANCH"
    echo "  content-games branch: $CONTENT_GAMES_BRANCH"
    echo ""

    if ! prompt_yes_no "Proceed with www build?"; then
        print_warning "Build cancelled by user"
        exit 0
    fi

    echo ""
    print_message "$GREEN" "Starting www build process..."
    echo ""

    # Step 1: Clean all repositories
    clean_www_repos

    # Step 2: Checkout branches
    checkout_www_branches "$OMNIJS_BRANCH" "$OMNI_CONTENT_BRANCH" "$CONTENT_GAMES_BRANCH"

    # Step 3: Build content-games
    build_content_games

    # Step 4: Restore omnijs
    restore_omnijs

    # Step 5: Compress and move www folder
    compress_and_move_www

    echo ""
    print_message "$GREEN" "================================================"
    print_success "WWW build process completed successfully!"
    print_message "$GREEN" "================================================"
    echo ""
    print_info "Build output location: $WWW_BUILDS_DIR"
}

# Main script execution - Choose between Android or WWW build
main() {
    print_message "$GREEN" "================================================"
    print_message "$GREEN" "  Build Automation Script"
    print_message "$GREEN" "  SplashLearn"
    print_message "$GREEN" "================================================"
    echo ""

    print_info "Select build type:"
    echo "  1) Android Build"
    echo "  2) WWW Build (iOS Content)"
    printf "${BLUE}Enter choice [1-2]${NC}: "
    read build_choice

    echo ""

    case $build_choice in
        1)
            main_android_build
            ;;
        2)
            main_www_build
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
