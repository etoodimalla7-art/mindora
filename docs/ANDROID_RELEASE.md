# Android Release Build

## Why this doc exists instead of a finished .apk

This project has been built entirely inside a sandboxed environment
with **no Flutter SDK and no access to `storage.googleapis.com`** (the
domain Flutter's own tooling downloads the Dart SDK and Android
engine artifacts from — confirmed by actually attempting it: cloning
`flutter/flutter` from GitHub succeeds, since `github.com` is
reachable, but `flutter --version` fails at the Dart-SDK-download step
with a truncated/corrupt archive, because the request to
`storage.googleapis.com` never reaches the real server). This means
**no command in this codebase's history has ever run through an
actual Flutter compiler** — every `.dart` file across all 18 prior
phases was written to correct syntax and checked for balanced
braces/parens, never compiled.

What this phase *did* produce, by hand, matching what `flutter create`
would normally generate automatically: the entire `android/` platform
directory (previously nonexistent — this project had no native
Android project at all until now), a release-ready `build.gradle` with
real signing-config wiring, a correctly-scoped `AndroidManifest.xml`
(validated as well-formed XML), launch theme resources, and
`flutter_launcher_icons`/`flutter_native_splash` configuration wired to
the same `BrandConfig` the app itself reads from.

**The one thing that cannot be verified here**: that this Gradle
project actually compiles. Follow the steps below on a machine with a
real Flutter install to find out — and if something doesn't compile,
it's the first real compiler feedback this codebase has ever received,
so treat it as genuinely new information, not a re-check of something
already confirmed working.

## Steps to produce a real release build

### 1. Install prerequisites
- Flutter SDK (stable channel) — https://docs.flutter.dev/get-started/install
- Android Studio or just the Android SDK command-line tools, with a
  recent `platform-tools` and at least one `platforms;android-34`
  installed
- A JDK 17 (Android Studio bundles one; `flutter doctor` will tell you
  if yours doesn't match)

### 2. First-time project setup
```bash
cd frontend/mindora_app
flutter pub get          # this ALSO auto-generates android/local.properties
```
If `local.properties` isn't generated automatically for any reason,
copy `android/local.properties.example` to `android/local.properties`
and fill in real paths.

### 3. Generate a real upload keystore (one-time, per app)
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
Then copy `android/key.properties.example` to `android/key.properties`
and fill in the password/alias/path you just used. **Never commit
`key.properties` or the `.jks` file** — both are gitignored already.

### 4. Real branding
A real icon (`assets/brand/icon.png`) and splash image
(`assets/brand/splash.png`) now exist in the project — the logo you
provided, saved at both paths and declared in `pubspec.yaml`'s
`flutter: assets:` list. Generate the actual Android launcher
icons/splash screens from them:
  ```bash
  dart run flutter_launcher_icons
  dart run flutter_native_splash:create
  ```
Still outstanding: change `applicationId` in `android/app/build.gradle`
from the `com.example.mindora_app` placeholder to a real, owned
reverse-domain identifier before any Play Store submission — Play
Store will reject `com.example.*`.

### 5. Build
```bash
flutter build apk --release      # a single universal APK
# or, for Play Store submission (smaller per-device downloads):
flutter build appbundle --release
```
Output lands at `build/app/outputs/flutter-apk/app-release.apk` or
`build/app/outputs/bundle/release/app-release.aab`.

### 6. Sanity-check before submitting anywhere
- Install the APK on a real device (`flutter install` or manually) and
  click through onboarding, login, and at least one AI chat message —
  this is the app's first real runtime test of any kind
- Confirm the app icon and splash screen are the real branding, not
  Flutter's default
- Confirm camera/microphone permission prompts appear when using
  vision/voice mode, and that denying them fails gracefully rather
  than crashing

## Known gaps to close before a real Play Store submission
- Real app icon/splash images (see step 4) — nothing is at those
  asset paths yet
- A real `applicationId` (see step 4)
- Play Store's data-safety form, privacy policy URL, and store listing
  — none of which are code changes, but all of which block submission
- `minSdkVersion 23` was chosen for compatibility with this project's
  plugin set (`record`, `image_picker`, `audioplayers`); revisit if the
  target market's device profile needs a lower floor
