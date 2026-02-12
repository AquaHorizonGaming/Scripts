# Flutter Grocery App

This Flutter application supports three roles: **customer**, **shopper**, and **admin**. It follows the MVVM pattern and runs on Android, iOS, and Web (as a PWA). All API calls use the FastAPI backend at `https://api.lostmediastudios.com`.

Role-based routing uses the JWT returned from the backend after login. Depending on the user role the app loads a different dashboard.

## Directory Layout

```
lib/
  main.dart            - entry point with login flow and role routing
  common/              - shared models and API client
  customer/            - customer UI and view models
  shopper/             - shopper UI and view models
  admin/               - admin (web) UI and view models
```

## Features

- Email/password authentication via FastAPI
- Role-based dashboards for **customer**, **shopper**, and **admin**
- Cross-platform build: Android, iOS, and Web (PWA)
- API client powered by `dio`
- Secure token storage with `flutter_secure_storage`
- Responsive UI across phone, tablet, and desktop

The code leaves TODO comments where real backend calls, maps, and notifications would be implemented.

Run `flutter run` or `flutter build web` once dependencies are installed and Flutter SDK is available.
