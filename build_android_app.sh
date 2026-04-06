#!/bin/bash

# [AI GENERATED CODE]
# Build Orchestrator Script for SplashLearn
# Main entry point that routes to Android or WWW builds

set -e  # Exit on error

# Enable echo to interpret escape sequences
shopt -s xpg_echo 2>/dev/null || true

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Main orchestrator function
main() {
    print_message "$GREEN" "================================================"
    print_message "$GREEN" "  SplashLearn Build Automation"
    print_message "$GREEN" "  Build Type Selector"
    print_message "$GREEN" "================================================"
    echo ""

    print_info "Select build type:"
    echo "  1) Android Build (APK/AAB with embedded Flutter)"
    echo "  2) WWW Build (iOS Web Content)"
    printf "${BLUE}Enter choice [1-2]${NC}: " >&2
    read build_choice

    echo ""

    case $build_choice in
        1)
            print_info "Loading Android Build Script..."
            source "$SCRIPT_DIR/android_build.sh"
            main_android_build
            ;;
        2)
            print_info "Loading WWW Build Script..."
            source "$SCRIPT_DIR/www_build.sh"
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
