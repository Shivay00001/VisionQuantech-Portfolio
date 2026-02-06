# 🎓 EdTech Platform - Production-Grade Learning Management System

A complete, production-ready EdTech platform built with Flutter and Firebase. Single codebase for Web and Android with enterprise-level architecture.

![Platform](https://img.shields.io/badge/Platform-Web%20%7C%20Android-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-02569B?logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Free%20Tier-orange?logo=firebase)
![License](https://img.shields.io/badge/License-MIT-green)

---

## ✨ Features

### 🔐 Authentication System
- Email/Password authentication
- Persistent login sessions
- Password reset functionality
- Protected routes with AuthGuard

### 📚 Course Management
- Browse all available courses
- Advanced search and filtering
- Course enrollment system
- My Courses dashboard
- Course progress tracking

### 🎬 Video Learning
- Custom YouTube player integration
- Locked lessons for non-enrolled users
- Seamless video streaming
- Next lesson recommendations
- Progress persistence

### 🎨 Modern UI/UX
- Dark mode with neon accents
- Glassmorphism design
- Smooth animations
- Responsive layout (mobile + desktop)
- Loading states and error handling

### 🔒 Security
- Firestore security rules
- Enrollment-based access control
- Protected video IDs
- User data privacy

---

## 🏗️ Architecture

### Project Structure
```
edtech_platform/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── app.dart                  # Root widget & routing
│   ├── firebase_options.dart     # Firebase configuration
│   │
│   ├── theme/
│   │   └── theme.dart           # App theme & colors
│   │
│   ├── services/
│   │   ├── auth_service.dart    # Authentication logic
│   │   ├── firestore_service.dart  # Database operations
│   │   └── purchase_service.dart   # Enrollment logic
│   │
│   ├── models/
│   │   ├── course.dart          # Course data model
│   │   └── lesson.dart          # Lesson data model
│   │
│   ├── modules/
│   │   ├── auth/                # Authentication pages
│   │   ├── home/                # Dashboard
│   │   ├── courses/             # Course browsing & details
│   │   ├── lessons/             # Video player
│   │   └── profile/             # User profile
│   │
│   └── widgets/                 # Reusable components
│
├── scripts/
│   └── seed_database.dart       # Database seeder
│
├── firestore.rules              # Firestore security
├── storage.rules                # Storage security
└── pubspec.yaml                 # Dependencies
```

### Technology Stack

**Frontend**
- Flutter 3.0+ (Web + Android)
- Provider (State Management)
- YouTube Player IFrame
- Cached Network Image

**Backend**
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Firebase Hosting

**Design**
- Material Design 3
- Custom dark theme
- Glassmorphism effects
- Responsive layouts

---

## 🚀 Quick Start

### Prerequisites
```bash
flutter --version  # 3.0 or higher
dart --version     # 3.0 or higher
```

### Installation

1. **Clone & Install**
```bash
git clone <your-repo>
cd edtech_platform
flutter pub get
```

2. **Configure Firebase**
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure project
flutterfire configure
```

3. **Setup Firebase Console**
- Enable Email/Password authentication
- Create Firestore database
- Deploy security rules (from firestore.rules)

4. **Seed Database**
```bash
# Update YouTube video IDs in scripts/seed_database.dart
dart scripts/seed_database.dart
```

5. **Run**
```bash
# Web
flutter run -d chrome

# Android
flutter run
```

---

## 📱 Build for Production

### Android APK
```bash
# Generate keystore
keytool -genkey -v -keystore android/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Configure key.properties (see android/key.properties.example)

# Build
flutter build apk --release
```

### Web Deployment
```bash
# Build
flutter build web --release

# Deploy to Firebase Hosting
firebase init hosting
firebase deploy --only hosting
```

---

## 🔒 Security Architecture

### Firestore Rules
- ✅ Users can only access their own data
- ✅ Lessons locked until course enrollment
- ✅ Video IDs hidden for non-enrolled users
- ✅ Purchase records protected per user

### Access Control Flow
```
User Request → Firebase Auth Check → Enrollment Verification → Grant/Deny Access
```

---

## 📊 Database Schema

### Collections

**users**
```json
{
  "uid": "string",
  "email": "string",
  "displayName": "string",
  "enrolledCourses": ["courseId1", "courseId2"],
  "createdAt": "timestamp"
}
```

**courses**
```json
{
  "id": "auto",
  "title": "string",
  "description": "string",
  "thumbUrl": "string",
  "level": "Beginner|Intermediate|Advanced",
  "price": 0.0,
  "totalLessons": 5,
  "createdAt": "timestamp"
}
```

**lessons**
```json
{
  "id": "auto",
  "courseId": "string",
  "title": "string",
  "ytId": "string",  // Hidden if not enrolled
  "order": 1,
  "duration": 900
}
```

**purchases**
```json
{
  "id": "auto",
  "userId": "string",
  "courseId": "string",
  "paymentStatus": "completed",
  "enrolledAt": "timestamp"
}
```

---

## 🎨 Customization

### Theme Colors
Edit `lib/theme/theme.dart`:
```dart
static const primaryNeon = Color(0xFF00F5FF);
static const secondaryNeon = Color(0xFFFF00FF);
static const accentNeon = Color(0xFF39FF14);
```

### App Name
Edit `pubspec.yaml`:
```yaml
name: your_app_name
```

### Package ID
Edit `android/app/build.gradle`:
```gradle
applicationId "com.yourcompany.yourapp"
```

---

## 🐛 Common Issues

### Firebase Connection Error
```bash
# Re-run configuration
flutterfire configure
```

### Video Not Playing
- Verify YouTube video is UNLISTED
- Check video ID is correct
- Ensure user is enrolled

### Build Errors
```bash
flutter clean
flutter pub get
flutter build <platform>
```

---

## 📈 Performance Optimization

- ✅ Cached network images
- ✅ Lazy loading lists
- ✅ Optimized Firebase queries
- ✅ Minified production builds
- ✅ Tree-shaking enabled

---

## 🔄 Future Enhancements

- [ ] Payment gateway integration
- [ ] Course certificates
- [ ] Progress tracking analytics
- [ ] Discussion forums
- [ ] Push notifications
- [ ] Offline video downloads
- [ ] Admin dashboard
- [ ] Quiz system

---

## 🤝 Contributing

Contributions welcome! Please follow:
1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Open pull request

---

## 📄 License

MIT License - feel free to use for commercial projects

---

## 👨‍💻 Author

Built with ❤️ using Flutter & Firebase

---

## 📞 Support

For issues or questions:
- Check [SETUP_GUIDE.md](./SETUP_GUIDE.md)
- Review Firebase Console logs
- Check Flutter error messages

---

**⚡ Ready to deploy? Follow [SETUP_GUIDE.md](./SETUP_GUIDE.md) for complete instructions!**