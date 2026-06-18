#!/bin/bash

# [AI GENERATED CODE]
# WWW Build Automation Script for SplashLearn
# Handles iOS web content build for www assets

# Source shared functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/shared_functions.sh"

# Function to clean all three repos for www build
clean_www_repos() {
    print_info "Cleaning all repositories for www build..."

    clean_git_repo "$OMNIJS_DIR" "omnijs"
    clean_git_repo "$OMNI_CONTENT_DIR" "omni-content"
    clean_git_repo "$CONTENT_GAMES_DIR" "content-games"

    print_success "All repositories cleaned"
}

# Function to checkout branches or tags for www build
checkout_www_refs() {
    local omnijs_ref=$1
    local omni_content_ref=$2
    local content_games_ref=$3
    local build_source=$4

    if [ "$build_source" = "tag" ]; then
        print_info "Checking out tags in all repositories..."

        checkout_tag "$OMNIJS_DIR" "$omnijs_ref" "omnijs"
        checkout_tag "$OMNI_CONTENT_DIR" "$omni_content_ref" "omni-content"
        checkout_tag "$CONTENT_GAMES_DIR" "$content_games_ref" "content-games"

        print_success "All repositories switched to their respective tags"
    else
        print_info "Checking out branches in all repositories..."

        checkout_branch "$OMNIJS_DIR" "$omnijs_ref" "omnijs"
        checkout_branch "$OMNI_CONTENT_DIR" "$omni_content_ref" "omni-content"
        checkout_branch "$CONTENT_GAMES_DIR" "$content_games_ref" "content-games"

        print_success "All repositories switched to their respective branches"
    fi
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

# Main WWW build function
main_www_build() {
    print_message "$GREEN" "================================================"
    print_message "$GREEN" "  WWW Build Automation Script"
    print_message "$GREEN" "  SplashLearn - iOS Content Build"
    print_message "$GREEN" "================================================"
    echo ""

    # Verify directories exist
    local missing_repos=()

    if [ ! -d "$OMNIJS_DIR" ]; then
        missing_repos+=("omnijs at: $OMNIJS_DIR")
    fi

    if [ ! -d "$OMNI_CONTENT_DIR" ]; then
        missing_repos+=("omni-content at: $OMNI_CONTENT_DIR")
    fi

    if [ ! -d "$CONTENT_GAMES_DIR" ]; then
        missing_repos+=("content-games at: $CONTENT_GAMES_DIR")
    fi

    if [ ${#missing_repos[@]} -gt 0 ]; then
        print_error "Required repositories not found on this system:"
        for repo in "${missing_repos[@]}"; do
            echo "  - $repo"
        done
        echo ""
        print_info "Please clone the missing repositories or run this script on a system where they exist."
        exit 1
    fi

    # Prompt for build configuration
    print_message "$YELLOW" "Build Configuration"
    echo ""

    # Select build source (branch or tag)
    print_info "Select build source:"
    echo "  1) branch  (Build from branch)"
    echo "  2) tag     (Build from tag)"
    printf "${BLUE}Enter choice [1-2]${NC}: "
    read source_choice

    case $source_choice in
        1)
            BUILD_SOURCE="branch"
            OMNIJS_REF=$(prompt_input "Enter branch name for omnijs" "master")
            OMNI_CONTENT_REF=$(prompt_input "Enter branch name for omni-content" "master")
            CONTENT_GAMES_REF=$(prompt_input "Enter branch name for content-games" "master")
            ;;
        2)
            BUILD_SOURCE="tag"
            OMNIJS_REF=$(prompt_input "Enter tag name for omnijs" "v1.0.0")
            OMNI_CONTENT_REF=$(prompt_input "Enter tag name for omni-content" "v1.0.0")
            CONTENT_GAMES_REF=$(prompt_input "Enter tag name for content-games" "v1.0.0")
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac

    # Keep old variable names for backward compatibility
    OMNIJS_BRANCH="$OMNIJS_REF"
    OMNI_CONTENT_BRANCH="$OMNI_CONTENT_REF"
    CONTENT_GAMES_BRANCH="$CONTENT_GAMES_REF"

    # Summary
    echo ""
    print_message "$YELLOW" "Build Summary"
    echo "  Build source:           $BUILD_SOURCE"
    if [ "$BUILD_SOURCE" = "tag" ]; then
        echo "  omnijs tag:             $OMNIJS_REF"
        echo "  omni-content tag:       $OMNI_CONTENT_REF"
        echo "  content-games tag:      $CONTENT_GAMES_REF"
    else
        echo "  omnijs branch:          $OMNIJS_REF"
        echo "  omni-content branch:    $OMNI_CONTENT_REF"
        echo "  content-games branch:   $CONTENT_GAMES_REF"
    fi
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

    # Step 2: Checkout branches or tags
    checkout_www_refs "$OMNIJS_REF" "$OMNI_CONTENT_REF" "$CONTENT_GAMES_REF" "$BUILD_SOURCE"

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
