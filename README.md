# SmartPark App

SmartPark is a Flutter parking app for finding lots, checking availability, booking slots, and managing parking activity from a mobile or desktop client.

## What it does

- Browse parking lots on a map and in list views.
- Search for locations and nearby parking areas.
- View lot details, availability, and pricing.
- Book parking slots through the backend.
- Manage subscriptions and saved bookings.
- Log in as an admin to access the admin dashboard.
- Switch the app backend URL from the built-in settings screen.

## Tech Stack

- Flutter
- Provider for app state
- HTTP API client
- flutter_map, geolocator, and geocoding for map and location features
- shared_preferences for storing the backend URL locally
- razorpay_flutter for payment flows

## Requirements

- Flutter SDK 3.11 or newer
- Dart SDK included with Flutter
- A running SmartPark backend API

## Setup

1. Install Flutter and verify your environment with `flutter doctor`.
2. Open this folder in your editor or terminal.
3. Fetch dependencies with `flutter pub get`.
4. Run the app with `flutter run`.

## Backend Configuration

The app uses a saved API base URL and falls back to a default backend URL if none is configured.

- Default backend URL: `http://4.145.90.51:5000`
- You can change the backend URL from the in-app Settings screen.

If you are running the backend locally, update the app settings to point to your local server before logging in.

## Run Commands

```bash
flutter pub get
flutter run
flutter build apk
flutter build ios
flutter build web
```

## Project Layout

- `lib/main.dart` - App bootstrap and provider setup
- `lib/screens/` - UI screens for login, home, maps, bookings, settings, and admin tools
- `lib/providers/` - App state and business logic
- `lib/services/` - API client, config storage, and booking-related services
- `assets/` - Images and branding assets

## Notes

- The app expects a backend that exposes the SmartPark API routes used by the services in `lib/services/`.
- Local Flutter and Android build artifacts are ignored by git in this repo.
- App-local secrets and editor files such as `.env` and `.vscode/` are intentionally ignored.
