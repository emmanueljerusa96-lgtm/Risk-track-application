# Risk Track

**Track. Report. Stay Aware.** Risk Track is a Flutter app for community-submitted reports about places that may need attention. People can explore reports on an interactive map, submit a report with an optional photo, follow its review status, and flag inaccuracies. An administrator can review reports and manage roles.

It runs in two shapes from one codebase:

- **In a browser** (Chrome, Edge, Firefox, a phone browser) - `web/` is part of the project, and `.github/workflows/web-pages.yml` publishes the web build to a public GitHub Pages link. This is the quickest way to see the app.
- **On an Android phone** as an APK (`flutter run`, `flutter build apk`).

Both use the same Firebase project, the same OpenStreetMap tiles and the same screens.

> **Responsible reporting:** A submitted report is a *community report*, not a verified statement that a place is dangerous. New reports are **Pending Verification** until reviewed. Even a **Verified Report** is not an official emergency alert. Exercise judgment, consult official sources for important decisions, and contact local emergency services when appropriate.

## What is included

- Material 3 branding, splash, three-page onboarding, login, registration, reset password and logout.
- Firebase Authentication (email/password) and private `users/{uid}` profiles; a new account always has `role: user`.
- Dashboard, consent-driven GPS (device location on Android, the browser Geolocation API on the web), reverse geocoding through the phone's geocoder or OpenStreetMap Nominatim, and a map pin picker that needs no permission at all.
- OpenStreetMap map, report markers, marker details, zoom/pan/center controls and attribution. No Google Maps key is needed.
- Validated reports with eight categories, optional JPG/PNG camera/gallery photo, Firebase Storage upload, Firestore persistence and error cleanup.
- Report details, *My reports*, incorrect-information flags and explicit active/resolved versus pending/verified/rejected labels.
- Recent-report search, category/status/review/date filters and an optional GPS distance filter.
- Admin counts, report verification/rejection/resolution, review of flags and role management. **Firestore and Storage rules enforce access**, not just hidden buttons.
- In-app Firestore notifications everywhere, plus optional opt-in FCM pushes (Android builds) sent by trusted Cloud Functions when admins review reports. Clients cannot send their own notifications; browser push is intentionally out of scope, so the web build relies on the in-app list.
- Google Analytics for Firebase. Automatic sessions, plus sign-in, sign-up, screen, and report-submitted events. Email, location, report text, and the advertising ID are not sent. Usage analytics can be turned off in Settings.
- Browser support: `web/` with a branded loading screen, PWA manifest and generated icons, plus `--dart-define` based Firebase configuration so no credentials live in Git. Wide desktop windows render the mobile layout centred instead of stretched.
- One GitHub Actions workflow that runs `flutter analyze`, `flutter test` and `flutter build web`, then publishes the result to GitHub Pages on `main`.
- Sample data fallback so the interface always opens. The app prefers the live Firebase project; if this build has no Firebase credentials, or Firebase cannot be reached at startup, it serves built-in sample reports instead and shows a banner. Force it any time with `--dart-define=USE_SAMPLE_DATA=true` (or `DemoMode.preferSampleData = true`). Sample accounts: `ada@risktrack.app` / `demo1234` and `admin@risktrack.app` / `admin1234`.
- Flutter tests, notification-function tests, Firestore emulator security tests and deployable rules/indexes.

## Requirements

For the browser build you need:

- A desktop OS with **Chrome or Edge** installed, and a recent stable **Flutter with Dart 3.9+** on the PATH (`flutter --version`). No Android SDK is required for `flutter run -d chrome` or `flutter build web`.
- VS Code with the Flutter and Dart extensions if you want to press F5 instead of typing commands.
- Internet access: Firebase for data, `tile.openstreetmap.org` for map images.

For the Android build you additionally need:

