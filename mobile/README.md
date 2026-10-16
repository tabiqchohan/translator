# LingoVerse — AI Powered Translator (Mobile)

Flutter mobile client for the **LingoVerse** app: AI-powered text, voice, camera
(OCR) and document translation with synchronized history and favorites.

The backend is a Next.js API deployed on Vercel
(`https://translator-two-dusky.vercel.app`). This package is the Flutter client
that talks to those APIs.

## Features

- **Text** — type/paste text, auto language detection, swap source/target.
- **Voice** — speech-to-text (`speech_to_text`) then translate automatically.
- **Camera** — on-device OCR (`google_mlkit_text_recognition`) then translate.
- **Document** — upload `PDF` / `DOCX` / `TXT`, server parses, then translate.
- **Conversation** — two-language chat mode with mixed typing & voice input for both sides.
- **History & Favorites** — searchable, pull-to-refresh, offline cache, delete with
  confirm + undo, and toggle favorite.
- **Export** — share/download history as a CSV file.
- **Text-to-Speech** — listen to translations (`flutter_tts`) with adjustable
  speech rate **and pitch**, copy, share.
- **Detected language badge** — offline Unicode-script detection shows a
  "Detected" label when translating from auto.
- **Live Chat Translate** — native overlay that translates incoming chat messages
  from WhatsApp, Messenger, Telegram, Instagram, SMS, Snapchat, Discord, Signal,
  Viber, Line, and WeChat in real time:
  - **Notification reader** — reads chat notifications (`NotificationListenerService`)
    and posts each translation as a **persistent notification** (stays in the shade
    until dismissed) with **Copy / Reply / Dismiss** actions.
  - **Floating bubble** — optional quick-peek bubble over any app.
  - **Reply translator** — a floating bar over any chat: type a reply, translate it
    into the other person's language, then copy & paste it into the chat.
  - **History, dark theme, per-app toggles** and rate-limit batching.
    Works in the background even while the app is closed.
- **Offline awareness** — a banner appears when the network is unavailable;
  history stays readable from the local cache.
- **Onboarding & rating** — first-launch walkthrough and an in-app rating
  prompt after a few translations.
- **Profile, Privacy, Terms** — dedicated screens plus account & data section.
- **58 languages** — with a searchable picker and recent-language shortcuts.
- **Auth** — register, login (NextAuth credentials), sign out, delete account,
  forgot password.
- **Theming** — light / dark / system, persisted with `shared_preferences`.
- **Haptics & accessibility** — haptic feedback and semantic labels on key
  controls; tabs keep their state when switching via `IndexedStack`.

## Tech stack

| Area            | Package |
| --------------- | ------- |
| State           | `provider` |
| HTTP            | `dio` + `cookie_jar` / `dio_cookie_manager` |
| Storage         | `path_provider`, `shared_preferences` |
| Network status  | `connectivity_plus` |
| Voice           | `speech_to_text`, `flutter_tts` |
| OCR             | `google_mlkit_text_recognition` |
| Files           | `image_picker`, `file_picker`, `share_plus`, `csv`, `path_provider` |
| UI              | `google_fonts` (Plus Jakarta Sans), `flutter_spinkit`, `fluttertoast` |

## Project structure

```
lib/
  main.dart                 App entry, theme, providers
  core/
    api_client.dart         Dio + cookie jar singleton
    constants.dart          Base URL + language list
    language_detector.dart  Offline Unicode-script language detection
    validators.dart         Password validation
  models/                   User, HistoryEntry
  providers/                AuthProvider, ConnectivityProvider, HistoryProvider, SettingsProvider
  services/                 AuthService, ExportService, HistoryService, TranslateService
  screens/                  Splash, Login, Register, ForgotPassword, Home, Profile, Privacy, Terms, LiveChat
  tabs/                     Text, Voice, Camera, Document, Conversation, History, Settings
  widgets/                  LanguageSelector, OnboardingOverlay, RatingPrompt, TranslationCard, ErrorBanner
test/                       Unit + widget tests
```

## Backend endpoints used

| Method | Endpoint | Purpose |
| ------ | -------- | ------- |
| POST   | `/api/translate` | Translate text |
| POST   | `/api/register` | Create account |
| GET/POST | `/api/auth/csrf`, `/api/auth/callback/credentials`, `/api/auth/session`, `/api/auth/signout` | NextAuth session flow |
| POST   | `/api/account/delete` | Delete account |
| GET/POST/DELETE/PATCH | `/api/history` | History CRUD + favorite |
| POST   | `/api/document` | Parse uploaded document |

## Getting started

Requirements: Flutter `>= 3.0.0`, Dart SDK `>= 3.0.0`.

```bash
flutter pub get
flutter run
```

The API base URL is configured in `lib/core/constants.dart` (`AppConstants.baseUrl`).

## Quality checks

```bash
flutter analyze
flutter test
```

## Building

```bash
flutter build apk --release      # Android
flutter build appbundle          # Play Store
flutter build ios --release      # iOS
```

App icons are generated from `assets/images/logo.jpg` via `flutter_launcher_icons`.

## Notes

- Live Chat Translate uses two Android permissions — **notification access** (to
  read incoming messages) and **display over other apps** (for the floating
  bubble & reply bar), plus the standard **notifications** runtime permission.
  The user grants them one-by-one from the Live Chat settings screen. Everything
  is translated server-side and the last 100 live translations are stored on the
  device only.
- The Android app is published as a full-screen Trusted Web Activity (TWA)
  (see Digital Asset Links in `android/`).
- Speech recognition and TTS depend on languages supported by the device.
