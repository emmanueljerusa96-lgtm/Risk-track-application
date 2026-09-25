# Risk Track

**Track. Report. Stay Aware.** Risk Track is an Android-first Flutter app for community-submitted reports about places that may need attention. People can explore reports on an interactive map, submit a report with an optional photo, follow its review status, and flag inaccuracies. An administrator can review reports and manage roles.

> **Responsible reporting:** A submitted report is a *community report*, not a verified statement that a place is dangerous. New reports are **Pending Verification** until reviewed. Even a **Verified Report** is not an official emergency alert. Exercise judgment, consult official sources for important decisions, and contact local emergency services when appropriate.

## What is included

- Material 3 branding, splash, three-page onboarding, login, registration, reset password and logout.
- Firebase Authentication (email/password) and private `users/{uid}` profiles; a new account always has `role: user`.
- Dashboard, consent-driven GPS, optional reverse geocoding and a map pin picker without GPS permission.
- OpenStreetMap map, report markers, marker details, zoom/pan/center controls and attribution. No Google Maps key is needed.
- Validated reports with eight categories, optional JPG/PNG camera/gallery photo, Firebase Storage upload, Firestore persistence and error cleanup.
- Report details, *My reports*, incorrect-information flags and explicit active/resolved versus pending/verified/rejected labels.
- Recent-report search, category/status/review/date filters and an optional GPS distance filter.
- Admin counts, report verification/rejection/resolution, review of flags and role management. **Firestore and Storage rules enforce access**, not just hidden buttons.
- In-app Firestore notifications and optional opt-in FCM pushes sent by trusted Cloud Functions when admins review reports. Clients cannot send their own notifications.
- Google Analytics for Firebase. Automatic sessions, plus sign-in, sign-up, screen, and report-submitted events. Email, location, report text, and the advertising ID are not sent. Usage analytics can be turned off in Settings.
- Flutter tests, notification-function tests, Firestore emulator security tests and deployable rules/indexes.

## Requirements

