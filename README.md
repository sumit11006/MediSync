# MediSync

MediSync is a Flutter-based medicine ordering and admin management app with Firebase-backed authentication, Firestore data storage, Cloudinary uploads, and a small WhatsApp OTP backend.

## Project Layout

The repository contains the Flutter app in the root `lib/` directory, Firebase platform files under `android/`, `ios/`, `web/`, `windows/`, `linux/`, and `macos/`, and the WhatsApp bot backend in `drugbee_backend/`.

## Secrets And Env

Hardcoded service keys were removed from the Flutter auth and upload flow. The app now reads them from the root `.env` file through `flutter_dotenv`.

Use the following variables:

```env
RENFLAIR_API_KEY=your-renflair-key
RENFLAIR_COUNTRY_CODE=91
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_UPLOAD_PRESET=your-upload-preset
CLOUDINARY_BANNER_UPLOAD_PRESET=your-banner-upload-preset
```

Copy `.env.example` to `.env` and fill in your values. The root `.env` file is ignored by git.

Firebase `apiKey` values in `lib/firebase_options.dart` and `android/app/google-services.json` are public client configuration, not server secrets. Keep private service-account credentials out of the repository.

## Setup

1. Install Flutter and Node.js.
2. Run `flutter pub get` from the project root.
3. Install backend dependencies with `cd drugbee_backend && npm install`.
4. Make sure `.env` is populated before launching the app.

## Run The App

```bash
flutter run
```

## Run The Backend

```bash
cd drugbee_backend
node index.js
```

The backend listens on `PORT` if defined, otherwise it uses `3000`.

## Notes

The app uses Firebase Firestore, Cloudinary for uploads, and WhatsApp-based OTP flows for registration and PIN reset. If you rotate any external service key, update `.env` locally and rebuild the app.
