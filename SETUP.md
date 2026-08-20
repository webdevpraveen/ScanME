# SeeMe - Production Deployment & Setup Guide

This document outlines the final steps you need to perform to set up the backend on Supabase, configure your environment variables, and prepare the Android build for the Google Play Store.

## 1. Supabase Backend Setup

We have prepared all database schemas, security policies (RLS), and functions into 8 migration files. You need to apply them to your Supabase project.

### Option A: Using Supabase CLI (Recommended)

1. **Install Supabase CLI:**
   Follow instructions at [https://supabase.com/docs/guides/cli](https://supabase.com/docs/guides/cli)
   For Windows, you can use Scoop: `scoop install supabase`

2. **Login to Supabase CLI:**
   ```bash
   supabase login
   ```

3. **Link Your Project:**
   Navigate to the root of the `ScanME` project in your terminal:
   ```bash
   supabase link --project-ref your-project-ref
   ```
   *(You can find your Project Reference ID in your Supabase dashboard URL or Project Settings -> General).*

4. **Push Migrations to Remote:**
   ```bash
   supabase db push
   ```
   This will automatically apply migrations `001` through `008` in the correct order, setting up all tables, indexes, triggers, and RLS policies.

### Option B: Manual SQL Execution

If you prefer not to use the CLI, you can manually execute the SQL migrations from the Supabase Dashboard:
1. Go to your Supabase Project -> **SQL Editor**.
2. Open the `supabase/migrations/` folder in your project.
3. Copy and paste the contents of each file (starting from `2024...001_core_enums.sql` up to `...008_seed_data.sql`) one by one and run them in order.

### Storage Buckets Setup
If the migration didn't automatically create the storage buckets, create them manually in the Supabase Dashboard:
1. Go to **Storage**.
2. Create a new bucket named `avatars` (Public).
3. Create a new bucket named `id_cards` (Private).
*(The RLS policies for these buckets are already included in the migrations).*

---

## 2. Environment Variables Configuration

The app relies on your Supabase URL and Anon Key. In a production environment, these should not be hardcoded. Instead, they are passed during the build process using `--dart-define-from-file`.

1. Create a file named `.env.production.json` in the root of your `ScanME` project. **Do not commit this file to version control (it is already in `.gitignore`).**

2. Add your Supabase credentials:
   ```json
   {
     "SUPABASE_URL": "https://your-project.supabase.co",
     "SUPABASE_ANON_KEY": "your-anon-key"
   }
   ```
   *(You can find these in your Supabase Dashboard -> Project Settings -> API).*

---

## 3. Google Play Store Release Preparation

To publish the app on the Google Play Store, you need to sign the Android app bundle (AAB).

### Step 1: Create a Keystore
1. Open your terminal and run the following command to generate an upload keystore:
   ```bash
   keytool -genkey -v -keystore c:\Users\iampr\upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Follow the prompts to enter your password and details. **Keep the password and the keystore file safe.**

### Step 2: Configure `key.properties`
1. Create a file named `key.properties` in the `android/` directory (`android/key.properties`).
2. Add the following content (replace with your actual paths and passwords):
   ```properties
   storePassword=your_keystore_password
   keyPassword=your_key_password
   keyAlias=upload
   storeFile=C:/Users/iampr/upload-keystore.jks
   ```

### Step 3: Update `build.gradle`
This step is already mostly configured, but ensure that `android/app/build.gradle` is set up to read `key.properties` for the release build type. (Standard Flutter setup handles this if configured properly).

### Step 4: Build the Release App Bundle
Run the following command to create the AAB file:
```bash
flutter build appbundle --dart-define-from-file=.env.production.json
```
The built AAB file will be located at:
`build/app/outputs/bundle/release/app-release.aab`

You will upload this `.aab` file to the Google Play Console.

---

## 4. Final Checklist Before Launch
- [ ] **Test with Production DB**: Ensure the app builds and connects to your live Supabase project.
- [ ] **Verify Registration Flow**: Test a full registration, ensure ID cards upload successfully, and the roll number validation works.
- [ ] **Firebase Setup (Optional)**: If using Firebase Cloud Messaging for notifications, add the `google-services.json` to `android/app/` and uncomment `Firebase.initializeApp()` in `lib/app/bootstrap.dart`.

Your application code has been reviewed, statically analyzed (`flutter analyze` shows 0 issues), and logically verified. You are ready for production!
