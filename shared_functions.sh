#!/bin/bash

# [AI GENERATED CODE]
# Shared Functions for SplashLearn Build Automation
# Contains common utility functions used by both Android and WWW builds

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
PLAYABLE_DOWNLOADER_DIR="$SCRIPT_DIR/../playable-downloader"
ANDROID_ASSETS_DIR="$SCRIPT_DIR/../android_assets_non_ios"
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

    # Verify this is a git repository
    if [ ! -d ".git" ]; then
        print_error "$repo_name is not a valid git repository"
        exit 1
    fi

    # Fetch latest changes from remote
    git fetch origin

    # Force checkout to the branch
    git checkout -f "$branch_name"

    # Check if local and remote have diverged
    LOCAL=$(git rev-parse @ 2>/dev/null || echo "")
    REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "")
    BASE=$(git merge-base @ @{u} 2>/dev/null || echo "")

    if [ "$LOCAL" = "$REMOTE" ]; then
        print_info "Branch is up to date with remote"
    elif [ "$LOCAL" = "$BASE" ]; then
        # Local is behind remote - can fast-forward
        print_info "Local branch is behind remote, updating..."
        git pull origin "$branch_name"
    elif [ "$REMOTE" = "$BASE" ]; then
        # Local is ahead of remote
        print_warning "Local branch is ahead of remote by $(git rev-list --count @{u}..@ 2>/dev/null || echo '?') commits"
        print_warning "Resetting to remote state for clean build..."
        git reset --hard "origin/$branch_name"
    else
        # Branches have diverged
        local local_commits=$(git rev-list --count @{u}..@ 2>/dev/null || echo '?')
        local remote_commits=$(git rev-list --count ..@{u} 2>/dev/null || echo '?')
        print_warning "Branches have diverged (local: $local_commits commits, remote: $remote_commits commits)"
        print_warning "Resetting to remote state for clean build..."
        git reset --hard "origin/$branch_name"
    fi

    print_success "Switched to branch '$branch_name' in $repo_name"
}

# Function to checkout tag
checkout_tag() {
    local repo_dir=$1
    local tag_name=$2
    local repo_name=$3

    print_info "Checking out tag '$tag_name' in $repo_name..."
    cd "$repo_dir"

    # Verify this is a git repository
    if [ ! -d ".git" ]; then
        print_error "$repo_name is not a valid git repository"
        exit 1
    fi

    # Fetch all tags from remote
    print_info "Fetching tags from remote..."
    git fetch --tags origin

    # Verify tag exists
    if ! git rev-parse "$tag_name" >/dev/null 2>&1; then
        print_error "Tag '$tag_name' does not exist in $repo_name"
        print_info "Available tags:"
        git tag -l | tail -10
        exit 1
    fi

    # Checkout the tag (this will be in detached HEAD state)
    if git checkout -f "tags/$tag_name"; then
        print_success "Checked out tag '$tag_name' in $repo_name"
        print_warning "Note: You are in 'detached HEAD' state (this is normal for tag checkouts)"

        # Show tag details
        local tag_commit=$(git rev-parse --short HEAD)
        local tag_date=$(git log -1 --format=%ai HEAD)
        print_info "Tag commit: $tag_commit"
        print_info "Tag date: $tag_date"
    else
        print_error "Failed to checkout tag '$tag_name' in $repo_name"
        exit 1
    fi

    print_success "Tag checkout complete for $repo_name"
}
