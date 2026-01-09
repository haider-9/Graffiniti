# Authentication Setup Guide

This document explains the authentication methods available in the Graffiniti app and how to configure them.

## Available Authentication Methods

### 1. Email/Password Authentication
- Traditional email and password sign-up and sign-in
- Password reset functionality
- User profile creation in Firestore

### 2. Google Sign-In
- One-tap Google authentication
- Automatic user profile creation
- Uses existing Google account information

### 3. Anonymous Authentication
- Guest access without registration
- Limited functionality for anonymous users
- Can be upgraded to full account later

## Configuration Requirements

### Google Sign-In Setup
1. **Firebase Console Configuration**:
   - Enable Google Sign-In in Firebase Authentication
   - Add your app's SHA-1 fingerprint
   - Download updated `google-services.json`

2. **Android Configuration**:
   - The `google-services.json` file is already in `android/app/`
   - Google Services plugin is configured in `android/app/build.gradle.kts`

3. **Dependencies**:
   - `google_sign_in: ^6.2.1` is added to `pubspec.yaml`
   - `firebase_auth: ^5.3.1` for Firebase authentication

### Anonymous Authentication
- No additional configuration required
- Enabled by default in Firebase Authentication

## User Data Structure

All authentication methods create a user document in Firestore with the following structure:

```dart
{
  'uid': String,
  'email': String,
  'displayName': String,
  'bio': String,
  'location': String,
  'website': String,
  'profileImageUrl': String,
  'graffitiCount': int,
  'followersCount': int,
  'followingCount': int,
  'isAnonymous': bool,
  'signInMethod': String, // 'email', 'google', or 'anonymous'
  'createdAt': Timestamp,
  'updatedAt': Timestamp,
  'lastSignInAt': Timestamp,
}
```

## Usage Examples

### Email/Password Sign-In
```dart
await _authService.signInWithEmailAndPassword(
  email: 'user@example.com',
  password: 'password123',
);
```

### Google Sign-In
```dart
final result = await _authService.signInWithGoogle();
if (result != null) {
  // User signed in successfully
}
```

### Anonymous Sign-In
```dart
await _authService.signInAnonymously();
```

### Sign Out
```dart
await _authService.signOut(); // Handles all sign-in methods
```

## UI Components

The login page (`lib/pages/auth/login_page.dart`) now includes:
- Email/password form
- Google Sign-In button with custom styling
- Anonymous/Guest sign-in button
- Proper loading states and error handling

## Security Considerations

1. **Anonymous Users**: Have limited access and should be prompted to create accounts for full features
2. **Google Sign-In**: Requires proper SHA-1 configuration for production
3. **Email Validation**: Built-in email format validation
4. **Password Requirements**: Minimum 6 characters (can be enhanced)

## Testing

To test the authentication methods:
1. Run `flutter pub get` to install new dependencies
2. Ensure Firebase is properly configured
3. Test each authentication method in the app
4. Verify user documents are created in Firestore

## Troubleshooting

### Google Sign-In Issues
- Verify SHA-1 fingerprint is added to Firebase
- Check `google-services.json` is up to date
- Ensure Google Sign-In is enabled in Firebase Console

### Anonymous Sign-In Issues
- Verify Anonymous authentication is enabled in Firebase Console
- Check Firebase rules allow anonymous users

### General Issues
- Ensure all Firebase dependencies are up to date
- Check internet connectivity
- Verify Firebase project configuration