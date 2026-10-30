# NeighbourConnect

NeighbourConnect is a Flutter app for bringing a neighbourhood together. Members
can share updates, discuss posts, organise events, and report local issues. The
app combines a Flutter client with SQLite persistence and a Node.js/MySQL
backend foundation.

## Features

- Register and sign in to an account.
- Choose a neighbourhood and browse its community feed.
- Create posts, add images, comment, and like posts.
- Create and view neighbourhood events.
- Report and review community issues.
- Browse neighbourhood and community information.
- Use an administrator dashboard for local community management.

## Tech stack

- **App:** Flutter and Dart
- **Database:** SQLite (`sqflite`) for the Flutter app
- **Backend:** Node.js, Express, and MySQL

> The project includes both a Flutter application and a backend foundation.
> Backend deployment and integration can be configured to suit the target
> environment.

## Get started

### Requirements

- Flutter SDK with Dart 3.12.2 or newer.
- An Android device or emulator (or another Flutter-supported platform).

### Run the app

From the project directory:

```bash
flutter pub get
flutter run
```

To build a release APK for Android:

```bash
flutter build apk --release
```

The APK is written to
`build/app/outputs/flutter-apk/app-release.apk`.

### Run checks

```bash
flutter analyze
flutter test
```

## Project layout

```text
lib/
  database/    SQLite database and data operations
  screens/     Welcome, account, feed, event, and admin screens
  services/    API-related service code
  theme/       App colors and Material theme
  main.dart    App entry point
backend/       Optional Express and MySQL service
test/          Flutter widget and unit tests
```

## Optional backend

The backend requires Node.js and a MySQL database. To run it locally, create
`backend/.env` from `backend/.env.example`, set `DB_HOST`, `DB_USER`,
`DB_PASSWORD`, and `DB_NAME` to match your MySQL setup, then run:

```bash
cd backend
npm install
npm start
```

The MySQL database and tables must be set up separately. Keep real credentials
in `.env`; do not commit them. Configure the app with your backend deployment
when connecting it to a shared service.

## Data and security notes

- Images can be uploaded or referenced by URL.
- `divya@gmail.com` is configured as the Super Admin account. The app does not
  verify email ownership. This client-side role check is for
  demonstration purposes and should not be used to secure a production service.
- Do not use real or sensitive personal data when evaluating this project.
