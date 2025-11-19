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
BUILD_OUTPUT_DIR="$SP_ANDROID_DIR/android_app_build"

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

# Function to prepare Android build
prepare_android_build() {
    local flavor=$1
    local export_type=$2

    print_info "Preparing Android project for build..."
    cd "$SP_ANDROID_DIR"

    # Run gradle clean
    print_info "Running gradle clean..."
    ./gradlew clean

    # Delete libil2cpp.so files for AAB builds
    if [ "$export_type" = "aab" ]; then
        print_info "Deleting libil2cpp.so files for AAB build..."
        find unityLibrary -name "libil2cpp.so" -type f -delete
        print_success "Deleted all libil2cpp.so files"
    fi

    # Comment out applicationIdSuffix for dev builds
    if [ "$flavor" = "dev" ]; then
        print_info "Commenting out applicationIdSuffix for dev build..."
        local build_gradle="app/build.gradle"
        if [ -f "$build_gradle" ]; then
            sed -i.bak "s|^\([[:space:]]*\)applicationIdSuffix '.debug1'|            // applicationIdSuffix '.debug1'|" "$build_gradle"
            rm -f "$build_gradle.bak"
            print_success "applicationIdSuffix commented out"
        fi
    fi

    print_success "Android project preparation complete"
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

# Function to build Android app
build_android_app() {
    local flavor=$1
    local build_type=$2
    local export_type=$3

    print_info "Building Android app..."
    cd "$SP_ANDROID_DIR"

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
    ./gradlew "$gradle_task"

    print_success "Build completed successfully"
}

# Function to copy build output
copy_build_output() {
    local flavor=$1
    local build_type=$2
    local export_type=$3

    print_info "Copying build output to $BUILD_OUTPUT_DIR..."
    cd "$SP_ANDROID_DIR"

    # Create output directory
    mkdir -p "$BUILD_OUTPUT_DIR"

    # Capitalize first letter for Gradle path (bash 3.2 compatible)
    local flavor_cap="$(tr '[:lower:]' '[:upper:]' <<< ${flavor:0:1})${flavor:1}"
    local build_type_cap="$(tr '[:lower:]' '[:upper:]' <<< ${build_type:0:1})${build_type:1}"

    # Determine source path
    local build_dir="app/build/outputs"
    if [ "$export_type" = "apk" ]; then
        local source_path="$build_dir/apk/$flavor/$build_type/"
        local file_pattern="*.apk"
    else
        local source_path="$build_dir/bundle/${flavor_cap}${build_type_cap}/"
        local file_pattern="*.aab"
    fi

    # Copy files
    if [ -d "$source_path" ]; then
        local timestamp=$(date +"%Y%m%d_%H%M%S")
        local dest_dir="$BUILD_OUTPUT_DIR/${flavor}_${build_type}_${export_type}_${timestamp}"
        mkdir -p "$dest_dir"

        find "$source_path" -name "$file_pattern" -exec cp {} "$dest_dir/" \;

        print_success "Build output copied to: $dest_dir"

        # List copied files
        print_info "Build files:"
        ls -lh "$dest_dir"
    else
        print_error "Build output directory not found: $source_path"
        return 1
    fi
}

# Main script execution
main() {
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
    print_info "Select build flavor:"
    echo "  1) dev"
    echo "  2) prod"
    printf "${BLUE}Enter choice [1-2]${NC}: "
    read flavor_choice

    case $flavor_choice in
        1) BUILD_FLAVOR="dev" ;;
        2) BUILD_FLAVOR="prod" ;;
        *) print_error "Invalid choice"; exit 1 ;;
    esac

    echo ""
    print_info "Select build type:"
    echo "  1) debug"
    echo "  2) profile"
    echo "  3) release"
    printf "${BLUE}Enter choice [1-3]${NC}: "
    read build_type_choice

    case $build_type_choice in
        1) BUILD_TYPE="debug" ;;
        2) BUILD_TYPE="profile" ;;
        3) BUILD_TYPE="release" ;;
        *) print_error "Invalid choice"; exit 1 ;;
    esac

    echo ""
    print_info "Select export type:"
    echo "  1) apk"
    echo "  2) aab"
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

    # Summary
    echo ""
    print_message "$YELLOW" "Build Summary"
    echo "  sp-android branch:   $SP_ANDROID_BRANCH"
    echo "  flutter_app branch:  $FLUTTER_APP_BRANCH"
    echo "  Build flavor:        $BUILD_FLAVOR"
    echo "  Build type:          $BUILD_TYPE"
    echo "  Export type:         $EXPORT_TYPE"
    echo "  Recreate Flutter:    $RECREATE_FLUTTER"
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
    prepare_android_build "$BUILD_FLAVOR" "$EXPORT_TYPE"

    # Step 8: Build Android app
    build_android_app "$BUILD_FLAVOR" "$BUILD_TYPE" "$EXPORT_TYPE"

    # Step 9: Copy build output
    copy_build_output "$BUILD_FLAVOR" "$BUILD_TYPE" "$EXPORT_TYPE"

    # Step 10: Restore build.gradle (cleanup)
    restore_build_gradle "$BUILD_FLAVOR"

    echo ""
    print_message "$GREEN" "================================================"
    print_success "Build process completed successfully!"
    print_message "$GREEN" "================================================"
    echo ""
    print_info "Build output location: $BUILD_OUTPUT_DIR"
}

# Run main function
main "$@"
