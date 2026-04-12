# Nesta — MedCare Mobile User Portal

A Flutter mobile application that connects patients with doctors, supports care for babies and elderly patients, and provides a full medical management experience. Built with Material 3 design, bilingual support (English / Arabic), and Supabase as the backend.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Tech Stack & Dependencies](#tech-stack--dependencies)
- [Authentication & Security](#authentication--security)
- [Screens & Navigation](#screens--navigation)
- [Localization](#localization)
- [Theme & Design System](#theme--design-system)
- [Setup & Running](#setup--running)
- [Android Configuration](#android-configuration)
- [iOS Configuration](#ios-configuration)

---

## Overview

**App name:** Nesta  
**Package:** `com.example.mobile_user_portal`  
**Version:** 1.0.0+1  
**Flutter SDK:** ^3.5.0  
**Backend:** Supabase  

Nesta is a healthcare companion app that allows users to:
- Manage their personal health profile
- Track and monitor babies (vitals, growth, vaccinations, routines, medicines, alerts)
- Track and monitor elderly patients (vitals, medications, health records, safety, alerts)
- Book and manage appointments with doctors
- Chat with doctors
- Browse and purchase from a medical shop
- Authenticate securely with email/password or biometrics (fingerprint / Face ID)

---

## Features

### Authentication
- Email & password sign-in and registration
- Biometric login (fingerprint / Face ID) — enabled and managed from the home screen
- Biometric app lock — if biometrics are enabled, a scan is required every time the app is opened
- Secure credential storage via `flutter_secure_storage` (AES-encrypted, Android Keystore)
- Supabase session persistence with automatic refresh token management

### Dashboard / Home
- Personalised greeting with user initials avatar
- Quick-access stat cards: babies count, elders count, upcoming appointments
- Upcoming appointments list with date, doctor, and status
- Pull-to-refresh
- Language toggle (EN / AR) in AppBar
- Biometric toggle button in AppBar (enable / disable biometric lock)

### Baby Management
- List all registered babies
- Add a new baby profile
- Baby detail screen
- Growth tracking with charts
- Vaccination schedule
- Daily routine management
- Medicine records
- Health alerts
- Live monitoring screen (heart rate chart, SpO2, temperature, live camera feed, safety alerts)

### Elder Management
- List all registered elders
- Add a new elder profile
- Elder detail screen
- Vitals history with charts
- Medication management
- Health records
- Safety information
- Health alerts
- Live monitoring screen (real-time HR chart, vital mini cards, live trend display)

### Appointments
- View upcoming and past appointments
- Add new appointments with doctor selection and date/time

### Chat
- Conversations list with all doctors
- Individual chat screen per doctor conversation

### Shop
- Medical product browsing
- Shopping cart

### Doctors
- Browse available doctors list

---

## Architecture

```
lib/
├── main.dart                        # App entry point, Supabase init, ProviderScope
├── core/
│   ├── router/
│   │   └── app_router.dart          # GoRouter config, auth redirect guards
│   ├── theme/
│   │   └── app_theme.dart           # Material 3 theme, color palette, text styles
│   ├── localization/
│   │   ├── app_localizations.dart   # Bilingual string definitions (EN/AR)
│   │   └── locale_provider.dart     # Riverpod locale state provider
│   ├── services/
│   │   └── biometric_service.dart   # local_auth + secure_storage biometric layer
│   └── supabase/
│       └── supabase_config.dart     # Supabase URL and anon key
├── features/
│   ├── auth/
│   │   ├── models/profile_model.dart
│   │   ├── providers/auth_provider.dart
│   │   └── screens/
│   │       ├── splash_screen.dart   # Startup routing + biometric gate
│   │       ├── login_screen.dart
│   │       └── register_screen.dart
│   ├── dashboard/
│   │   └── screens/
│   │       ├── home_screen.dart
│   │       └── main_shell.dart      # Bottom nav shell + BiometricToggleButton + LangToggleButton
│   ├── baby/
│   │   ├── models/baby_model.dart
│   │   ├── providers/baby_provider.dart
│   │   └── screens/ (8 screens)
│   ├── elder/
│   │   ├── models/elder_model.dart
│   │   ├── providers/elder_provider.dart
│   │   └── screens/ (9 screens)
│   ├── appointments/
│   │   ├── models/appointment_model.dart
│   │   ├── providers/appointments_provider.dart
│   │   └── screens/ (2 screens)
│   ├── chat/
│   │   ├── models/chat_model.dart
│   │   ├── providers/chat_provider.dart
│   │   └── screens/ (2 screens)
│   ├── shop/
│   │   ├── models/product_model.dart
│   │   ├── providers/shop_provider.dart
│   │   └── screens/ (2 screens)
│   └── doctor/
│       ├── providers/doctor_provider.dart
│       └── screens/ (1 screen)
└── shared/
    └── widgets/
        ├── app_card.dart
        ├── stat_card.dart
        ├── loading_widget.dart
        ├── empty_state_widget.dart
        ├── error_widget.dart
        └── patient_card.dart
```

**State management:** Riverpod (`flutter_riverpod ^2.5.1`)  
**Navigation:** GoRouter (`go_router ^14.2.0`) with auth redirect guards  
**Pattern:** Feature-first folder structure with models / providers / screens per feature  

---

## Tech Stack & Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter` | SDK | UI framework |
| `flutter_localizations` | SDK | RTL + i18n support |
| `supabase_flutter` | ^2.5.0 | Auth, database, realtime |
| `flutter_riverpod` | ^2.5.1 | State management |
| `go_router` | ^14.2.0 | Declarative navigation |
| `fl_chart` | ^0.68.0 | Vitals / HR charts |
| `intl` | 0.20.2 | Date formatting, RTL |
| `timeago` | ^3.6.0 | Relative timestamps in chat |
| `local_auth` | ^2.3.0 | Fingerprint / Face ID authentication |
| `flutter_secure_storage` | ^9.2.2 | Encrypted credential / token storage |
| `flutter_lints` | ^4.0.0 | (dev) Lint rules |
| `flutter_launcher_icons` | ^0.14.1 | (dev) App icon generation |

---

## Authentication & Security

### Login Flow
1. User enters email + password → Supabase `signInWithPassword`
2. On success → navigate to `/home`

### Biometric Setup (Home Screen)
Biometrics are **enabled from the home screen** (fingerprint icon in AppBar):
1. Tap fingerprint icon → biometric scan prompt appears immediately
2. On success → current Supabase session's refresh token is saved to encrypted storage
3. Tap again when enabled → confirmation dialog → disable (clears stored credentials)

### App Lock (Biometric Gate on Startup)
Every time the app is opened:
- Session active + biometrics enabled → biometric scan required before entering the app
- Scan passes → go to home
- Scan fails / cancelled → go to login screen
- Session active + biometrics not enabled → go directly to home
- No session → go to login

### Biometric Login (Login Screen)
- If biometrics were previously enabled, a "Sign in with Biometric" button appears on the login screen
- Triggers fingerprint / Face ID → restores session via stored refresh token

### Credential Storage Keys
All stored with `flutter_secure_storage` using `AndroidOptions(encryptedSharedPreferences: true)`:

| Key | Content |
|---|---|
| `nesta_biometric_refresh_token` | Supabase refresh token (set from home screen) |
| `nesta_biometric_email` | User email (legacy) |
| `nesta_biometric_password` | User password (legacy) |

---

## Screens & Navigation

```
/splash              → SplashScreen (biometric gate on startup)
/login               → LoginScreen
/register            → RegisterScreen
/home                → HomeScreen          (inside MainShell — bottom nav)
/appointments        → AppointmentsScreen  (inside MainShell)
/appointments/add    → AddAppointmentScreen
/chat                → ConversationsScreen (inside MainShell)
/chat/:id            → ChatScreen
/shop                → ShopScreen          (inside MainShell)
/shop/cart           → CartScreen
/doctors             → DoctorsListScreen
/babies              → BabiesListScreen
/babies/add          → AddBabyScreen
/babies/:id          → BabyDetailScreen
/babies/:id/growth
/babies/:id/vaccinations
/babies/:id/routine
/babies/:id/medicines
/babies/:id/alerts
/babies/:id/monitoring
/elders              → EldersListScreen
/elders/add          → AddElderScreen
/elders/:id          → ElderDetailScreen
/elders/:id/vitals
/elders/:id/medications
/elders/:id/health-records
/elders/:id/alerts
/elders/:id/safety
/elders/:id/monitoring
```

**Router guards (in `app_router.dart`):**
- Unauthenticated user on a protected route → redirect to `/login`
- Authenticated user on `/login` or `/register` → redirect to `/home`
- `/splash` is exempt from redirect (handles its own routing logic)

---

## Localization

The app is fully bilingual: **English** and **Arabic** (RTL).

- All strings are defined in `lib/core/localization/app_localizations.dart` using a `_t(en, ar)` helper
- Language can be toggled at runtime via the `LangToggleButton` in the home screen AppBar
- Current locale is managed with a Riverpod `localeProvider`
- Flutter's `GlobalMaterialLocalizations`, `GlobalWidgetsLocalizations`, and `GlobalCupertinoLocalizations` delegates handle RTL layout direction automatically

---

## Theme & Design System

Material 3 (`useMaterial3: true`) with a custom color palette defined in `AppTheme`:

| Token | Hex | Usage |
|---|---|---|
| `primary` | `#2563EB` | Buttons, active nav, icons |
| `babyAccent` | `#F472B6` | Baby module accent color |
| `elderAccent` | `#6366F1` | Elder module accent color |
| `healthGreen` | `#10B981` | Success states, healthy status |
| `error` | `#EF4444` | Errors, critical alerts |
| `warning` | `#F59E0B` | Warnings, elevated readings |
| `background` | `#F1F5F9` | Scaffold background |
| `surface` | `#FFFFFF` | Cards, inputs, bottom nav |
| `border` | `#E2E8F0` | Dividers, input borders |
| `textPrimary` | `#0F172A` | Headings, body text |
| `textSecondary` | `#475569` | Subtitles, labels |
| `textLight` | `#94A3B8` | Placeholders, disabled text |

---

## Setup & Running

### Prerequisites
- Flutter SDK 3.5.0+
- Android Studio / Xcode
- A physical device or emulator with biometric hardware enrolled (for biometric features)

### Install & Run

```bash
# Install dependencies
flutter pub get

# Generate launcher icons
dart run flutter_launcher_icons

# Run on connected device / emulator
flutter run
```

### Clean Build

Always run a clean build after any native Android/iOS changes:

```bash
flutter clean && flutter run
```

---

## Android Configuration

### `MainActivity.kt`
```kotlin
// Must extend FlutterFragmentActivity (not FlutterActivity) for local_auth
class MainActivity : FlutterFragmentActivity()
```

### `build.gradle.kts`
```kotlin
minSdk = 23   // local_auth requires Android 6.0+
```

### `AndroidManifest.xml`
```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.USE_FINGERPRINT"/>
```

### `res/values/styles.xml` and `res/values-night/styles.xml`
```xml
<!-- AppCompat-based theme required by FlutterFragmentActivity -->
<style name="LaunchTheme" parent="@style/Theme.AppCompat.Light.NoActionBar">
<style name="NormalTheme" parent="@style/Theme.AppCompat.Light.NoActionBar">
```
Night variant uses `@style/Theme.AppCompat.NoActionBar`.

---

## iOS Configuration

### `Info.plist`
```xml
<!-- Required for Face ID usage -->
<key>NSFaceIDUsageDescription</key>
<string>Use Face ID to sign in to Nesta quickly and securely.</string>
```

This key is mandatory on Face ID-capable devices. Without it the app will crash when biometric authentication is triggered.
