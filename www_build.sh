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

# Main WWW build function
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
