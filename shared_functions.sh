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

# [AI GENERATED CODE] ---------------------------------------------------------
# Non-interactive mode
#
# When NON_INTERACTIVE=true, every prompt is answered from a pre-set variable
# instead of reading stdin, so the script can be driven by another program (the
# Slack remote-terminal-manager) without piping positional answers - which
# silently answers the WRONG question whenever a prompt is added, removed, or
# made conditional (this script has several conditional prompts).
#
# Interactive behaviour is unchanged: with NON_INTERACTIVE unset/false every
# prompt reads stdin exactly as before.
#
# answer_for <VAR_NAME> <prompt> [default]
#   Non-interactive: echo $VAR_NAME (or the default if unset/empty); fails loudly
#   if there is neither a value nor a default, rather than silently building the
#   wrong variant.
#   Interactive: falls through to the normal prompt.
NON_INTERACTIVE="${NON_INTERACTIVE:-false}"

is_non_interactive() {
    [ "$NON_INTERACTIVE" = "true" ]
}

answer_for() {
    local var_name=$1
    local prompt_message=$2
    local default_value=$3
    local optional=$4          # "optional" -> empty is a valid answer, not an error
    local preset="${!var_name}"

    if is_non_interactive; then
        if [ -z "$preset" ]; then
            preset="$default_value"
        fi
        if [ -z "$preset" ] && [ "$optional" = "optional" ]; then
            # [AI GENERATED CODE] Genuinely optional input (e.g. the
            # speech_to_text ref, whose prompt says "leave empty to skip") -
            # empty is the skip signal, not a missing answer.
            echo ""
            return 0
        fi
        if [ -z "$preset" ]; then
            print_error "Non-interactive mode: no value for $var_name (prompt: $prompt_message)" >&2
            exit 1
        fi
        printf "${BLUE}${prompt_message}${NC}: ${preset} (preset)\n" >&2
        echo "$preset"
        return 0
    fi

    prompt_input "$prompt_message" "$default_value"
}

# [AI GENERATED CODE] answer_yes_no <VAR_NAME> <prompt>
#   Non-interactive: returns 0/1 from $VAR_NAME (yes/y/true -> yes). An unset
#   variable means "no", matching the interactive [y/N] default.
answer_yes_no() {
    local var_name=$1
    local prompt_message=$2
    local preset="${!var_name}"

    if is_non_interactive; then
        printf "${BLUE}${prompt_message}${NC} [y/N]: ${preset:-n} (preset)\n" >&2
        case "$preset" in
            [yY][eE][sS]|[yY]|true|TRUE) return 0 ;;
            *) return 1 ;;
        esac
    fi

    prompt_yes_no "$prompt_message"
}

