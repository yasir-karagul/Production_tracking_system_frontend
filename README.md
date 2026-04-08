# Maia Porselen Frontend

Flutter-based production tracking application for factory operations.
This client supports offline-first data entry, background synchronization, and role-based workflows.

## Table of Contents

- [Highlights](#highlights)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Supported Platforms](#supported-platforms)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [Development Commands](#development-commands)
- [Build Commands](#build-commands)
- [Offline + Sync Behavior](#offline--sync-behavior)
- [Localization](#localization)
- [Security & Data Handling](#security--data-handling)
- [Troubleshooting](#troubleshooting)
- [Flutter References](#flutter-references)

## Highlights

- Role-based authentication (`worker`, `supervisor`, `admin`)
- Production flow modules: production, quality, packaging, shipment
- Offline-first local persistence with Drift (SQLite)
- Sync queue with retry/backoff and mobile background sync (Workmanager)
- Product/pattern catalog flows including file/image import
- Turkish-first localization (`tr_TR`) and shift-aware access behavior

## Tech Stack

- Flutter / Dart (`>=3.2.0 <4.0.0`)
- State management: Riverpod
- Networking: Dio (+ auth/redirect/failover interceptors)
- Local database: Drift + SQLite
- Secure storage: `flutter_secure_storage`
- Background tasks: Workmanager (Android/iOS)

## Architecture

Project follows a layered structure:

- `presentation/`: UI screens, widgets, Riverpod state providers
- `application/`: app-level orchestration (sync/caching/business flows)
- `data/`: remote/local data sources, repositories, models, database
- `domain/`: core entities
- `core/`: constants, theme, networking, utilities, shared errors

## Project Structure

```text
lib/
  application/
  core/
    constants/
    errors/
    network/
    theme/
    utils/
  data/
    database/
    datasources/
      local/
      remote/
    models/
    repositories/
  domain/
    entities/
  presentation/
    providers/
    screens/
    widgets/
  main.dart
```

## Supported Platforms

- Android
- iOS
- Web
- Windows
- macOS
- Linux

## Prerequisites

- Flutter SDK (stable channel)
- Dart SDK compatible with `pubspec.yaml`
- A running backend API endpoint compatible with this client

## Getting Started

1. Install dependencies:
   ```bash
   flutter pub get
   ```
2. Run the app:
   ```bash
   flutter run --dart-define=API_BASE_URL=http://localhost:8000/api/v1
   ```

## Configuration

API base URL is configured using `--dart-define`:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

Notes:

- For Android emulator, `http://10.0.2.2:8000/api/v1` is commonly used.
- If `API_BASE_URL` is not provided, the app uses internal fallback candidates.
- Do not commit private endpoints, credentials, tokens, or environment-specific secrets.

### Configuration Reference

| Key | Required | Example | Purpose |
| --- | --- | --- | --- |
| `API_BASE_URL` | No | `http://localhost:8000/api/v1` | Overrides default API base URL candidates at startup. |

## Development Commands

Analyze:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

Regenerate Drift/build-runner code:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Watch mode for code generation:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

Regenerate launcher icons:

```bash
dart run flutter_launcher_icons
```

## Build Commands

Android APK:

```bash
flutter build apk --release
```

Android App Bundle:

```bash
flutter build appbundle --release
```

Web:

```bash
flutter build web --release
```

Windows:

```bash
flutter build windows --release
```

## Offline + Sync Behavior

- Records are stored locally and queued when network is unavailable.
- Sync queue supports retry/backoff and failure tracking.
- Periodic sync task runs on mobile platforms (Android/iOS).
- Desktop platforms skip Workmanager background scheduling.

## Localization

- Application locale is Turkish (`tr_TR`).
- Date formatting and UI localization delegates are configured for Turkish usage.

## Security & Data Handling

- Access/refresh tokens are stored with secure storage APIs.
- Avoid logging or sharing sensitive production data.
- Keep configuration and deployment secrets outside version control.

## Troubleshooting

- API unreachable on Android emulator:
  Use `http://10.0.2.2:<port>` instead of `localhost`.
- Drift codegen issues:
  Run `dart run build_runner build --delete-conflicting-outputs`.
- Sync not running in background on desktop:
  Expected behavior; Workmanager tasks are mobile-only in this app.

## Flutter References

- [Flutter documentation](https://docs.flutter.dev/)
- [Flutter cookbook](https://docs.flutter.dev/cookbook)
