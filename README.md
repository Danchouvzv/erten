# Erten — productivity with cinematic polish

Erten is a modern Flutter app that blends minimalist UX with powerful
AI-driven assistance. Built for speed and clarity, it ships with a
Neo-inspired cinematic splash, smart scheduling powered by Google
Gemini, and a CI pipeline that automates TestFlight releases via Fastlane.

Key facts
- **Bundle ID:** `com.erten.app`
- **Team ID:** `PN3N2NQBHC`
- **CI:** `fastlane beta` (exports IPA and uploads to TestFlight)

Why this repo
- Clean Flutter architecture for rapid iteration.
- Gemini-backed goal generation and planning (`lib/gemini_service.dart`).
- Manual signing + dedicated App Store provisioning for reliable uploads.

Quick start
1. Install Flutter, Xcode, CocoaPods and Homebrew gems for Fastlane.
2. Fetch Dart packages:

```bash
flutter pub get
```

3. Build & upload to TestFlight (uses an app-specific password):

```bash
FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD=<app-specific-pwd> fastlane beta
```

Gemini integration
- API client: `lib/gemini_service.dart` (uses `gemini-1.5-flash`).
- Set your Gemini API key securely in the environment before running features that call the model.

Files of interest
- `lib/screens/splash.dart` — cinematic Neo-style splash screen
- `lib/gemini_service.dart` — centralized Gemini calls
- `fastlane/Fastfile` — build, archive and TestFlight upload lanes

Troubleshooting
- If TestFlight upload fails due to 2FA, use an app-specific password and export it via `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD`.
- If Xcode archive fails, open `ios/Runner.xcworkspace` in Xcode and inspect signing & provisioning.

Contributing
- Open issues/PRs for UI polish, Gemini prompt improvements, or CI tweaks.

License & contacts
- Add your preferred license file. For questions, ping the maintainer.

Enjoy shipping fast, elegant iOS builds. 🚀
