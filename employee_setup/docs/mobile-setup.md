   # CyberWise IE — Mobile & Device Security Setup Guide

This document details the complete native configuration, platform permissions, security architecture, and testing procedures for running **CyberWise IE** on real physical devices (Android & iOS) and web environments.

---

## 1. System Requirements & Versions

| Component | Target Version |
|---|---|
| **Flutter SDK** | `^3.29.x` / `^3.38.x` |
| **Dart SDK** | `^3.7.x` / `^3.12.x` |
| **Android Gradle Plugin (AGP)** | `9.0.x` / `8.x` |
| **Kotlin** | `2.3.x` / `2.0.x` |
| **Android minSdk** | `23` (Android 6.0+) |
| **Android targetSdk** | `34` / `35` (Android 14 / 15) |
| **iOS Deployment Target** | `iOS 14.0+` |

---

## 2. Package Dependency Matrix

| Package | Version | Purpose | Android | iOS | Web |
|---|---|---|---|---|---|
| `local_auth` | `^2.3.0` | Hardware Biometrics (Fingerprint, Face ID, Touch ID) | BiometricPrompt | LocalAuthentication | Unsupported (Graceful fallback) |
| `geolocator` | `^13.0.2` | GPS coordinates, accuracy, permission checks, mock detection | LocationManager / FusedLocation | CLLocationManager | Geolocation API |
| `connectivity_plus` | `^6.1.3` | Network status & VPN telemetry | ConnectivityManager | NetworkReachability | Navigator Online |
| `flutter_secure_storage` | `^9.2.4` | Encrypted session & credential storage | Android Keystore + EncryptedSharedPreferences | iOS Keychain | Web LocalStorage / WebCrypto fallback |
| `google_sign_in` | `^6.2.2` | Google OAuth identity authentication | Google Sign-In SDK | GoogleSignIn iOS SDK | Google Identity Services |
| `flutter_local_notifications` | `^18.0.1` | Local notifications & notification channels | NotificationManager (Channels) | UNUserNotificationCenter | Unsupported (Graceful fallback) |
| `flutter_riverpod` | `^2.6.1` | Reactive state management & DI | All | All | All |
| `go_router` | `^14.8.1` | Declarative routing & auth redirect guards | All | All | All |

---

## 3. Android Native Configuration

### 3.1 `MainActivity.kt` (Fragment Activity)
For Android's `BiometricPrompt` dialogs to render properly, the main activity extends `FlutterFragmentActivity`:

```kotlin
package com.example.employee_setup

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
```

### 3.2 `AndroidManifest.xml` Permissions
Located at `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Network & Internet capabilities -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <!-- Location verification permissions for Attendance -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    
    <!-- Biometric identity verification -->
    <uses-permission android:name="android.permission.USE_BIOMETRIC" />
    <uses-permission android:name="android.permission.USE_FINGERPRINT" />
    
    <!-- Local Notifications (Android 13+) -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <application
        android:label="CyberWise IE"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        ...
    </application>
</manifest>
```

---

## 4. iOS Native Configuration

### 4.1 `Info.plist` Usage Descriptions
Located at `ios/Runner/Info.plist`:

```xml
<!-- Location Access Description -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app requires location access to verify physical presence within the company workplace for attendance check-in and check-out.</string>

<!-- Face ID / Biometrics Description -->
<key>NSFaceIDUsageDescription</key>
<string>This app requires Face ID / Biometrics to authenticate employee identity when registering attendance.</string>
```

---

## 5. Google Sign-In Setup for Real Devices

To execute real OAuth authentication on physical mobile devices:

### Android Setup:
1. Generate the debug SHA-1 signing key fingerprint:
   ```bash
   cd android
   ./gradlew signingReport
   ```
2. In the Google Cloud Console / Firebase Console:
   - Create a project and add an Android App with package name `com.example.employee_setup`.
   - Register the SHA-1 and SHA-256 fingerprints.
   - Download `google-services.json` and place it in `android/app/`.

### iOS Setup:
1. In the Google Cloud Console / Firebase Console:
   - Add an iOS app with bundle identifier `com.example.employeeSetup`.
   - Download `GoogleService-Info.plist` and place it in `ios/Runner/`.
