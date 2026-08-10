# 🩺 MediSync

<p align="center">
  <b>A Cross-Platform Medicine Ordering & Healthcare Management Ecosystem</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-Cross--Platform-blue?style=flat-square&logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Node.js-Backend-green?style=flat-square&logo=nodedotjs" alt="Node.js">
  <img src="https://img.shields.io/badge/Firebase-Firestore%20%26%20Auth-orange?style=flat-square&logo=firebase" alt="Firebase">
  <img src="https://img.shields.io/badge/Cloudinary-Media%20Storage-blueviolet?style=flat-square&logo=cloudinary" alt="Cloudinary">
</p>

---

## 🚀 About The Project

**MediSync** is an end-to-end full-stack healthcare platform engineered to bridge the gap between patients, pharmacies, and administrators. It features a cross-platform Flutter application paired with an independent Node.js microservice handling WhatsApp-based verification flows. Designed specifically to streamline critical medicine procurement and administrative oversight, the ecosystem handles secure data storage, fast media rendering, and reliable communication pipelines.

---

## 🛠️ Tech Stack & Architecture

* **Frontend Client:** Flutter (Cross-platform UI for mobile and web deployment)
* **Backend Microservice:** Node.js (WhatsApp OTP and bot logic handler)
* **Database & Security:** Firebase Firestore (Real-time data synchronization) & Firebase Authentication
* **Media Management:** Cloudinary (Dynamic uploads for assets and banner management)
* **Verification Flow:** Renflair API integrated via WhatsApp messaging channels

---

## 📁 Project Structure

```text
MediSync/
├── lib/                      # Core Flutter application source files & UI components
├── android/                  # Android-specific platform configurations & Firebase setup
├── ios/                      # iOS-specific platform configurations & entitlements
├── web/                      # Web platform entry points and assets
├── windows/                  # Windows desktop embedding layer
├── linux/                    # Linux desktop embedding layer
├── macos/                    # macOS desktop embedding layer
└── drugbee_backend/          # Node.js backend workspace for WhatsApp OTP workflows
```

---

## ⚙️ Environment Variables & Configuration

Hardcoded secrets have been decoupled from the client code base. The app securely reads environment variables from a root `.env` file via `flutter_dotenv`.

1. Copy the template or create a root `.env` file.
2. Populate the required keys:

```env
RENFLAIR_API_KEY=your-renflair-key
RENFLAIR_COUNTRY_CODE=91
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_UPLOAD_PRESET=your-upload-preset
CLOUDINARY_BANNER_UPLOAD_PRESET=your-banner-upload-preset
```

> **Security Note:** Firebase `apiKey` credentials found in `lib/firebase_options.dart` and `android/app/google-services.json` are public client keys by design. Keep server-side credentials and private service-account keys strictly out of version control.

---

## 🚀 Setup & Installation

Ensure you have **Flutter SDK** and **Node.js** installed on your workstation before proceeding.

1. **Clone the repository:**
   ```bash
   git clone https://github.com/sumit11006/MediSync.git
   cd MediSync
   ```

2. **Install Flutter Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Install Backend Dependencies:**
   ```bash
   cd drugbee_backend
   npm install
   cd ..
   ```

4. **Configure Environment:**
   Ensure your root `.env` file is filled with valid API keys and upload presets.

---

## ▶️ Running the Application

### 1. Launch the Backend Server
Navigate to the backend folder and start the Node.js server (defaults to port `3000` or the environment's `PORT` variable):
```bash
cd drugbee_backend
node index.js
```

### 2. Run the Flutter Application
Open a separate terminal window at the project root and launch the client:
```bash
flutter run
```

---

## 💡 Notes & Maintenance

* The system leverages Cloudinary for handling media uploads and Firestore for persistent document management.
* WhatsApp-based OTP services manage user registration and PIN recovery loops.
* If any external provider key is rotated, update your local `.env` configuration file immediately and trigger a fresh client build.
