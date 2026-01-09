# Google Sign-In Troubleshooting Guide

## Common Issues and Solutions

### 1. Network Connectivity Issues
If you're experiencing network issues (as shown in the Gradle build failure), this can affect Google Sign-In:

**Solution:**
- Check your internet connection
- Try using a VPN if you're in a region with restricted access to Google services
- Wait and retry later if it's a temporary network issue

### 2. Missing SHA-1 Fingerprint Configuration

This is the most common cause of Google Sign-In failures.

**To get your SHA-1 fingerprint:**

#### Method 1: Using Gradle (when network is working)
```bash
cd android
./gradlew signingReport
```

#### Method 2: Using keytool directly
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

#### Method 3: Using Android Studio
1. Open Android Studio
2. Open your project
3. Click on Gradle panel (right side)
4. Navigate to: `android > Tasks > android > signingReport`
5. Double-click to run

**Copy the SHA-1 fingerprint and add it to Firebase:**

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Go to Project Settings (gear icon)
4. Select your Android app
5. Add the SHA-1 fingerprint
6. Download the updated `google-services.json`
7. Replace the existing file in `android/app/google-services.json`

### 3. Firebase Configuration Issues

**Check Firebase Console:**
1. Ensure Google Sign-In is enabled in Authentication > Sign-in method
2. Verify your Android app is properly configured
3. Make sure the package name matches: `com.example.griffiniti`

### 4. Testing Google Sign-In

**Debug Steps:**
1. Run the app with better error logging (already implemented)
2. Check the console output for specific error messages
3. Common error codes:
   - `SIGN_IN_FAILED`: Usually SHA-1 fingerprint issue
   - `NETWORK_ERROR`: Internet connectivity issue
   - `SIGN_IN_CANCELLED`: User cancelled the sign-in

### 5. Alternative Testing Method

If Google Sign-In continues to fail, you can test the anonymous login first:

1. Click "Continue as Guest" button
2. This should work without any additional configuration
3. If anonymous login works, the issue is specifically with Google Sign-In configuration

### 6. Production Considerations

For production builds, you'll need:
1. Release SHA-1 fingerprint (different from debug)
2. Proper signing configuration
3. Updated `google-services.json` with production SHA-1

## Quick Fix Checklist

- [ ] Internet connection is working
- [ ] Firebase project is set up correctly
- [ ] Google Sign-In is enabled in Firebase Authentication
- [ ] SHA-1 fingerprint is added to Firebase
- [ ] `google-services.json` is up to date
- [ ] Package name matches in Firebase and `android/app/build.gradle.kts`
- [ ] Google Play Services are available on the test device

## Testing Commands

Once network issues are resolved, test with:

```bash
# Get dependencies
flutter pub get

# Clean and rebuild
flutter clean
flutter pub get

# Run the app
flutter run
```

## Error Messages to Look For

When testing, check the console for these specific messages:
- "Google Sign-In Error: [specific error]"
- "Firebase Auth Error: [error code] - [message]"

The error messages will help identify the exact issue.