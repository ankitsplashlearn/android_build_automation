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

# [AI GENERATED CODE] Single source of truth for every menu's valid choices.
# ORDER MATTERS: the position in each list IS the menu number the existing
# `case` statements in android_build.sh switch on, so appending a choice is
# safe but reordering one silently remaps the menu. Defined once and used by
# BOTH validate_preset (up-front checking) and answer_choice (at the prompt),
# so the two can never drift apart.
VALID_TARGETS=(android www)
VALID_SOURCES=(branch tag)
VALID_FLAVORS=(dev prod)
VALID_STORES=(android amazon)
VALID_TYPES=(debug profile release)
VALID_EXPORTS=(apk aab)

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
  --distribute <yes|no>               upload to Firebase App Distribution
                                      (default: yes in non-interactive mode)
  -y, --yes                           auto-confirm the "Proceed with build?" prompt
  -h, --help                          show this help
USAGE
}

parse_build_args() {
    # [AI GENERATED CODE] Guard against an option whose value is missing:
    # `--flavor --type debug` would otherwise take "--type" as the flavor and
    # then fail with the confusing "Unknown option: debug". Anything starting
    # with "-" is a flag, never a value.
    require_value() {
        local flag=$1
        local value=$2
        case "$value" in
            ""|-*)
                print_error "$flag requires a value"
                print_build_usage
                exit 1
                ;;
        esac
    }

    while [ $# -gt 0 ]; do
        case "$1" in
            --*|-y|-h)
                # [AI GENERATED CODE] Value-taking options are every long option
                # except the two standalone flags handled below.
                case "$1" in
                    --non-interactive|-y|--yes|-h|--help) ;;
                    *) require_value "$1" "$2" ;;
                esac
                ;;
        esac

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
            --distribute)             DISTRIBUTE_PRESET="$2"; NON_INTERACTIVE=true; shift 2 ;;
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
        validate_preset BUILD_TARGET_PRESET "${VALID_TARGETS[@]}"
        validate_preset BUILD_SOURCE_PRESET "${VALID_SOURCES[@]}"
        validate_preset BUILD_FLAVOR_PRESET "${VALID_FLAVORS[@]}"
        validate_preset BUILD_STORE_PRESET "${VALID_STORES[@]}"
        validate_preset BUILD_TYPE_PRESET "${VALID_TYPES[@]}"
        validate_preset EXPORT_TYPE_PRESET "${VALID_EXPORTS[@]}"

        BUILD_TARGET_PRESET="${BUILD_TARGET_PRESET:-android}"
        BUILD_SOURCE_PRESET="${BUILD_SOURCE_PRESET:-branch}"
        BUILD_STORE_PRESET="${BUILD_STORE_PRESET:-android}"
        PLAYABLE_DOWNLOADER_REF_PRESET="${PLAYABLE_DOWNLOADER_REF_PRESET:-master}"
        GENERATE_ASSETS_PRESET="${GENERATE_ASSETS_PRESET:-no}"
        DOWNLOAD_FRESH_ASSETS_PRESET="${DOWNLOAD_FRESH_ASSETS_PRESET:-yes}"
        RECREATE_FLUTTER_PRESET="${RECREATE_FLUTTER_PRESET:-no}"
        PROCEED_PRESET="${PROCEED_PRESET:-yes}"
        # [AI GENERATED CODE] Distribution defaults ON for non-interactive runs -
        # an automated build exists to be handed to testers, and every failure
        # mode below degrades to a warning rather than losing the build.
        DISTRIBUTE_PRESET="${DISTRIBUTE_PRESET:-yes}"

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

        # [AI GENERATED CODE] www_build.sh still reads stdin directly (it has not
        # been converted to the answer_* helpers), so a non-interactive www run
        # would consume whatever stdin happens to be - dying at its first prompt
        # on a closed stdin, or silently taking the wrong branch names if
        # something is piped in. Reject it here with a clear reason instead.
        # Remove this guard once www_build.sh uses the same helpers.
        if [ "$BUILD_TARGET_PRESET" = "www" ] || [ "$BUILD_TARGET_PRESET" = "2" ]; then
            print_error "Non-interactive mode is not supported for www builds yet."
            print_error "Run 'sh build_android_app.sh' with no options and choose 2) WWW Build."
            exit 1
        fi

        export NON_INTERACTIVE
    fi
}

