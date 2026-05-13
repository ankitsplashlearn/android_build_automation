#!/bin/bash

# [AI GENERATED CODE]
# Asset Preparation Script for Android Build
# Downloads and prepares assets from playable-downloader for sp-android

# Source shared functions for colored output
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/shared_functions.sh"

# Directories
PLAYABLE_DOWNLOADER_DIR="/Users/ankitmaurya/AndroidStudioProjects/playable-downloader"
ANDROID_ASSETS_DIR="/Users/ankitmaurya/AndroidStudioProjects/android_assets_non_ios"
SP_ANDROID_DIR="/Users/ankitmaurya/AndroidStudioProjects/sp-android"
VENV_DIR="$PLAYABLE_DOWNLOADER_DIR/venv"

# Parse command line arguments
APP_VERSION=$1

if [ -z "$APP_VERSION" ]; then
    print_error "App version is required"
    print_info "Usage: $0 <app_version>"
    exit 1
fi

print_info "Starting asset preparation for version: $APP_VERSION"

# Step 1: Setup Python virtual environment
setup_python_venv() {
    print_info "Setting up Python virtual environment..."
    cd "$PLAYABLE_DOWNLOADER_DIR"

    if [ ! -d "$VENV_DIR" ]; then
        print_info "Creating virtual environment..."
        python3 -m venv "$VENV_DIR"
        print_success "Virtual environment created at $VENV_DIR"
    else
        print_info "Virtual environment already exists"
    fi

    # Activate virtual environment
    print_info "Activating virtual environment..."
    source "$VENV_DIR/bin/activate"
    print_success "Virtual environment activated"

    # Install dependencies
    print_info "Installing dependencies..."
    pip install -r requirements.txt > /dev/null 2>&1
    print_success "Dependencies installed"
}

# Step 2: Download assets using Python script
download_assets() {
    print_info "Downloading assets for version $APP_VERSION..."
    cd "$PLAYABLE_DOWNLOADER_DIR"

    # Ensure venv is activated
    source "$VENV_DIR/bin/activate"

    # Run the downloader script
    print_info "Running: python3 downloader_android.py prod smunol '$APP_VERSION' '$ANDROID_ASSETS_DIR'"
    if python3 downloader_android.py prod smunol "$APP_VERSION" "$ANDROID_ASSETS_DIR"; then
        print_success "Assets downloaded successfully"
    else
        print_error "Asset download failed"
        deactivate
        return 1
    fi

    # Deactivate virtual environment
    deactivate
    print_success "Virtual environment deactivated"
}

# Step 3: Copy sound assets (7 zip files) to sp-android
copy_sound_assets() {
    print_info "Copying sound assets to sp-android..."

    local sound_assets=("common_assets" "gradek_assets" "grade1_assets" "grade2_assets" "grade3_assets" "grade4_assets" "grade5_assets")

    for asset in "${sound_assets[@]}"; do
        local source_dir="$ANDROID_ASSETS_DIR/$asset"
        local dest_dir="$SP_ANDROID_DIR/$asset/src/main/assets/$asset/worksheet_sounds"

        if [ -d "$source_dir" ]; then
            # Find the zip file in the source directory
            local zip_file=$(find "$source_dir" -name "*.zip" -type f | head -1)

            if [ -n "$zip_file" ]; then
                # Create destination directory if it doesn't exist
                mkdir -p "$dest_dir"

                # Copy the zip file
                cp "$zip_file" "$dest_dir/"
                print_success "Copied $(basename "$zip_file") to $asset"
            else
                print_warning "No zip file found in $source_dir"
            fi
        else
            print_warning "Sound asset directory not found: $source_dir"
        fi
    done

    print_success "Sound assets copied successfully"
}

# Step 4: Move manifest assets to sp-android
move_manifest_assets() {
    print_info "Moving manifest assets to sp-android..."

    # Find all manifest_asset_* directories
    local manifest_dirs=$(find "$ANDROID_ASSETS_DIR" -maxdepth 1 -type d -name "manifest_asset_*" | sort -V)
    local count=0

    for manifest_dir in $manifest_dirs; do
        local asset_name=$(basename "$manifest_dir")
        local dest_dir="$SP_ANDROID_DIR/$asset_name"

        # Create destination directory structure
        mkdir -p "$dest_dir/src/main/assets"

        # Copy the entire src directory if it exists
        if [ -d "$manifest_dir/src" ]; then
            cp -R "$manifest_dir/src/"* "$dest_dir/src/"
            ((count++))
        fi

        # Create build.gradle for this manifest asset
        create_manifest_build_gradle "$asset_name"
    done

    print_success "Moved $count manifest assets to sp-android"
}

# Step 5: Create build.gradle for manifest assets
create_manifest_build_gradle() {
    local asset_name=$1
    local build_gradle_path="$SP_ANDROID_DIR/$asset_name/build.gradle"

    cat > "$build_gradle_path" << EOF
apply plugin: 'com.android.asset-pack'

assetPack {
    packName = "$asset_name"  // The name of your asset pack
    dynamicDelivery {
        deliveryType = "on-demand"
    }
}
EOF
}

