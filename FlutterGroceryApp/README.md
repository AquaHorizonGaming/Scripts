# Flutter Grocery App

This Flutter application supports three roles: **customer**, **shopper**, and **admin**. It follows the MVVM pattern and runs on Android, iOS, and Web (as a PWA). The app communicates with a FastAPI backend hosted at `https://api.lostmediastudios.com`.

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

- Email/password authentication (placeholder)
- Role-based dashboards for customer, shopper, and admin
- Placeholder API client using `dio`
- Secure token storage with `flutter_secure_storage`
- Responsive Flutter UI for mobile and web

The code leaves TODO comments where real backend calls, maps, and notifications would be implemented.

Run `flutter run` or `flutter build web` once dependencies are installed and Flutter SDK is available.
