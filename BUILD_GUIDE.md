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

## Non-Interactive Mode (automation)

Running the script with **no options** is unchanged - you get the usual
interactive prompts. Passing any option below switches it to non-interactive
mode, where every prompt is answered from the command line instead of stdin.
This is what the Slack remote-terminal-manager uses to trigger Android builds.

```bash
# staging: dev flavor, Play Store, profile build, APK
sh build_android_app.sh \
  --sp-android staging-1 --flutter-app staging-1 \
  --flavor dev --type profile --export apk

# production
sh build_android_app.sh \
  --sp-android nov25-release-1 --flutter-app android_nov_25_1 \
  --flavor prod --type profile --export apk
```

Run `sh build_android_app.sh --help` for the full option list.

Values accept either the menu number or the readable name - `--type 2` and
`--type profile` are equivalent.

### Why flags, not piped input

Answers are matched to prompts **by name**, not by position. Piping a fixed
sequence (`printf '1\n2\n...' | sh build_android_app.sh`) breaks silently
whenever a prompt is added, removed, or skipped - and several prompts here are
conditional (the asset block only appears for android + aab + prod). A
misaligned pipe doesn't fail; it answers the wrong question and builds the wrong
variant. Flags cannot drift that way.

### Validation

Non-interactive runs are validated **before** any checkout or Gradle work:

- an invalid value (`--flavor staging`) fails immediately, listing valid choices
- a missing required option (`--flavor`, `--type`, `--export`, `--sp-android`,
  `--flutter-app`) fails immediately
- `--speech-to-text` is genuinely optional; omitting it skips that repo

Defaults applied only in non-interactive mode: `--target android`,
`--source branch`, `--store android`, `--playable-downloader master`,
`--generate-assets no`, `--recreate-flutter no`, and auto-confirm of the final
"Proceed with build?" prompt.

## Firebase App Distribution

After a successful build the artifact is uploaded to Firebase App Distribution,
the same destination iOS builds use (`CrossPlatformGames2/iOS/fastlane/Fastfile`,
`distribute` lane). Interactive runs are asked; non-interactive runs default to
yes and can opt out with `--distribute no`.

It reuses the machine-level assets already set up for iOS:

| Asset | Default path | Override |
|---|---|---|
| Service-account creds | `~/Desktop/.DoNotDelete/firebase_creds.json` | `FIREBASE_CREDENTIALS` |
| Firebase CLI | `/usr/local/bin/firebase` | `FIREBASE_CLI` |
| Android app id | `~/Desktop/.DoNotDelete/firebaseAppIds/android.txt` | `FIREBASE_APP_ID_FILE`, or `FIREBASE_APP_ID` to skip the file |
| Tester groups | `app-testing-team,content-testing-team` | `FIREBASE_GROUPS` |

The app id file holds the Android **App ID** from Firebase Console → Project
Settings → Your apps, one line, e.g. `1:123456789012:android:abc123def456`.
It is a different app id from iOS - same Firebase project, different app.

### Release notes

Written for the tester reading them in Firebase, phrased like the iOS lane
("Development Build" / "Production Build") rather than as raw gradle values -
`BUILD_FLAVOR` is environment+store concatenated, so `devandroid profile apk`
means nothing to a reader. The store is named only when it isn't the default,
and tag builds say so because it matters whether a tester is on a moving branch
or a fixed release point:

```
Development Build (profile, apk)
sp-android: staging-1
flutter_app: staging-1
```
```
Production Build (profile, apk) - amazon store
sp-android: v7.3.4
flutter_app: v7.3.4
built from tags
```

**Distribution never fails the build.** The artifact is already on disk and
reported regardless, so every problem is a warning plus a machine-readable
`FIREBASE_STATUS=` line rather than a non-zero exit:

- `uploaded` - success, also prints `FIREBASE_APP=<id>`
- `skipped:no-app-id` / `skipped:empty-app-id` - app id file missing or blank
- `skipped:no-credentials` / `skipped:no-cli` - machine isn't set up
- `skipped:too-large:<n>MB` - over Firebase's 500MB limit (`FIREBASE_MAX_UPLOAD_MB`)
- `failed` - upload failed after `FIREBASE_UPLOAD_ATTEMPTS` (default 3) tries

The retry loop wraps the whole CLI call, mirroring the iOS lane: a send timeout
escapes the underlying tool's own retry handling, so retrying has to happen one
level up.