2. Add the reversed client ID as a URL scheme in `ios/Runner/Info.plist`:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleTypeRole</key>
           <string>Editor</string>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
           </array>
       </dict>
   </array>
   ```

*Note: In local test and demo environments without a registered Google Cloud project, CyberWise IE automatically provides a safe fallback to authenticated test sessions.*

---

## 6. Biometric Authentication Architecture

### Privacy & Compliance Principles:
- **Zero Raw Biometric Storage**: The application NEVER receives, accesses, or persists fingerprint imagery, Face ID biometric vectors, or face templates.
- **Hardware-Enclave Authentication**: All biometric verification occurs inside the secure hardware enclave (TEE / Secure Enclave).
- **Boolean Verdict Only**: The application receives only a signed cryptographic verdict (`BiometricAuthResult.success`, `failed`, `cancelled`, or `notAvailable`).

---

## 7. GPS Location & Geofencing Pipeline

### Verification Flow:
```
User Taps "Check In"
       ↓
Check Location Service Enabled (GPS On)
       ↓
Check Foreground Location Permission (Fine / Coarse)
       ↓
Acquire GPS Position (High Accuracy, 12s timeout)
       ↓
Inspect Android Mock Location Flag (position.isMocked)
       ↓
Calculate Geodesic Distance via Haversine Formula
       ↓
Compare Distance with Workplace Radius (4.0m)
       ↓
Evaluate GPS Accuracy Threshold (<= 20.0m)
       ↓
Proceed to Biometric Challenge
```

---

## 8. Network & Device Integrity Security

### 8.1 Network & VPN Risk:
- `RealNetworkRiskService` monitors active network interfaces (`ConnectivityResult.vpn`, `wifi`, `cellular`, `none`).
- VPN activity is recorded as a security telemetry signal sent to the backend decision engine.
- *VPN detection is not treated as proof of fake GPS; physical location is verified by GPS hardware.*

### 8.2 Device Integrity (Play Integrity / App Attest):
- `DeviceIntegrityService` requests platform attestation tokens using a server-provided cryptographic nonce.
- The mobile client **never** self-certifies device integrity; the backend server performs the cryptographic validation against Google Play Integrity or Apple App Attest verification APIs.

---

## 9. Secure Session Storage

Sensitive session metadata is persisted using `SecureSessionStorage` backed by:
- **Android**: Android Keystore + `EncryptedSharedPreferences` (AES-256-GCM / RSA).
- **iOS**: iOS Keychain (`kSecAttrAccessibleAfterFirstUnlock`).
- **Web**: LocalStorage fallback.

### What is stored:
- Session Token (`cyberwise_jwt_...`)
- Authenticated Employee Profile JSON
- Onboarding Completion Flag (`true` / `false`)

### What is NEVER stored:
- User Passwords
- Biometric Data
- Private API Keys

---

## 10. Local Notifications Setup

`NotificationService` initializes standard notification channels on Android and handles iOS authorization:
- **Channel 1 (`cyberwise_attendance_channel`)**: Check-in and check-out confirmations (High Importance / Sound / Heads-up).
- **Channel 2 (`cyberwise_requests_channel`)**: Advances, permissions, and vacation request status updates (Default Importance).

---

## 11. Real Device Testing Checklist

When running on an Android or iOS device (`flutter run`):

1. **Google Sign-In**:
   - Tap "تسجيل الدخول باستخدام Google".
   - Confirm Google account picker opens or test session creates securely.
2. **Onboarding Flow**:
   - Complete Step 1 (Personal Info), Step 2 (Work Info), Step 3 (Workplace Location).
   - Test Biometric Enrollment with device Face ID / Fingerprint.
3. **Location & Geofencing**:
   - Test inside workplace zone (< 4m).
   - Test outside workplace zone (> 4m).
   - Verify permission prompts request "While Using the App".
4. **Biometrics on Attendance**:
   - Tap "تسجيل الحضور" on Attendance screen.
   - Confirm OS biometric dialog appears and verifies identity.
5. **Notifications**:
   - Confirm system notification banner pops up after successful check-in.
6. **App Lifecycle**:
   - Put app in background during check-in, resume, confirm clean state recovery.
7. **Developer Demo Controls**:
   - In Settings -> Developer Controls, toggle "حساسات الجهاز الحقيقية" vs "وضع المحاكاة".
