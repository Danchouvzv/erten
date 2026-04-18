<div align="center">

```
███████╗██████╗ ████████╗███████╗███╗   ██╗
██╔════╝██╔══██╗╚══██╔══╝██╔════╝████╗  ██║
█████╗  ██████╔╝   ██║   █████╗  ██╔██╗ ██║
██╔══╝  ██╔══██╗   ██║   ██╔══╝  ██║╚██╗██║
███████╗██║  ██║   ██║   ███████╗██║ ╚████║
╚══════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═══╝
```

**Your mind, amplified.**  
*A cinematic productivity OS for people who ship things.*

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter)
![iOS](https://img.shields.io/badge/Platform-iOS-black?style=flat-square&logo=apple)
![CI](https://img.shields.io/badge/CI-Fastlane%20→%20TestFlight-orange?style=flat-square)
![AI](https://img.shields.io/badge/AI-Fine--tuned%20LLM-blueviolet?style=flat-square)

</div>

---

## What is Erten?

Erten is not a to-do list. It is a **personal operating system** built around how high-performers actually think — in goals, sprints, and focus windows.

At its core sits a **fine-tuned LLM** trained specifically on productivity frameworks, goal decomposition, and deep-work scheduling. It doesn't just answer questions — it *thinks alongside you*, breaking down ambiguous goals into executable plans, adapting to your energy levels, and learning your working style over time.

The interface wraps all of this in a Neo-noir cinematic shell — dark gradients, fluid motion, and deliberate silence where most apps scream for attention.

---

## Core pillars

| Pillar | What it means |
|---|---|
| **AI Planning** | Fine-tuned LLM that decomposes goals into focused execution steps |
| **Deep Focus** | Distraction-free session runner with adaptive time blocks |
| **Goal Architecture** | Hierarchical goal system — vision → milestone → task |
| **Cinematic UI** | Neo-inspired dark design language, built in Flutter |
| **CI/CD** | One-command TestFlight deploys via Fastlane |

---

## The AI layer

The intelligence behind Erten is powered by a **fine-tuned language model** trained on curated data spanning productivity research, cognitive science, and real-world goal-setting patterns.

Unlike generic assistants, the model is optimized for a single purpose: *turning vague intentions into concrete, time-bound actions.*

Key behaviors:
- **Goal decomposition** — takes a high-level ambition and breaks it into a sequenced plan
- **Context retention** — understands your current load and adjusts suggestions accordingly
- **Execution framing** — outputs are always actionable, never abstract
- **Tone calibration** — responds like a sharp thinking partner, not a chatbot

The model backend lives in `lib/ai_service.dart` and communicates over a secure API endpoint.

---

## Architecture

```
lib/
├── main.dart              # App entry, routing
├── app_state.dart         # Global state management
├── ai_service.dart        # Fine-tuned LLM integration layer
├── ui_kit.dart            # Design system tokens & components
└── screens/
    ├── splash.dart        # Cinematic Neo-style entry screen
    ├── dashboard.dart     # Personal OS home view
    ├── goals.dart         # Goal architecture tree
    ├── focus_session.dart # Deep work runner
    ├── execution.dart     # Task execution mode
    ├── profile.dart       # User settings & stats
    └── premium.dart       # Pro tier features
```

---

## Quick start

```bash
# 1. Get dependencies
flutter pub get

# 2. Run in development
flutter run

# 3. Deploy to TestFlight
FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD=<app-specific-pwd> fastlane beta
```

**Requirements:** Flutter 3.x · Xcode 15+ · CocoaPods · Fastlane

---

## CI / CD

Every push triggers a Fastlane pipeline that:
1. Runs Flutter tests
2. Archives the iOS build with manual signing
3. Exports a signed IPA
4. Uploads directly to TestFlight

Provisioning: `ERTEN_AppStore_Distribution.mobileprovision`  
Bundle ID: `com.erten.app`

---

## Troubleshooting

**TestFlight upload fails** → export `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD` with an app-specific password from appleid.apple.com  
**Xcode archive fails** → open `ios/Runner.xcworkspace` and verify signing & provisioning in project settings  
**Flutter build errors** → run `flutter clean && flutter pub get` and retry

---

## Contributing

Pull requests are welcome. The best areas to contribute:

- UI motion design and micro-interactions
- AI prompt architecture and model behavior tuning
- New productivity frameworks in the goal engine
- Performance profiling and startup time

Open an issue first to discuss significant changes.

---

<div align="center">

*Built for the ones who refuse to coast.*

</div>