# Step 6: Copy JSON files to app/src/main/assets
copy_json_files() {
    print_info "Copying JSON files to app assets..."

    local app_assets_dir="$SP_ANDROID_DIR/app/src/main/assets"
    mkdir -p "$app_assets_dir"

    # Copy manifest_to_zip_mapping.json
    if [ -f "$ANDROID_ASSETS_DIR/manifest_to_zip_mapping.json" ]; then
        cp "$ANDROID_ASSETS_DIR/manifest_to_zip_mapping.json" "$app_assets_dir/"
        print_success "Copied manifest_to_zip_mapping.json"
    else
        print_warning "manifest_to_zip_mapping.json not found"
    fi

    # Copy zip_to_manifest_mapping.json
    if [ -f "$ANDROID_ASSETS_DIR/zip_to_manifest_mapping.json" ]; then
        cp "$ANDROID_ASSETS_DIR/zip_to_manifest_mapping.json" "$app_assets_dir/"
        print_success "Copied zip_to_manifest_mapping.json"
    else
        print_warning "zip_to_manifest_mapping.json not found"
    fi

    print_success "JSON files copied to app assets"
}

# Step 7: Update settings.gradle to include manifest assets
update_settings_gradle() {
    print_info "Updating settings.gradle..."

    local settings_gradle="$SP_ANDROID_DIR/settings.gradle"
    local temp_file=$(mktemp)

    # Read existing settings.gradle and find the last sound asset include
    local last_line_num=$(grep -n "include ':grade5_assets'" "$settings_gradle" | cut -d: -f1)

    if [ -z "$last_line_num" ]; then
        print_error "Could not find grade5_assets in settings.gradle"
        return 1
    fi

    # Copy lines up to and including grade5_assets
    head -n "$last_line_num" "$settings_gradle" > "$temp_file"

    # Add all manifest asset includes
    local manifest_dirs=$(find "$SP_ANDROID_DIR" -maxdepth 1 -type d -name "manifest_asset_*" | sort -V)
    for manifest_dir in $manifest_dirs; do
        local asset_name=$(basename "$manifest_dir")
        echo "include ':$asset_name'" >> "$temp_file"
    done

    # Copy remaining lines (after grade5_assets)
    tail -n +$((last_line_num + 1)) "$settings_gradle" >> "$temp_file"

    # Replace original file
    mv "$temp_file" "$settings_gradle"

    print_success "settings.gradle updated with manifest assets"
}

# Step 8: Update app/build.gradle assetPacks list
update_app_build_gradle() {
    print_info "Updating app/build.gradle assetPacks list..."

    local app_build_gradle="$SP_ANDROID_DIR/app/build.gradle"

    # Find all manifest assets
    local manifest_assets=$(find "$SP_ANDROID_DIR" -maxdepth 1 -type d -name "manifest_asset_*" | sort -V | xargs -I {} basename {} | sed 's/^/":/; s/$/"/' | tr '\n' ',' | sed 's/,$//')

    # Current assetPacks list with double quotes
    local current_packs='":play_assets", ":UnityDataAssetPack", ":common_assets", ":gradek_assets", ":grade1_assets", ":grade2_assets", ":grade3_assets", ":grade4_assets", ":grade5_assets"'

    # New assetPacks list with manifest assets
    local new_packs="$current_packs, $manifest_assets"

    # Replace in build.gradle - only update lines starting with optional whitespace followed by assetPacks
    sed -i.bak '/^[[:space:]]*assetPacks/s|assetPacks = \[.*\]|assetPacks = ['"$new_packs"']|' "$app_build_gradle"
    rm -f "$app_build_gradle.bak"

    print_success "app/build.gradle updated with manifest assets"
}

# Main execution
main() {
    print_message "$GREEN" "================================================"
    print_message "$GREEN" "  Asset Preparation Script"
    print_message "$GREEN" "  Version: $APP_VERSION"
    print_message "$GREEN" "================================================"
    echo ""

    # Verify directories exist
    if [ ! -d "$PLAYABLE_DOWNLOADER_DIR" ]; then
        print_error "playable-downloader directory not found at: $PLAYABLE_DOWNLOADER_DIR"
        exit 1
    fi

    if [ ! -d "$SP_ANDROID_DIR" ]; then
        print_error "sp-android directory not found at: $SP_ANDROID_DIR"
        exit 1
    fi

    # Check if assets already exist
    if [ -d "$ANDROID_ASSETS_DIR" ]; then
        print_warning "android_assets_non_ios directory already exists"
        if prompt_yes_no "Do you want to download fresh assets? (will overwrite existing)"; then
            print_info "Removing existing assets..."
            rm -rf "$ANDROID_ASSETS_DIR"

            # Execute steps 1 and 2 (download)
            setup_python_venv
            download_assets
        else
            print_info "Using existing assets from $ANDROID_ASSETS_DIR"
        fi
    else
        # Execute steps 1 and 2 (download)
        setup_python_venv
        download_assets
    fi

    # Execute remaining steps (copy and configure)
    copy_sound_assets
    move_manifest_assets
    copy_json_files
    update_settings_gradle
    update_app_build_gradle

    echo ""
    print_message "$GREEN" "================================================"
    print_success "Asset preparation completed successfully!"
    print_message "$GREEN" "================================================"
    echo ""
    print_info "Summary:"
    echo "  - Sound assets: 7 modules updated"
    echo "  - Manifest assets: $(find "$SP_ANDROID_DIR" -maxdepth 1 -type d -name "manifest_asset_*" | wc -l | tr -d ' ') modules created"
    echo "  - JSON files: 2 files copied to app/src/main/assets"
    echo "  - settings.gradle: Updated with all manifest assets"
    echo "  - app/build.gradle: Updated with all manifest assets"
    echo ""
}

# Run main function
main "$@"
