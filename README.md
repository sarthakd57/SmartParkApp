# SmartPark App

SmartPark is a Flutter parking app for finding lots, checking availability, booking slots, and managing parking activity from a mobile or desktop client.

<img width="230" height="506" alt="Screenshot 2026-08-02 073707" src="https://github.com/user-attachments/assets/9dd94aca-c041-4447-852a-68610501b638" />
<img width="240" height="506" alt="Screenshot 2026-08-02 073651" src="https://github.com/user-attachments/assets/6ec40497-003c-4e09-a090-0609075ba06e" />
<img width="275" height="515" alt="Screenshot 2026-08-02 073557" src="https://github.com/user-attachments/assets/529cd7e5-2506-46ea-ab98-585cacbc3366" />
<img width="279" height="520" alt="Screenshot 2026-08-02 073520" src="https://github.com/user-attachments/assets/2988c3d6-0040-4c46-ad2a-9580cda14087" />

## What it does

- Browse parking lots on a map and in list views.
- Search for locations and nearby parking areas.
- View lot details, availability, and pricing.
- Book parking slots through the backend.
- Manage subscriptions and saved bookings.
- Log in as an admin to access the admin dashboard.
- AI powered lot occupancy detection through Yolov8 model.
- Switch the app backend URL from the built-in settings screen.

## Setup

1. Install APK file (uploaded under releases section) and run directly on android devices
2. Alternatively, clone repository and after installing flutter sdk, run using the following commands:

```bash
flutter pub get
flutter run
flutter build apk
flutter build ios
flutter build web
```

## Backend Configuration

The app uses a saved API base URL and falls back to a default backend URL if none is configured.

- Default backend URL: `http://4.145.90.51:5000`
- You can change the backend URL from the in-app Settings screen.

If you are running the backend locally, update the app settings to point to your local server before logging in.





