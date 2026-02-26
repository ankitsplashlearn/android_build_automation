# SP-Android Build Automation Guide

## Quick Overview

The build automation script (`build_android_app.sh`) supports the sp-android project with:
- **13 modules**: 1 app, 9 asset packs, 1 lib, 1 unity, 1 flutter
- **12 build variants**: 4 flavors × 3 build types
- **2D flavor matrix**: environment (prod/dev) × store (android/amazon)
- **Output formats**: APK and AAB

## Build Variants

```
prodAndroid: debug, profile, release (APK/AAB)
prodAmazon:  debug, profile, release (APK/AAB)
devAndroid:  debug, profile, release (APK/AAB)
devAmazon:   debug, profile, release (APK/AAB)
```

## Quick Reference

### Build Commands

```bash
# Production builds (Google Play)
./build_android_app.sh prodandroid release aab sp-android
./build_android_app.sh prodandroid release apk sp-android

# Production builds (Amazon)
./build_android_app.sh prodamazon release aab sp-android
./build_android_app.sh prodamazon release apk sp-android

# Development builds
./build_android_app.sh devandroid debug apk sp-android
./build_android_app.sh devamazon debug apk sp-android
```

### Build Output Location

Builds are placed in: `android_build_automation/builds/sp-android/`

Structure:
```
builds/
└── sp-android/
    └── {flavor}/
        └── {buildType}/
            └── {export_type}/
                └── YYYYMMDD_HHMMSS/
                    └── app-{flavor}-{buildType}.{aab|apk}
```

Example:
```
builds/sp-android/prodAndroid/release/aab/20260226_143022/app-prodAndroid-release.aab
```

## Project Configuration

### Technical Details
- **Target SDK**: 36
- **Min SDK**: 26
- **Gradle Plugin**: 8.9.1
- **Kotlin**: 2.1.0
- **NDK**: 25.1.8937393

### Key Features
- Multi-store distribution (Google Play + Amazon Appstore)
- Dynamic asset packs (9 packs with install-time delivery)
- Firebase integration (Crashlytics, Performance, Distribution)
- Realm database with encryption
- Apollo GraphQL integration
- Custom build tasks for asset preparation

## Script Enhancements

### Validation Functions
- `validate_project_structure()` - Verifies all 13 modules present
- `validate_signing_config()` - Checks keystore availability

### Key Improvements
1. **Store dimension support** - Handles android/amazon variants
2. **2D flavor matrix** - Combines environment + store dimensions
3. **Project validation** - Pre-build structure checks
4. **Better error handling** - Clear error messages with exit codes
5. **Organized outputs** - Timestamped folders in script directory

## Common Tasks

### Release Build for Production
```bash
# Google Play Store
./build_android_app.sh prodandroid release aab sp-android

# Amazon Appstore
./build_android_app.sh prodamazon release aab sp-android
```

### Testing Build
```bash
# Quick debug APK
./build_android_app.sh devandroid debug apk sp-android
```

### Profile Build (Performance Testing)
```bash
./build_android_app.sh prodandroid profile apk sp-android
```

## Troubleshooting

### Module Not Found
- Ensure all 13 modules exist in sp-android project
- Check asset pack modules (asset_pack_01 through asset_pack_09)

### Signing Issues
- Verify keystore file exists
- Check signing config in build.gradle
- Ensure key passwords are correct

### Build Failure
- Run `./gradlew clean` in sp-android directory
- Check Gradle daemon: `./gradlew --stop`
- Verify dependencies are downloaded

## Notes

- **Custom tasks**: `devApkRequiredAssets`, `prodAabRequiredAssets` run automatically
- **Flavors**: Use lowercase (prodandroid, not prodAndroid) in commands
- **Asset packs**: Install-time delivery configured for all 9 packs
- **Signing**: Required for release builds, optional for debug
