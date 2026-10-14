# Game Companion SDK - AGENTS.md

## Project Context
This is a Flutter-based Game Companion SDK targeting Web, iOS, and Android. It includes an engine capable of running interactive maps (using `flutter_map` with `CRS.simple`), a wiki database, and game guides for various games (with a specific GTA V mock implementation to start).

## Prerequisites
- **Flutter**: Ensure you have Flutter installed (version 3.41.0 or later recommended).
- **Dart**: Dart SDK is included with Flutter.

## Setup & Dependencies
To install the necessary dependencies, run:
```bash
flutter pub get
```

## Running Static Analysis & Linting
To run static analysis and verify there are no linting errors, run:
```bash
flutter analyze
```

## Running Automated Test Suites
To execute unit and widget tests, run:
```bash
flutter test
```

## Architecture Notes
- **State Management**: Uses `flutter_riverpod`.
- **Local Persistence**: Uses `shared_preferences` (e.g., for `CollectionTrackerService`).
- **Routing**: Uses `go_router` for a web-friendly cross-platform experience.
- **Theming**: Uses Material 3 design, taking inspiration from apps like YouTube and Revolut.
