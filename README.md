# ScanME

Scan. Connect. Grow. - Verified Student Networking Platform

## Project Overview

ScanME is a robust, production-ready Flutter application designed specifically for educational institutions. The platform facilitates verified connections among students, enabling them to share professional profiles, highlight academic achievements, and build their network seamlessly through secure QR code scanning. 

Built with scalability, security, and performance in mind, ScanME leverages modern development practices and a serverless architecture to ensure a seamless user experience across all supported devices.

## Core Features

- **Verified Digital Identity**: End-to-end authentication and institutional verification system backed by Supabase.
- **Dynamic QR Code Integration**: Generate, render, and scan unique encrypted QR codes for instant profile sharing and network expansion.
- **Connection Management**: Track, organize, and manage professional connections with an intuitive interface.
- **Administrative Dashboard**: Comprehensive controls for user management, identity verification, and system analytics.
- **Responsive Architecture**: Built with Material 3 design principles, ensuring a consistent and premium user experience across diverse screen sizes and Android versions (API 21+).
- **Environment Driven**: Seamlessly switch between development and production environments using structured environment variables.

## Technical Stack

- **Framework**: Flutter 3.x
- **Language**: Dart 3.x
- **State Management**: Riverpod (with Code Generation)
- **Routing**: GoRouter for declarative, type-safe navigation
- **Backend & Database**: Supabase (PostgreSQL)
- **Authentication**: Supabase Auth (Email/Password, OAuth integrations)
- **Storage**: Supabase Storage (Profile media, Verification documents)
- **Local Database**: SQLite / Shared Preferences for caching and offline capabilities

## Project Structure

The codebase strictly adheres to feature-first architecture, ensuring high maintainability and modularity:

- `lib/core/`: Application-wide utilities, constants, themes, and network layers.
- `lib/features/`: Isolated business logic and UI for distinct domains:
  - `auth/`: Authentication workflows (Login, Registration, Password Recovery).
  - `home/`: Primary application shell and navigation controller.
  - `network/`: Connection state management and profile viewing logic.
  - `profile/`: User profile management and QR code generation.
  - `qr/`: Hardware integration for scanning QR codes.
  - `student_verification/`: Document submission and institutional verification.
  - `admin/`: Privileged administrator tools.
- `lib/shared/`: Reusable, domain-agnostic UI widgets, models, and services.
- `supabase/migrations/`: Version-controlled SQL schema definitions and RLS policies.

## Installation and Setup

### Prerequisites

1. **Flutter SDK**: Ensure the latest stable Flutter SDK is installed and configured in your PATH.
2. **Android Studio / VS Code**: Recommended IDEs with Flutter and Dart plugins enabled.
3. **Supabase CLI**: Required for local database development and migration execution.

### Local Development

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/webdevpraveen/ScanME.git
   cd ScanME
   ```

2. **Resolve Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Environments**:
   Create two files in the project root: `.env` (for local development) and `.env.production.json` (for production builds).
   
   Example `.env` format:
   ```env
   SUPABASE_URL=your_project_url
   SUPABASE_ANON_KEY=your_anon_key
   ```

4. **Initialize Backend (Supabase)**:
   Link your local environment to your remote Supabase project and apply all migrations to set up tables, functions, and RLS policies.
   ```bash
   supabase link --project-ref your-project-ref
   supabase db push
   ```

5. **Run the Application**:
   ```bash
   flutter run
   ```

## Build and Deployment

### Production Android Build

The application is configured to build highly optimized Android App Bundles (AAB) and APKs. Core library desugaring and Multidex are natively supported to ensure compatibility down to Android 5.0 (API 21).

To generate a production APK:
```bash
flutter build apk --release --dart-define-from-file=.env.production.json
```

To generate an App Bundle for Google Play Console:
```bash
flutter build appbundle --release --dart-define-from-file=.env.production.json
```

## Security and Permissions

The application requires specific permissions based on the environment build:
- `INTERNET`: Required for backend communication (explicitly defined for release builds).
- `CAMERA`: Required for QR code scanning functionalities.
- `READ_EXTERNAL_STORAGE`: Required for profile picture uploads on devices running older Android versions.

Row Level Security (RLS) is strictly enforced on the Supabase database to prevent unauthorized access or mutation of user data.

## Licensing

Proprietary Software. All rights reserved. 
Unauthorized copying, modification, or distribution of this software is strictly prohibited.
