# 🚀 EdTech Platform - Complete Setup Guide

## 📋 Prerequisites

- Flutter SDK 3.0+ installed
- Firebase account (free tier)
- Android Studio or VS Code
- Git installed

---

## 🔥 STEP 1: Firebase Setup

### 1.1 Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **Add Project**
3. Enter project name: `edtech-platform`
4. Disable Google Analytics (optional for free tier)
5. Click **Create Project**

### 1.2 Enable Firebase Authentication

1. In Firebase Console, go to **Authentication**
2. Click **Get Started**
3. Enable **Email/Password** sign-in method
4. Save

### 1.3 Create Firestore Database

1. Go to **Firestore Database**
2. Click **Create Database**
3. Select **Start in production mode**
4. Choose a location (closest to your users)
5. Click **Enable**

### 1.4 Setup Firebase Storage

1. Go to **Storage**
2. Click **Get Started**
3. Select **Start in production mode**
4. Use same location as Firestore
5. Click **Done**

### 1.5 Register Your Apps

#### For Web:
1. Click **Project Settings** (gear icon)
2. Click **Add app** → Web
3. Register app nickname: `EdTech Web`
4. Check **Firebase Hosting**
5. Copy the config values

#### For Android:
1. Click **Add app** → Android
2. Package name: `com.example.edtech_platform`
3. Download `google-services.json`
4. Place it in `android/app/` directory

---

## 📦 STEP 2: Project Setup

### 2.1 Clone/Create Project Structure

```bash
# Create Flutter project
flutter create edtech_platform
cd edtech_platform

# Create necessary directories
mkdir -p lib/services
mkdir -p lib/modules/auth
mkdir -p lib/modules/home
mkdir -p lib/modules/courses
mkdir -p lib/modules/lessons
mkdir -p lib/modules/profile
mkdir -p lib/widgets
mkdir -p lib/theme
mkdir -p lib/models
mkdir -p scripts
mkdir -p assets/images
mkdir -p assets/icons
```

### 2.2 Copy All Code Files

Copy each artifact code to corresponding files:

```
edtech_platform/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── firebase_options.dart
│   ├── theme/
│   │   └── theme.dart
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── firestore_service.dart
│   │   └── purchase_service.dart
│   ├── models/
│   │   ├── course.dart
│   │   └── lesson.dart
│   ├── modules/
│   │   ├── auth/
│   │   │   ├── login_page.dart
│   │   │   ├── signup_page.dart
│   │   │   └── forgot_password_page.dart
│   │   ├── home/
│   │   │   └── home_page.dart
│   │   ├── courses/
│   │   │   ├── course_list_page.dart
│   │   │   ├── course_detail_page.dart
│   │   │   └── my_courses_page.dart
│   │   ├── lessons/
│   │   │   └── lesson_player_page.dart
│   │   └── profile/
│   │       └── profile_page.dart
│   └── widgets/
│       └── (all widget files)
├── scripts/
│   └── seed_database.dart
├── android/
│   ├── app/
│   │   ├── build.gradle
│   │   └── google-services.json
│   └── key.properties.example
├── firestore.rules
├── storage.rules
└── pubspec.yaml
```

### 2.3 Configure Firebase

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase (auto-generates firebase_options.dart)
flutterfire configure
```

Follow prompts to select your Firebase project.

---

## 🔐 STEP 3: Security Rules

### 3.1 Deploy Firestore Rules

1. Go to Firebase Console → **Firestore Database** → **Rules**
2. Copy content from `firestore.rules` artifact
3. Click **Publish**

### 3.2 Deploy Storage Rules

1. Go to Firebase Console → **Storage** → **Rules**
2. Copy content from `storage.rules` artifact
3. Click **Publish**

---

## 📊 STEP 4: Seed Database

### 4.1 Prepare YouTube Videos

1. Upload your course videos to YouTube as **UNLISTED**
2. Get video IDs from URLs (e.g., `dQw4w9WgXcQ` from `youtube.com/watch?v=dQw4w9WgXcQ`)
3. Keep a list of all video IDs

### 4.2 Update Seeder Script

Open `scripts/seed_database.dart` and replace:
- `YOUTUBE_VIDEO_ID_1` → Your actual video ID
- `YOUTUBE_VIDEO_ID_2` → Your actual video ID
- etc.

### 4.3 Run Seeder

```bash
# Install dependencies first
flutter pub get

# Run seeder
dart scripts/seed_database.dart
```

Verify in Firebase Console → Firestore Database that courses and lessons are created.

---

## 🚀 STEP 5: Run Development

### 5.1 Install Dependencies

```bash
flutter pub get
```

### 5.2 Run on Web

```bash
flutter run -d chrome
```

### 5.3 Run on Android

```bash
# Connect Android device or start emulator
flutter run
```

---

## 📱 STEP 6: Build for Production

### 6.1 Android APK

#### Generate Keystore

```bash
cd android
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Follow prompts and remember passwords.

#### Create key.properties

```bash
# Copy example
cp key.properties.example key.properties

# Edit with your passwords
nano key.properties
```

#### Build APK

```bash
cd ..
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

#### Build App Bundle (for Play Store)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

---

## 🌐 STEP 7: Deploy Web

### 7.1 Build Web

```bash
flutter build web --release
```

### 7.2 Initialize Firebase Hosting

```bash
firebase login
firebase init hosting
```

Configuration:
- Public directory: `build/web`
- Single-page app: **Yes**
- Overwrite index.html: **No**

### 7.3 Deploy

```bash
firebase deploy --only hosting
```

Your app will be live at: `https://YOUR_PROJECT_ID.web.app`

---

## 🔧 STEP 8: Post-Deployment

### 8.1 Test Authentication

1. Open app
2. Click **Sign Up**
3. Create test account
4. Verify in Firebase Console → Authentication

### 8.2 Test Enrollment

1. Login with test account
2. Go to **Explore Courses**
3. Select a course
4. Click **Enroll Now**
5. Verify in Firestore → purchases collection

### 8.3 Test Video Player

1. Go to **My Courses**
2. Open enrolled course
3. Click on a lesson
4. Verify video plays correctly
5. Check that locked lessons show lock icon

---

## 🎯 Production Checklist

- [ ] All YouTube video IDs replaced in seeder
- [ ] Firebase security rules deployed
- [ ] Test user signup/login works
- [ ] Test course enrollment works
- [ ] Test video player works on enrolled lessons
- [ ] Test locked lessons are blocked for non-enrolled users
- [ ] Web app deployed to Firebase Hosting
- [ ] Android APK/AAB built successfully
- [ ] Test on multiple devices
- [ ] Analytics enabled (optional)
- [ ] Error monitoring setup (optional)

---

## 🐛 Troubleshooting

### Firebase Connection Issues
```bash
# Re-run FlutterFire config
flutterfire configure

# Check google-services.json is in android/app/
```

### Build Errors
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build apk --release
```

### Video Player Issues
- Verify YouTube video IDs are correct
- Ensure videos are UNLISTED (not private)
- Check internet connection
- Verify enrollment status in Firestore

### Security Rules Errors
- Check user is authenticated
- Verify purchase record exists in Firestore
- Check security rules are published
- Look at Firestore console → Rules tab for errors

---

## 📚 Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)

---

## 🎉 Congratulations!

Your production-grade EdTech platform is now live! 🚀

For support or questions, check Firebase Console logs or Flutter error messages.