# [AI GENERATED CODE] ---------------------------------------------------------
# Firebase App Distribution
#
# Mirrors what the iOS side does in CrossPlatformGames2/iOS/fastlane/Fastfile's
# `distribute` lane, reusing the SAME machine-level assets: the service-account
# credentials, the firebase CLI, the tester groups, and the
# firebaseAppIds/<slug>.txt convention for looking up an app id. Uses the
# firebase CLI directly rather than fastlane - this repo has no Ruby/fastlane
# setup, and the CLI call is what the plugin ultimately makes anyway.
FIREBASE_CREDENTIALS="${FIREBASE_CREDENTIALS:-$HOME/Desktop/.DoNotDelete/firebase_creds.json}"
FIREBASE_CLI="${FIREBASE_CLI:-/usr/local/bin/firebase}"
FIREBASE_APP_ID_FILE="${FIREBASE_APP_ID_FILE:-$HOME/Desktop/.DoNotDelete/firebaseAppIds/android.txt}"
FIREBASE_GROUPS="${FIREBASE_GROUPS:-app-testing-team,content-testing-team}"

# [AI GENERATED CODE] Firebase App Distribution rejects uploads over 500MB. The
# iOS lane skips distribution entirely for preshipping/ODR builds for exactly
# this reason; an android AAB with asset packs can plausibly cross it too, so
# check rather than fail the whole build on an upload that cannot succeed.
FIREBASE_MAX_UPLOAD_MB="${FIREBASE_MAX_UPLOAD_MB:-500}"
FIREBASE_UPLOAD_ATTEMPTS="${FIREBASE_UPLOAD_ATTEMPTS:-3}"