- Windows 10 64-bit (or a supported development OS), VS Code with Flutter/Dart extensions.
- A recent stable **Flutter with Dart 3.9+** (the project targets the current Flutter Android template); `flutter doctor -v` must pass the Android checks.
- Android SDK/Android SDK Platform-Tools, Android SDK API 36 if your Flutter version asks for it, and JDK 17+ (Android Studio's bundled JDK works). Android phone with **Android 7.0 / API 24+** for device testing. No emulator required.
- A Firebase project that **you own**, network access for Firebase/map tiles, and optionally Node.js 22 + Firebase CLI for Functions and emulator tests.
- Cloud Storage and deployed Functions may require a Firebase billing plan. Verify the current Firebase plan requirements in your own project.

This repository contains **no Firebase project ID, credentials, service account or map key**. `android/app/google-services.json`, `android/key.properties`, keystores and `.firebaserc` are gitignored. Do not commit private keys or service-account JSON.

## 1. Flutter and Android setup (Windows / VS Code)

1. Install the Flutter SDK from [flutter.dev](https://docs.flutter.dev/get-started/install/windows/mobile), add its `bin` directory to PATH and install the VS Code Flutter and Dart extensions.
2. Install Android SDK Platform-Tools, the requested SDK Platform/Build-Tools and a JDK (Android Studio *SDK Manager* is one way; no emulator is needed). Accept Android licences.
3. From the repository root in a **new** PowerShell/VS Code terminal:

   ```powershell
   flutter --version
   flutter doctor -v
   flutter doctor --android-licenses
   flutter pub get
   flutter analyze
   flutter test
   ```

4. For a physical Android phone: tap *Build number* seven times to unlock Developer options, enable **USB debugging**, use a USB data cable, select File Transfer if prompted and approve the phone's debugging authorization. Install its OEM Windows USB driver if necessary. Confirm with `adb devices -l` and `flutter devices`; the device should be shown as **authorized**.

Flutter normally writes `android/local.properties` automatically when it builds; that file is local-only. If you invoke Gradle manually instead, set `flutter.sdk` and `sdk.dir` in your own `android/local.properties`.

## 2. Connect Firebase before using the app

Without Firebase configuration, the APK can open but shows a **Connect Firebase** setup screen rather than pretending authentication/reports work.

1. Create a project in the [Firebase Console](https://console.firebase.google.com/). Add an **Android** app with application ID **`com.risktrack.app`**. That ID is the Android package name in `android/app/build.gradle.kts`, `MainActivity.kt`, and the map User-Agent. It is **not** a Firebase project ID.
2. Download the real `google-services.json` for that app and copy it to **`android/app/google-services.json`**. Never replace it with invented values. The Android Google Services plugin (`com.google.gms.google-services` **4.5.0**) is applied in the app module. If that file is missing, the build warns and continues so the Connect Firebase screen can still open. Rebuild after adding the file. Android uses this file for `Firebase.initializeApp()`; there is no generated `firebase_options.dart` to edit. Firebase Analytics is already declared with BoM **34.19.0** (`firebase-analytics`, no separate version). Enable Google Analytics on the Firebase project if the console asks. Collection starts only after this file is present and the app is rebuilt.
3. Enable **Authentication → Sign-in method → Email/Password** and configure the email action template/sender for reset emails.
4. Create **Cloud Firestore** and **Cloud Storage** in your project (choose the appropriate region and plan). Deploy the restrictive rules/indexes below **before** inviting users. Do **not** leave production data in Firebase test mode.
5. Install the Firebase CLI, sign in on **your machine**, choose **your own** project and deploy:

   ```powershell
   npm install -g firebase-tools
   firebase login
   firebase use --add
   firebase deploy --only "firestore:rules,firestore:indexes,storage"
   ```

   `firebase.json`, `firestore.rules`, `storage.rules` and `firestore.indexes.json` are included. Wait for indexes to become enabled. Some combinations of filters require composite indexes; these are included. The Storage rule uses `firestore.exists()` to permit cleanup of an orphaned upload while preventing authors from deleting photos after a report is saved; Firebase may prompt the project owner to enable cross-service rule access.
6. For persistent in-app admin/review notifications and optional FCM push, deploy the trusted Functions (Node.js 22):

   ```powershell
   cd functions
   npm ci
   npm test
   cd ..
   firebase deploy --only functions
   ```

   FCM is **optional and opt-in** on the phone. In-app notifications are only created after these Functions are deployed; the submit-form success confirmation works without them. The app never puts FCM server keys in client code. On Android 13+, notification permission is requested **only** after the user taps Enable alerts. The Functions send generic status text (no private location, email or report body on the lock screen).

### Initial administrator (trusted bootstrap)

1. Register an ordinary account in the app. It will be created with `users/{uid}.role = "user"`; no registration field can set a different role.
2. As the **Firebase project owner**, use the trusted Firebase Console/Firestore administration (or Admin SDK in your private environment) to set **that existing user's** `role` to `"admin"`. Do not provide client-side admin creation or a public service-account key. Sign out/in if the profile UI has not refreshed yet.
3. Only admins can read the user list, change another user's role, view flags and update a report's review/status. Admins cannot revoke their **own** admin role in the app. Deleting/disabling Firebase Authentication accounts requires a separate trusted Admin SDK workflow; this app does not claim to disable Auth accounts.

## 3. Maps and location

- Map tiles use HTTPS `tile.openstreetmap.org` and a named User-Agent with visible **© OpenStreetMap contributors** attribution linking to the copyright page. **No API key** is embedded. The starting viewport is Lagos only as a neutral placeholder: **GPS is never requested at startup**. Tap *Use GPS*, *Center on my location* or *Use current GPS* to prompt for device location. The report form also supports choosing a map pin without permission.
- The public OSM tile server is appropriate for limited development, **not an unlimited production tile plan**. Before a public rollout, read [OSM's tile usage policy](https://operations.osmfoundation.org/policies/tiles/) and migrate to a permitted provider or self-hosted tiles if traffic warrants it. Preserve attribution and identify the client correctly. Offline tiles are not bundled.
- Device reverse geocoding is best-effort; coordinates appear if no address can be obtained. GPS-off, denied, permanently denied and unavailable cases produce guidance and a settings shortcut when appropriate.
- Nearby distance and text searches operate **within up to 100 most recent server-filtered reports**, not a geospatial index of the entire database. The UI labels this scope. Add pagination and a geohash/geospatial query for a city-scale production rollout.

## 4. Run and test on your Android phone

```powershell
flutter pub get
flutter analyze
flutter test
flutter devices
flutter run -d <device-id>
```

Test on your own Firebase project and an authorized device: registration (including duplicate email), login/logout, password reset email, lost/offline connection, permission allow/deny/deny-forever/GPS-off, map panning/markers/center/attribution, pin picker, report validation, camera/gallery, photo upload, Firestore creation, report detail/flag, My reports, category/date/status/review/distance filters, admin-only screens and rules, in-app notifications, and push after opting in and deploying Functions. To test admin, bootstrap a separate admin account as above. Photos must not include faces, number plates or private details; a Storage download URL is a **bearer link** and may be accessible to anyone holding it even when SDK reads are protected by Storage rules.

For additional security tests with Java and the Firebase CLI installed:

```powershell
cd functions
npm ci
npm test
cd ..
firebase emulators:exec --project demo-risk-track-rules --only firestore "cd functions && npm run test:rules"
```

This security test verifies owner-only profile access, no self-promotion, owner/admin report transitions, admin promotion, self-demotion protection and rejection of spoofed notifications. It uses a **demo** emulator project, not production data.

## 5. Release APK

Once Firebase is configured and `flutter analyze`, `flutter test` and on-phone checks succeed:

```powershell
flutter build apk --release
```

The result, **only if the command succeeds**, is `build/app/outputs/flutter-apk/app-release.apk`. The current Gradle configuration uses a **debug key for local release-mode testing** if `android/key.properties` is absent: do **not** distribute that APK. To publish, make your own upload keystore, copy `android/key.properties.example` to the ignored `android/key.properties`, set its real values and rebuild. Keep your keystore and passwords secure and outside Git. Update `applicationId`, app name/icon/version and Play Console configuration as needed before publishing.

For a 4 GB computer, keep the Android emulator closed, use the physical phone, avoid parallel Gradle builds and let the first dependency/Gradle download finish. `android/gradle.properties` caps the Gradle heap/workers.

### GitHub Actions

`.github/workflows/android-release.yml` builds a release APK and AAB on pushes to `main`, on version tags, and when the workflow is run manually. It does not store Firebase or signing files in Git. Add these Actions secrets on the repository (Settings → Secrets and variables → Actions), or run `scripts/set-github-secrets.ps1` from a machine that already has `gh` logged in with permission to manage secrets:

| Secret | Value |
| --- | --- |
| `GOOGLE_SERVICES_JSON` | Full contents of `android/app/google-services.json`. Required. Package name must be `com.risktrack.app`. |
| `ANDROID_KEYSTORE_BASE64` | Base64 of `android/upload-keystore.jks`. Omit all four signing secrets for a debug-signed test build. |
| `ANDROID_KEYSTORE_PASSWORD` | `storePassword` from `android/key.properties`. |
| `ANDROID_KEY_PASSWORD` | `keyPassword` from `android/key.properties`. |
| `ANDROID_KEY_ALIAS` | `keyAlias` from `android/key.properties` (the example uses `upload`). |

Create the upload key once, then keep the `.jks` and passwords outside Git:

```powershell
keytool -genkeypair -v -keystore android/upload-keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
copy android/key.properties.example android/key.properties
```

Set the real passwords in the ignored `android/key.properties`. `storeFile` must stay `../upload-keystore.jks`. Then:

```powershell
.\scripts\set-github-secrets.ps1
```

A build without the four signing secrets is debug-signed and must not be published. Artifacts are kept for 14 days.

## Troubleshooting

| Problem | Check |
| --- | --- |
| `flutter` not found | Install Flutter and add its `bin` directory to Windows PATH; open a new terminal. |
| No Android device | USB debugging, device authorization prompt, data cable, Windows OEM USB driver, `adb devices -l` and `flutter devices`. |
| Setup screen after adding JSON | Ensure `android/app/google-services.json` matches the **application ID**; rebuild and check `flutter doctor -v`. |
| Gradle warns that `google-services.json` is missing | Expected until the file is added. The app still builds and shows Connect Firebase. |
| `permission-denied` | Deploy the included rules/indexes, confirm sign-in/profile creation and check the admin role if reviewing. New accounts cannot self-promote. |
| Firestore index error | Deploy `firestore.indexes.json`, then wait for Firebase to build the indexes. |
| Map blank | Internet access, OSM tile policy/rate limit and the correct User-Agent; the app does not bundle map tiles. |
| GPS unavailable | Enable Android Location; grant location permission only when prompted; try an outdoor fix or choose a map pin. |
| Camera/gallery upload fails | Use a JPG or PNG smaller than 5 MB, check Storage setup/rules/plan and network. |
| In-app review notification absent | Deploy Functions; reports still submit without Functions. For push, tap **Enable alerts** and grant Android notification permission. |
| Build out of memory | Close other apps, use the phone (not emulator), keep Gradle at 2 workers and ensure Java/Android SDK agree with `flutter doctor -v`. |
| Actions build fails before Gradle | Add `GOOGLE_SERVICES_JSON`. For a Play upload, also add the four `ANDROID_KEYSTORE_*` / `ANDROID_KEY_*` secrets. |

### Current workspace verification

This repository was initially only a README. It has been scaffolded here into a Flutter/Android project. The remote Linux coding sandbox **does not contain Flutter, Dart, Java, Android SDK or a connected USB phone** and cannot reach the official Flutter/pub artifact hosts. Consequently `flutter pub get`, `flutter analyze`, `flutter test`, `flutter run` and `flutter build apk --release` **have not succeeded here**. Do not treat the project as device-verified or claim an APK exists until those commands are run successfully in an equipped environment. The included Node notification tests and static JSON/JS checks can run independently and are reported separately.
