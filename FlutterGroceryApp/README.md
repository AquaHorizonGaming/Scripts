# Flutter Grocery App

This is a skeleton Flutter application supporting three roles: **customer**, **shopper**, and **admin**. The project is structured using the MVVM pattern and targets Android, iOS, and Web (PWA).

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