# [AI GENERATED CODE] answer_choice <VAR_NAME> <prompt> <valid-choice>...
#   For the numbered menus, which read stdin directly rather than via
#   prompt_input. Accepts either the menu NUMBER or the human-readable name
#   (e.g. "2" or "profile"), and echoes back the menu number the caller's
#   existing `case` already understands - so callers keep their current logic.
answer_choice() {
    local var_name=$1
    local prompt_message=$2
    shift 2
    local choices=("$@")
    local preset="${!var_name}"
    local reply

    if is_non_interactive; then
        if [ -z "$preset" ]; then
            print_error "Non-interactive mode: no value for $var_name (prompt: $prompt_message)" >&2
            exit 1
        fi
        local index=1
        for choice in "${choices[@]}"; do
            if [ "$preset" = "$index" ] || [ "$preset" = "$choice" ]; then
                printf "${BLUE}${prompt_message}${NC}: ${choice} (preset)\n" >&2
                echo "$index"
                return 0
            fi
            index=$((index + 1))
        done
        print_error "Non-interactive mode: invalid $var_name='$preset' (valid: ${choices[*]})" >&2
        exit 1
    fi

    printf "${BLUE}${prompt_message}${NC}: " >&2
    read reply
    echo "$reply"
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

    # Fetch all tags from remote (force update to overwrite local tags)
    print_info "Fetching tags from remote..."
    git fetch --tags --force origin

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

# [AI GENERATED CODE] ---------------------------------------------------------
# CLI argument parsing for non-interactive runs.
#
# parse_build_args "$@"  - sets the NON_INTERACTIVE flag and the per-prompt
# preset variables consumed by answer_for / answer_yes_no / answer_choice.
# Passing NO arguments leaves NON_INTERACTIVE=false, so the interactive flow is
# completely unchanged for humans running `sh build_android_app.sh`.
#
# Values accept either the menu number or the readable name ("2" or "profile").
print_build_usage() {
    cat >&2 <<'USAGE'
Usage: build_android_app.sh [options]

  Run with NO options for the normal interactive prompts.
  Any option below switches the script to non-interactive mode: every prompt is
  answered from these values instead of stdin.

  --target <android|www>              which build to run (default: android)
  --source <branch|tag>               build from branches or tags (default: branch)
  --sp-android <ref>                  sp-android branch/tag
  --flutter-app <ref>                 flutter_app branch/tag
  --playable-downloader <ref>         playable-downloader branch/tag (default: master)
  --speech-to-text <ref>              speech_to_text_flutter branch/tag (optional)
  --flavor <dev|prod>                 build environment
  --store <android|amazon>            target store (default: android)
  --type <debug|profile|release>      build type
  --export <apk|aab>                  export type
  --generate-assets <yes|no>          android+aab+prod only (default: no)
  --asset-version <version>           app version for asset download
  --download-fresh-assets <yes|no>    overwrite existing assets (default: yes)
  --recreate-flutter <yes|no>         recreate Flutter module (default: no)
  -y, --yes                           auto-confirm the "Proceed with build?" prompt
  -h, --help                          show this help
USAGE
}

parse_build_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --target)                 BUILD_TARGET_PRESET="$2"; NON_INTERACTIVE=true; shift 2 ;;
            --source)                 BUILD_SOURCE_PRESET="$2"; NON_INTERACTIVE=true; shift 2 ;;
            --sp-android)             SP_ANDROID_REF_PRESET="$2"; NON_INTERACTIVE=true; shift 2 ;;
            --flutter-app)            FLUTTER_APP_REF_PRESET="$2"; NON_INTERACTIVE=true; shift 2 ;;
            --playable-downloader)    PLAYABLE_DOWNLOADER_REF_PRESET="$2"; NON_INTERACTIVE=true; shift 2 ;;
            --speech-to-text)         SPEECH_TO_TEXT_REF_PRESET="$2"; NON_INTERACTIVE=true; shift 2 ;;
            --flavor)                 BUILD_FLAVOR_PRESET="$2"; NON_INTERACTIVE=true; shift 2 ;;
            --store)                  BUILD_STORE_PRESET="$2"; NON_INTERACTIVE=true; shift 2 ;;
            --type)                   BUILD_TYPE_PRESET="$2"; NON_INTERACTIVE=true; shift 2 ;;
            --export)                 EXPORT_TYPE_PRESET="$2"; NON_INTERACTIVE=true; shift 2 ;;
            --generate-assets)        GENERATE_ASSETS_PRESET="$2"; NON_INTERACTIVE=true; shift 2 ;;
            --asset-version)          ASSET_VERSION_PRESET="$2"; NON_INTERACTIVE=true; shift 2 ;;
            --download-fresh-assets)  DOWNLOAD_FRESH_ASSETS_PRESET="$2"; NON_INTERACTIVE=true; shift 2 ;;
            --recreate-flutter)       RECREATE_FLUTTER_PRESET="$2"; NON_INTERACTIVE=true; shift 2 ;;
            -y|--yes)                 PROCEED_PRESET="yes"; NON_INTERACTIVE=true; shift ;;
            --non-interactive)        NON_INTERACTIVE=true; shift ;;
            -h|--help)                print_build_usage; exit 0 ;;
            *)
                print_error "Unknown option: $1"
                print_build_usage
                exit 1
                ;;
        esac
    done

    # [AI GENERATED CODE] Validate up front, in THIS shell. answer_choice's own
    # `exit 1` runs inside a $( ) subshell at the call sites, which kills only
    # the subshell - the parent would carry on with an empty choice and build
    # some other variant. Checking here means a bad value stops the run before
    # any checkout or gradle work begins.
    validate_preset() {
        local var_name=$1
        shift
        local value="${!var_name}"
        [ -z "$value" ] && return 0          # unset is fine; defaults/prompts handle it
        local index=1
        for choice in "$@"; do
            if [ "$value" = "$index" ] || [ "$value" = "$choice" ]; then
                return 0
            fi
            index=$((index + 1))
        done
        print_error "Invalid value '$value' for ${var_name%_PRESET} (valid: $*)"
        exit 1
    }

    # [AI GENERATED CODE] Sensible defaults so a Slack-style invocation only has
    # to name what actually varies. Applied only in non-interactive mode - they
    # must never pre-answer a prompt a human is about to be asked.
    if is_non_interactive; then
        validate_preset BUILD_TARGET_PRESET android www
        validate_preset BUILD_SOURCE_PRESET branch tag
        validate_preset BUILD_FLAVOR_PRESET dev prod
        validate_preset BUILD_STORE_PRESET android amazon
        validate_preset BUILD_TYPE_PRESET debug profile release
        validate_preset EXPORT_TYPE_PRESET apk aab

        BUILD_TARGET_PRESET="${BUILD_TARGET_PRESET:-android}"
        BUILD_SOURCE_PRESET="${BUILD_SOURCE_PRESET:-branch}"
        BUILD_STORE_PRESET="${BUILD_STORE_PRESET:-android}"
        PLAYABLE_DOWNLOADER_REF_PRESET="${PLAYABLE_DOWNLOADER_REF_PRESET:-master}"
        GENERATE_ASSETS_PRESET="${GENERATE_ASSETS_PRESET:-no}"
        DOWNLOAD_FRESH_ASSETS_PRESET="${DOWNLOAD_FRESH_ASSETS_PRESET:-yes}"
        RECREATE_FLUTTER_PRESET="${RECREATE_FLUTTER_PRESET:-no}"
        PROCEED_PRESET="${PROCEED_PRESET:-yes}"

        # [AI GENERATED CODE] Required for an android build: these have prompt
        # defaults ("master") that are fine for a human who sees them, but
        # silently building master when the caller meant a release branch is
        # exactly the kind of wrong-variant build this mode must prevent.
        if [ "$BUILD_TARGET_PRESET" = "android" ] || [ "$BUILD_TARGET_PRESET" = "1" ]; then
            # [AI GENERATED CODE] "VAR:flag" pairs so the error names the actual
            # option a caller types, not the internal variable.
            for required in "BUILD_FLAVOR_PRESET:--flavor" \
                            "BUILD_TYPE_PRESET:--type" \
                            "EXPORT_TYPE_PRESET:--export" \
                            "SP_ANDROID_REF_PRESET:--sp-android" \
                            "FLUTTER_APP_REF_PRESET:--flutter-app"; do
                local var_name="${required%%:*}"
                local flag_name="${required#*:}"
                if [ -z "${!var_name}" ]; then
                    print_error "Missing required option $flag_name (non-interactive android build)"
                    print_build_usage
                    exit 1
                fi
            done
        fi

        export NON_INTERACTIVE
    fi
}
