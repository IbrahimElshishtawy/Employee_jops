# Enterprise Flutter Update & Deployment Architecture

This document describes the update and release management system for the Employee/HR Flutter application, integrating **GitHub Releases**, **Shorebird Code Push (Over-The-Air Patches)**, and **Firebase Cloud Messaging (FCM)**.

---

## 1. System Overview

The update system provides two distinct update strategies tailored to the nature of changes:

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        Update Decision Matrix                          │
└────────────────────────────────────────────────────────────────────────┘
                               │
               Requires Native Code / Plugins / Config?
                               │
                 ┌─────────────┴─────────────┐
                YES                          NO
                 │                           │
                 ▼                           ▼
      ┌─────────────────────┐     ┌─────────────────────┐
      │  TYPE 1: Release    │     │  TYPE 2: Patch      │
      │  (Store / GitHub)   │     │  (Shorebird OTA)    │
      ├─────────────────────┤     ├─────────────────────┤
      │ • AndroidManifest   │     │ • Bug fixes         │
      │ • iOS Info.plist    │     │ • UI logic tweaks   │
      │ • Native Kotlin/ObjC│     │ • Dart state fixes  │
      │ • Major dependencies│     │ • Business rules    │
      │ • App version bump  │     │ • Fast rollouts     │
      └─────────────────────┘     └─────────────────────┘
                 │                           │
                 ▼                           ▼
         Full Store Download          Silent OTA Update
        (APK / AAB / App Store)       (No Store Download)