- Windows 10 64-bit (or a supported development OS); `flutter doctor -v` must pass the Android checks.
- Android SDK/Android SDK Platform-Tools, Android SDK API 36 if your Flutter version asks for it, and JDK 17+ (Android Studio's bundled JDK works). Android phone with **Android 7.0 / API 24+** for device testing. No emulator required.

Either way:

- A Firebase project that **you own**, plus optionally Node.js 22 + Firebase CLI for Functions and emulator tests.
- Cloud Storage and deployed Functions may require a Firebase billing plan. Verify the current Firebase plan requirements in your own project.

This repository contains **no Firebase project ID, credentials, service account or map key**. `android/app/google-services.json`, `android/key.properties`, `config/firebase-config.json`, keystores and `.firebaserc` are gitignored. Do not commit private keys or service-account JSON.

## 1. Quick start in a browser

```powershell
git pull
flutter pub get
flutter run -d chrome            # or: flutter run -d edge
```

That is enough to see the whole interface: the app opens on the splash, onboarding and sign-in screens, and - with no Firebase settings - it runs on the built-in sample reports (`ada@risktrack.app` / `demo1234`, `admin@risktrack.app` / `admin1234`).

To use your own Firebase project from the browser, copy the example file once and paste the web app values into it:

```powershell
copy config\firebase-config.example.json config\firebase-config.json
flutter run -d chrome --dart-define-from-file=config\firebase-config.json
```

In VS Code, press **F5** (or Run and Debug) and choose one of the ready-made configurations:

| Configuration | What it does |
| --- | --- |
| **Risk Track · Chrome (Firebase)** | Opens Chrome on `http://localhost:5273` with your Firebase settings. |
| **Risk Track · Edge (Firebase)** | The same, in Microsoft Edge. |
| **Risk Track · Chrome (sample data)** | No Firebase needed; always shows the built-in demo reports. |
| **Risk Track · Android phone** | Runs on a connected, authorized phone. |

Notes for the browser build:

- The first page load compiles the app and downloads the Flutter engine, so it can take a minute. Later loads are fast.
- Location is requested **only** after you tap *Use current GPS* / *Center on my location*, and the browser will show its own permission prompt. Browsers only allow this on `localhost` or an HTTPS address - `http://<ip-address>` and `file://` do not work, which is one reason the published Pages link exists.
- The address shown for a pin is looked up over HTTPS from OpenStreetMap Nominatim. If the lookup is rate limited, the coordinate pair is shown instead, and the report still submits.
- There is no browser push notification support in this build; review updates appear in **Alerts** inside the app.

## 2. Flutter and Android setup (Windows / VS Code)

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

## 3. Connect Firebase (browser and Android)

Both builds read the same Firebase project. A phone can use `google-services.json`, but a browser cannot read that file at all, so the web build takes its settings from `config/firebase-config.json`. With neither present the app still opens - it serves the built-in sample reports and shows a banner instead of pretending to be connected.

1. Create a project in the [Firebase Console](https://console.firebase.google.com/). Add an **Android** app with application ID **`com.risktrack.app`**. That ID is the Android package name in `android/app/build.gradle.kts`, `MainActivity.kt`, and the map User-Agent. It is **not** a Firebase project ID.
2. Download the real `google-services.json` for that app and copy it to **`android/app/google-services.json`**. Never replace it with invented values. The Android Google Services plugin (`com.google.gms.google-services` **4.5.0**) is applied in the app module. If that file is missing, the build warns and continues so the Connect Firebase screen can still open. Rebuild after adding the file. Android uses this file for `Firebase.initializeApp()`; there is no generated `firebase_options.dart` to edit. Firebase Analytics is already declared with BoM **34.19.0** (`firebase-analytics`, no separate version). Enable Google Analytics on the Firebase project if the console asks. Collection starts only after this file is present and the app is rebuilt.
3. Add a **Web** app to the same project (the `</>` icon) and paste the values it shows into the ignored config file:

   ```powershell
   copy config\firebase-config.example.json config\firebase-config.json
   ```

   ```json
   {
     "FIREBASE_API_KEY": "AIzaSy...",
     "FIREBASE_APP_ID": "1:1234567890:web:abcdef123456",
     "FIREBASE_MESSAGING_SENDER_ID": "1234567890",
     "FIREBASE_PROJECT_ID": "your-project-id",
     "FIREBASE_AUTH_DOMAIN": "your-project-id.firebaseapp.com",
     "FIREBASE_STORAGE_BUCKET": "your-project-id.firebasestorage.app",
     "FIREBASE_MEASUREMENT_ID": "G-XXXXXXXXXX"
   }
   ```

   Run with `flutter run -d chrome --dart-define-from-file=config\firebase-config.json`. These values are client identifiers rather than secrets, but they are still kept out of Git, and the GitHub Pages workflow injects them from repository secrets instead.

4. Enable **Authentication → Sign-in method → Email/Password** and configure the email action template/sender for reset emails.
5. Create **Cloud Firestore** and **Cloud Storage** in your project (choose the appropriate region and plan). Deploy the restrictive rules/indexes below **before** inviting users. Do **not** leave production data in Firebase test mode.
6. Install the Firebase CLI, sign in on **your machine**, choose **your own** project and deploy:

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

## 4. Maps and location

- Map tiles use HTTPS `tile.openstreetmap.org` and a named User-Agent with visible **© OpenStreetMap contributors** attribution linking to the copyright page. **No API key** is embedded. The starting viewport is Lagos only as a neutral placeholder: **GPS is never requested at startup**. Tap *Use GPS*, *Center on my location* or *Use current GPS* to prompt for device location. The report form also supports choosing a map pin without permission.
- The public OSM tile server is appropriate for limited development, **not an unlimited production tile plan**. Before a public rollout, read [OSM's tile usage policy](https://operations.osmfoundation.org/policies/tiles/) and migrate to a permitted provider or self-hosted tiles if traffic warrants it. Preserve attribution and identify the client correctly. Offline tiles are not bundled.
- Location comes from `geolocator`: Android/iOS location services on a phone, and the browser Geolocation API on the web. Browsers allow this only on `localhost` or HTTPS, and some embedded/iframe viewers block the permission entirely - use the pin picker there.
- Reverse geocoding is best-effort and layered: the phone's own geocoder first (the `geocoding` plugin implements Android, iOS and macOS only), then OpenStreetMap [Nominatim](https://operations.osmfoundation.org/policies/nominatim/) over HTTPS for browsers and as a fallback, then the printable coordinate pair. GPS-off, denied, permanently denied, timeout and unavailable cases each produce their own guidance, plus a settings shortcut only where the platform has one (no browser has one, so no dead button appears there).
- Nearby distance and text searches operate **within up to 100 most recent server-filtered reports**, not a geospatial index of the entire database. The UI labels this scope. Add pagination and a geohash/geospatial query for a city-scale production rollout.

## 5. Run and test on your Android phone

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

## 6. Publish the web app with GitHub Pages

`.github/workflows/web-pages.yml` runs `flutter analyze`, `flutter test` and `flutter build web`, then publishes `build/web` to GitHub Pages whenever `main` is updated. Every run also attaches the built site as the **risk-track-web** artifact, so a pull request can be previewed by downloading and serving that folder (`python -m http.server` inside it), and a failed deployment never costs you a working build.

One-time setup:

1. **Settings → Pages → Build and deployment → Source: GitHub Actions.** Until this is done the deploy job prints a warning with this exact instruction instead of failing the build.
2. **Settings → Secrets and variables → Actions**, then add the Firebase web values from *Project settings → Your apps → Web app*:
   `FIREBASE_WEB_API_KEY`, `FIREBASE_WEB_APP_ID`, `FIREBASE_WEB_MESSAGING_SENDER_ID`, `FIREBASE_WEB_PROJECT_ID`, and optionally `FIREBASE_WEB_AUTH_DOMAIN`, `FIREBASE_WEB_STORAGE_BUCKET`, `FIREBASE_WEB_MEASUREMENT_ID`.
   Without these secrets the workflow still publishes, and the site opens in sample-data mode.
3. In **Firebase Console → Authentication → Settings → Authorized domains**, add `<your-user>.github.io` so the hosted site can use email sign-in and password resets.
4. Merge the change into `main` (or run the workflow manually from the Actions tab and merge afterwards - only `main` deploys). The job prints the published address: `https://<your-user>.github.io/<repository>/`.

The address is stable: every later push to `main` replaces the site. Share that one link with users, and open it on a phone to use the app without installing anything.

The workflow can also be run manually on any branch; it then builds and tests without deploying, and keeps the web build as a downloadable artifact. The `--base-href` is derived from the repository name automatically, which is what makes the sub-path URL work.

## 7. Release APK

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
| Setup screen after adding JSON | Ensure `android/app/google-services.json` matches the **application ID** and rebuild; `DemoMode.preferSampleData` already defaults to `false`. |
| Gradle warns that `google-services.json` is missing | Expected until the file is added. The app still builds and shows Connect Firebase. |
| `permission-denied` | Deploy the included rules/indexes, confirm sign-in/profile creation and check the admin role if reviewing. New accounts cannot self-promote. |
| Firestore index error | Deploy `firestore.indexes.json`, then wait for Firebase to build the indexes. |
| Map blank | Internet access, OSM tile policy/rate limit and the correct User-Agent; the app does not bundle map tiles. |
| GPS unavailable | Enable Android Location; grant location permission only when prompted; try an outdoor fix or choose a map pin. |
| Camera/gallery upload fails | Use a JPG or PNG smaller than 5 MB, check Storage setup/rules/plan and network. |
| In-app review notification absent | Deploy Functions; reports still submit without Functions. For push, tap **Enable alerts** and grant Android notification permission. |
| Build out of memory | Close other apps, use the phone (not emulator), keep Gradle at 2 workers and ensure Java/Android SDK agree with `flutter doctor -v`. |
| Actions build fails before Gradle | Add `GOOGLE_SERVICES_JSON`. For a Play upload, also add the four `ANDROID_KEYSTORE_*` / `ANDROID_KEY_*` secrets. |
| Blank page in the browser | Open DevTools (F12) and read the console. `flutter run -d chrome` shows the same output in the terminal. Check that `web/index.html` was not edited badly and that the Flutter/Dart extensions are current. |
| Browser shows "Sample data" banner | No Firebase web settings reached the build. Pass `--dart-define-from-file=config\firebase-config.json`, or add the `FIREBASE_WEB_*` secrets for the Pages workflow. |
| Location does nothing in the browser | Browsers only allow GPS on `localhost` or HTTPS. Allow the prompt, check the site permission icon, and use the map pin picker otherwise. GPS is never requested on page load. |
| Address shows coordinates only | The geocoder was rate limited or offline. The report still submits; retry later for a street name. |
| Sign-in works on Android but not on the hosted site | Add `<your-user>.github.io` under Authentication → Settings → Authorized domains. |
| Published page looks unstyled or 404s | Pages must be enabled with source **GitHub Actions**, and the build must use `--base-href /<repository>/` (the workflow derives it). |

### Current workspace verification

This repository was initially only a README, and it was scaffolded into a Flutter project in a separate remote coding sandbox. That sandbox contains **no Flutter, Dart, Java, Android SDK or connected phone**, and it cannot reach the Flutter/pub artifact hosts, so nothing could be compiled there.

Verification therefore happens in GitHub Actions, which does have a Flutter toolchain:

- `.github/workflows/web-pages.yml` runs `flutter pub get`, `flutter analyze`, `flutter test` and `flutter build web --release` on every pull request and push to `main`. The checks reported on a pull request are real output from that runner - a green check means the analyzer found nothing, all Flutter tests passed and the web app compiled.
- Successful runs attach the built site as the **risk-track-web** artifact (14 MB), which anyone can download and serve locally to inspect the release build.
- What CI does **not** cover: the Android APK build (`flutter build apk`), and everything that needs a real device or browser session - camera/gallery, GPS permission prompts, the Firebase project itself and on-phone behaviour. Those still need `flutter run`, on your machine, with your own Firebase project.