# [AI GENERATED CODE] distribute_to_firebase <artifact> <release-notes>
# Never fails the build: the artifact already exists on disk and is reported
# either way, so a distribution problem (missing app id, offline, oversized
# file) is a warning, not a reason to discard a 10-minute build. Prints a plain
# FIREBASE_* result line for callers that parse this script's output.
distribute_to_firebase() {
    local artifact=$1
    local release_notes=$2

    if [ ! -f "$artifact" ]; then
        print_warning "Firebase: artifact not found ($artifact) - skipping distribution"
        echo "FIREBASE_STATUS=skipped:no-artifact"
        return 0
    fi

    if [ ! -x "$FIREBASE_CLI" ] && ! command -v firebase >/dev/null 2>&1; then
        print_warning "Firebase: CLI not found at $FIREBASE_CLI - skipping distribution"
        echo "FIREBASE_STATUS=skipped:no-cli"
        return 0
    fi
    local firebase_bin="$FIREBASE_CLI"
    [ -x "$firebase_bin" ] || firebase_bin="$(command -v firebase)"

    # [AI GENERATED CODE] FIREBASE_APP_ID wins over the file, so a one-off run can
    # target a different app without editing anything on disk.
    local app_id="$FIREBASE_APP_ID"
    if [ -z "$app_id" ]; then
        if [ ! -f "$FIREBASE_APP_ID_FILE" ]; then
            print_warning "Firebase: no app id at $FIREBASE_APP_ID_FILE - skipping distribution"
            print_info "Create it with the Android app id from Firebase Console (e.g. 1:123:android:abc)"
            echo "FIREBASE_STATUS=skipped:no-app-id"
            return 0
        fi
        app_id=$(tr -d '[:space:]' < "$FIREBASE_APP_ID_FILE")
    fi
    if [ -z "$app_id" ]; then
        print_warning "Firebase: app id file $FIREBASE_APP_ID_FILE is empty - skipping distribution"
        echo "FIREBASE_STATUS=skipped:empty-app-id"
        return 0
    fi

    if [ ! -f "$FIREBASE_CREDENTIALS" ]; then
        print_warning "Firebase: credentials not found at $FIREBASE_CREDENTIALS - skipping distribution"
        echo "FIREBASE_STATUS=skipped:no-credentials"
        return 0
    fi

    # [AI GENERATED CODE] stat -f is BSD/macOS (the build machine); -c is GNU.
    local size_bytes
    size_bytes=$(stat -f%z "$artifact" 2>/dev/null || stat -c%s "$artifact" 2>/dev/null || echo 0)
    local size_mb=$((size_bytes / 1024 / 1024))
    # [AI GENERATED CODE] Compare BYTES, not truncated MB: with integer MB a
    # limit of 0 never trips, and a file just over the limit rounds down to
    # exactly the limit and slips through.
    if [ "$size_bytes" -gt $((FIREBASE_MAX_UPLOAD_MB * 1024 * 1024)) ]; then
        print_warning "Firebase: ${size_mb}MB exceeds the ${FIREBASE_MAX_UPLOAD_MB}MB limit - skipping distribution"
        echo "FIREBASE_STATUS=skipped:too-large:${size_mb}MB"
        return 0
    fi

    print_info "Distributing to Firebase (${size_mb}MB, app $app_id)..."
    local attempt=1
    # [AI GENERATED CODE] Declared outside the retry loop: these carry the last
    # attempt's failure out to the reporting block after the loop ends.
    local last_error=""
    local last_status=""
    while [ "$attempt" -le "$FIREBASE_UPLOAD_ATTEMPTS" ]; do
        # [AI GENERATED CODE] The iOS lane retries at the LANE level because a
        # send timeout escapes the plugin's own retry loop; the CLI has the same
        # failure mode, so retry around the whole command here too.
        # [AI GENERATED CODE] Capture the CLI's output instead of letting it go
        # straight to the console: on success it prints the URIs that actually
        # matter (the tester install link and a console link to THIS release, not
        # the project), plus the version it assigned. Tee it so the operator
        # watching a manual run still sees everything live.
        # [AI GENERATED CODE] Piping into `tee` would make the `if` below test
        # TEE's exit status, not the CLI's - and tee virtually always succeeds,
        # so a failed upload would be reported as "uploaded" with nothing to
        # scrape. Capture first, echo afterwards, so the status tested is the
        # firebase CLI's own.
        local cli_output cli_status
        cli_output=$(GOOGLE_APPLICATION_CREDENTIALS="$FIREBASE_CREDENTIALS" "$firebase_bin" \
                appdistribution:distribute "$artifact" \
                --app "$app_id" \
                --groups "$FIREBASE_GROUPS" \
                --release-notes "$release_notes" 2>&1)
        cli_status=$?
        # [AI GENERATED CODE] Echo to stderr so an operator watching a manual run
        # still sees the CLI's output live, as the old `tee` did.
        printf '%s\n' "$cli_output" >&2
        if [ "$cli_status" -eq 0 ]; then
            print_success "Distributed to Firebase App Distribution"
            echo "FIREBASE_STATUS=uploaded"
            echo "FIREBASE_APP=$app_id"

            # [AI GENERATED CODE] Pull the release identity out of the CLI's own
            # output rather than guessing a URL. Each is optional: the CLI's
            # wording has changed across versions, so a missing piece must not
            # turn a successful upload into a reported failure.
            # [AI GENERATED CODE] "uploaded new release 7.3.4 (1042) successfully"
            # -> capture "7.3.4 (1042)": the build number in parentheses is the
            # versionCode, which is what actually distinguishes two uploads of the
            # same version name. Falls back to the bare version if the CLI omits
            # the parenthesised part.
            local version
            version=$(printf '%s\n' "$cli_output" \
                | sed -nE 's/.*uploaded (new )?release ([^ ]+ \([0-9]+\)).*/\2/p' | head -1)
            if [ -z "$version" ]; then
                version=$(printf '%s\n' "$cli_output" \
                    | sed -nE 's/.*uploaded (new )?release ([^ ]+).*/\2/p' | head -1)
            fi
            [ -n "$version" ] && echo "FIREBASE_VERSION=$version"

            local testing_uri
            testing_uri=$(printf '%s\n' "$cli_output" \
                | grep -oE 'https://appdistribution\.firebase\.[^ ]*' | head -1)
            [ -n "$testing_uri" ] && echo "FIREBASE_TESTING_URI=$testing_uri"

            local console_uri
            console_uri=$(printf '%s\n' "$cli_output" \
                | grep -oE 'https://console\.firebase\.google\.com/[^ ]*' | head -1)
            [ -n "$console_uri" ] && echo "FIREBASE_CONSOLE_URI=$console_uri"
            return 0
        fi
        print_warning "Firebase upload failed (attempt ${attempt}/${FIREBASE_UPLOAD_ATTEMPTS}, exit ${cli_status})"
        # [AI GENERATED CODE] Keep the LAST attempt's output: that's the one the
        # final failure is reported for, and each retry can fail differently
        # (a transient timeout, then a hard auth error).
        last_error=$cli_output
        last_status=$cli_status
        attempt=$((attempt + 1))
    done

    print_warning "Firebase distribution failed after ${FIREBASE_UPLOAD_ATTEMPTS} attempts - the build itself is fine"
    echo "FIREBASE_STATUS=failed"
    echo "FIREBASE_EXIT_CODE=${last_status}"
    # [AI GENERATED CODE] The REASON, on stdout, as a machine-readable marker -
    # without it the caller can only say "the upload failed", leaving the actual
    # cause (bad app id, expired credentials, network) buried in a log nobody
    # reads. One line: the CLI's messages are multi-line and the markers are
    # parsed line-by-line, so collapse to the most informative single line -
    # the first line mentioning an error, else the last non-empty line.
    local reason
    reason=$(printf '%s\n' "$last_error" \
        | grep -iE 'error|failed|denied|forbidden|invalid|not found|unauthorized' \
        | head -1)
    if [ -z "$reason" ]; then
        reason=$(printf '%s\n' "$last_error" | grep -v '^[[:space:]]*$' | tail -1)
    fi
    # [AI GENERATED CODE] Strip ANSI colour codes and carriage returns the CLI
    # emits for its spinner - they render as escape gibberish in Slack.
    reason=$(printf '%s' "$reason" | sed -E 's/\x1b\[[0-9;]*[A-Za-z]//g; s/\r//g' | cut -c1-300)
    [ -n "$reason" ] && echo "FIREBASE_ERROR=$reason"
    return 0
}