```

---

## 2. Update Types & When to Use

### TYPE 1 — Normal Store Release (Native / Platform Changes)
Use a **Normal Store Release** when changes touch:
- Android configuration (`AndroidManifest.xml`, `build.gradle`, `MainActivity.kt`, permissions)
- iOS configuration (`Info.plist`, `Podfile`, `AppDelegate.swift`, capabilities)
- Native plugins (new plugins or major native SDK upgrades)
- Application major/minor version increments (e.g., `1.0.0` -> `1.1.0`)

**User Experience:**
- User receives an in-app dialog / push notification: *"تحديث جديد متاح"* (New Update Available).
- Tapping "تحديث الآن" (Update Now) redirects to Google Play, Apple App Store, or GitHub Releases.
- If `installedVersion < minimumSupportedVersion`, a **Force Update** is enforced (dialog is non-dismissible).

---

### TYPE 2 — Shorebird OTA Patch (Dart & Flutter Only)
Use a **Shorebird Patch** when changes are strictly Dart/Flutter code:
- Critical bug fixes and regression patches
- Attendance verification UI logic tweaks
- Chat and communication formatting fixes
- Localization string updates
- Performance and rendering optimizations

**User Experience:**
- The Shorebird updater automatically checks and stages the patch in the background.
- Next time the user launches or restarts the app, the latest patch is active.
- **Zero app store downloads or reinstalls required.**

> [!WARNING]
> **Shorebird Native Limitation:** Shorebird cannot patch native Android/iOS changes, native Gradle/Podfile modifications, or new native permissions. Attempting to patch native changes will result in crashes or patch rejection.

---

## 3. GitHub Actions Workflows

The repository contains 3 automated production workflows in `.github/workflows/`:

| Workflow File | Trigger | Purpose |
| :--- | :--- | :--- |
| [`release.yml`](file:///.github/workflows/release.yml) | Git tag `v*.*.*` or `workflow_dispatch` | Formats, analyzes, tests, builds release APK & AAB, creates GitHub Release, and notifies FCM |
| [`shorebird_release.yml`](file:///.github/workflows/shorebird_release.yml) | Manual `workflow_dispatch` | Creates the base Shorebird binary release corresponding to the store build |
| [`shorebird_patch.yml`](file:///.github/workflows/shorebird_patch.yml) | Manual `workflow_dispatch` | Validates tests, builds, and publishes an instant Over-The-Air code patch |

---

## 4. Required GitHub Secrets

Configure the following secrets in GitHub Repository Settings (`Settings -> Secrets and variables -> Actions`):

| Secret Name | Required By | Description |
| :--- | :--- | :--- |
| `SHOREBIRD_TOKEN` | `shorebird_release.yml`, `shorebird_patch.yml` | Shorebird CI/CD authentication token (obtained via `shorebird login:ci`) |
| `FIREBASE_SERVICE_ACCOUNT` | `release.yml` *(optional)* | Google Cloud Service Account JSON for triggering FCM push notifications |
| `FIREBASE_PROJECT_ID` | `release.yml` *(optional)* | Firebase Project ID for FCM notification routing |
| `GITHUB_TOKEN` | `release.yml` | Default GitHub token (automatically provided by GitHub Actions) |

> [!IMPORTANT]
> Never commit secrets or API tokens into source files or `.env` files.

---

## 5. Step-by-Step Developer Workflows

### How to Create a New Version (Type 1 Release)

1. **Update `pubspec.yaml` version:**
   ```yaml
   # Format: <major>.<minor>.<patch>+<buildNumber>
   version: 1.1.0+13
   ```

2. **Commit and create a Git Tag:**
   ```bash
   git add pubspec.yaml
   git commit -m "chore(release): bump version to 1.1.0+13"
   git tag v1.1.0
   git push origin main --tags
   ```

3. **CI/CD Execution:**
   - GitHub Actions automatically runs `release.yml`.
   - Validates formatting, analyzer, unit and widget tests.
   - Builds `app-release.apk` and `app-release.aab`.
   - Creates GitHub Release `v1.1.0` with release notes and binary assets.

4. **Create Corresponding Shorebird Baseline:**
   - Go to GitHub -> **Actions** -> **Shorebird Base Release** -> **Run workflow** (Target: `1.1.0+13`).

---

### How to Publish an Instant Patch (Type 2 Patch)

1. **Make Dart/Flutter code changes and test locally:**
   ```bash
   flutter test
   ```

2. **Commit changes to `main` branch:**
   ```bash
   git commit -m "fix(attendance): resolve biometric retry timing"
   git push origin main
   ```

3. **Trigger Shorebird Patch Workflow:**
   - Go to GitHub -> **Actions** -> **Shorebird Code Push Patch**.
   - Click **Run workflow**.
   - Input target release version: `1.1.0+13`.
   - Click **Run workflow**.
   - Shorebird compiles and distributes the patch Over-The-Air to all users on `1.1.0+13`.

---

## 6. Firebase Cloud Messaging (FCM) Payload Specification

To broadcast an update notification to users via FCM, send a data payload conforming to:

```json
{
  "type": "APP_UPDATE",
  "version": "1.2.0",
  "title": "تحديث جديد متاح",
  "body": "يتوفر إصدار جديد من تطبيق الموظفين",
  "releaseNotes": "تحسين سرعة تسجيل الحضور وإضافة ميزات جديدة",
  "androidUrl": "https://github.com/IbrahimElshishtawy/Employee_jops/releases/latest",
  "iosUrl": "https://github.com/IbrahimElshishtawy/Employee_jops/releases/latest",
  "forceUpdate": false
}
```

---

## 7. Force Update vs Optional Update Mechanics

The `AppUpdateServiceImpl` evaluates update constraints on every app launch and foreground resume:

```dart
// 1. Force Update Condition
if (currentInstalledVersion < remoteConfig.minimumSupportedVersion) {
  // Enforces non-dismissible UpdateDialog
  // User cannot dismiss dialog or access application without updating
}

// 2. Optional Store Update Condition
else if (remoteConfig.latestVersion > currentInstalledVersion) {
  // Shows dismissible UpdateDialog with "تحديث الآن" and "لاحقًا"
  // Displays UpdateBanner in Settings & About screens
}

// 3. Shorebird OTA Patch Condition
else if (hasShorebirdPatch) {
  // Automatically downloads and stages patch in background
  // User sees silent update notice on next launch
}
```

---

## 8. Rollback and Disaster Recovery

### Rollback for Shorebird Patches
If a bad patch was deployed:
1. Go to your Shorebird console or use CLI:
   ```bash
   shorebird patch android --release-version=1.1.0+13 --rollback
   ```
2. Or deploy a new fix patch following standard workflow.

### Rollback for Store Releases
If a major store binary release fails:
1. Increase `minimumSupportedVersion` in remote configuration to prevent affected versions from running.
2. Publish a hotfix binary release (e.g. `v1.1.1`).

---

## 9. Local Verification Commands

To verify the entire update and build pipeline locally:

```bash
# 1. Check dependencies
flutter pub get

# 2. Check code formatting
dart format --output=none --set-exit-if-changed .

# 3. Static analyzer
flutter analyze

# 4. Run test suite
flutter test

# 5. Build release APK
flutter build apk --release
```
