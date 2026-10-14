# Game Companion App SDK

A generic, cross-platform Flutter application and SDK template designed to build interactive companion apps for video games. It targets **Web, iOS, and Android**.

Currently, the SDK features a mock data implementation for **Grand Theft Auto V**.

## 🚀 Features

* **Cross-Platform:** Write once, run on Web, iOS, and Android seamlessly.
* **Interactive Map Engine:** Powered by `flutter_map` utilizing `CRS.simple`, enabling custom non-GPS coordinate map overlays (like fictional video game maps). Includes offline fallback support.
* **Wiki & Database:** Filterable lists and detail screens for game items, weapons, vehicles, etc.
* **Game Guides:** Markdown-supported article engine with external video linking capabilities.
* **Global Search:** Simultaneously query POIs (Points of Interest) and Wiki items from anywhere in the app.
* **Collection Tracking:** Persistent local storage using `shared_preferences` to track collected items across sessions.
* **Game Switcher:** Built-in registry to handle multiple game manifestations (e.g., GTA V, RDR2, Witcher 3).

## 🛠️ Tech Stack & Architecture

* **Framework:** [Flutter](https://flutter.dev/) (Dart)
* **State Management:** [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod)
* **Routing:** [`go_router`](https://pub.dev/packages/go_router) for deep-linking and web URL support.
* **Storage:** [`shared_preferences`](https://pub.dev/packages/shared_preferences)
* **Mapping:** [`flutter_map`](https://pub.dev/packages/flutter_map) + [`latlong2`](https://pub.dev/packages/latlong2)

### Directory Structure

The project separates the generic SDK engine from game-specific data:
* `lib/sdk/`: Contains the generic models, map engine, registry, and storage services.
* `lib/games/`: Contains the specific mock data/fixtures for games (e.g., `lib/games/gtav/fixtures.dart`).
* `lib/ui/`: Contains the core application shell, theming, widgets, and screens.

## 💻 Running Locally

### Prerequisites
* Ensure you have [Flutter](https://docs.flutter.dev/get-started/install) installed (version 3.41.0 or later recommended).

### Setup
1. Clone the repository.
2. Navigate into the application directory:
   ```bash
   cd game_companion_sdk
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the application (choose your target device/browser):
   ```bash
   flutter run
   ```

### Testing & Linting
To ensure code quality, run static analysis and tests:
```bash
# Run Linter
flutter analyze

# Run Unit and Widget Tests
flutter test
```

## 🌐 Web Deployment (GitHub Pages)

This repository includes a pre-configured GitHub Actions workflow (`.github/workflows/flutter_web_deploy.yml`) that automatically builds and deploys the application to **GitHub Pages** whenever changes are pushed to the `main` branch.

### How to Enable:
1. Go to your repository on GitHub.
2. Navigate to **Settings > Pages** (in the left sidebar).
3. Under **Build and deployment**, set the **Source** to **GitHub Actions**.
4. Push your code to the `main` branch! The action will run, and shortly after, your app will be live.

---
*Created as a generic SDK template. Follow instructions in `AGENTS.md` for AI-assisted development guidelines.*
