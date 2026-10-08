# OCR Expense Tracker

A production-style Flutter 3.x mini-project that turns physical receipts into editable local expense records.

## Features

- Camera viewfinder with receipt framing overlay
- Flash/torch toggle
- Tap-to-focus
- Gallery import
- Deterministic receipt crop pipeline
- Google ML Kit on-device text recognition
- Regex/heuristic extraction of merchant, VND total and date
- Confidence indicators and mandatory human review
- SQLite persistence with indexes
- Receipt original + thumbnail cache in application storage
- Expense CRUD, search, category filters and swipe delete
- Food / Study / Travel / Gear / Entertainment categories
- Animated donut chart using CustomPainter
- Animated seven-day bar chart using CustomPainter
- Offline-first: no cloud OCR API is required

## Architecture

Camera -> Crop -> ML Kit -> Regex Parser -> Review -> SQLite -> Dashboard

Layers:
- features/: presentation and user workflows
- state/: application state
- data/: database, repository and device services
- core/: constants, formatting and theme
- widgets/: reusable UI and CustomPainter charts

## Requirements

- Flutter 3.44.x or newer stable
- Dart 3.12+
- Android Studio / Android SDK for Android
- Xcode for iOS
- Physical device or emulator with camera support

## Run

    flutter pub get
    flutter analyze
    flutter test
    flutter run

For a fresh checkout, generate native platform folders if they are not present:

    flutter create --platforms=android,ios .

## Android release

    flutter build apk --release

Artifact: build/app/outputs/flutter-apk/app-release.apk

The GitHub Actions release workflow can build the APK in CI.

## OCR notes

ML Kit recognition is performed on-device for the supported mobile platforms. OCR output is treated as untrusted input: the parser supplies confidence values and the user must review fields before persistence.

## Data model

Money is stored as integer VND, avoiding floating-point currency errors. SQLite stores receipt paths rather than image bytes.

## Submission

1. GitHub repository
2. Release APK / demo video
3. 2–4 page technical report using the course template

See docs/architecture.md, docs/demo-script.md, and docs/report-outline.md.
