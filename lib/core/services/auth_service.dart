import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await result.user?.updateDisplayName(displayName);

      // Create user document using helper method
      if (result.user != null) {
        await _createOrUpdateUserDocument(result.user!, isNewUser: true);
      }

      return result;
    } catch (e) {
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        // User is already signed out
        return;
      }

      // Check if user was signed in with Google
      bool wasGoogleSignIn = false;
      for (final providerData in user.providerData) {
        if (providerData.providerId == 'google.com') {
          wasGoogleSignIn = true;
          break;
        }
      }

      // Sign out from Google if user was signed in with Google
      if (wasGoogleSignIn) {
        try {
          await _googleSignIn.signOut();
        } catch (e) {
          // Google sign out failed, but continue with Firebase sign out
          print('Google sign out failed: $e');
        }
      }

      // Always sign out from Firebase (handles email/password, anonymous, and Google)
      await _auth.signOut();

      // Clear any cached Google sign-in data
      try {
        await _googleSignIn.disconnect();
      } catch (e) {
        // Disconnect failed, but that's okay
        print('Google disconnect failed: $e');
      }
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential result = await _auth.signInWithCredential(credential);

      // Create or update user document in Firestore
      if (result.user != null) {
        await _createOrUpdateUserDocument(
          result.user!,
          isNewUser: result.additionalUserInfo?.isNewUser ?? false,
        );
      }

      return result;
    } catch (e) {
      throw Exception('Google sign in failed: ${e.toString()}');
    }
  }

  // Sign in anonymously
  Future<UserCredential?> signInAnonymously() async {
    try {
      UserCredential result = await _auth.signInAnonymously();

      // Create user document for anonymous user
      if (result.user != null) {
        await _createOrUpdateUserDocument(
          result.user!,
          isNewUser: true,
          isAnonymous: true,
        );
      }

      return result;
    } catch (e) {
      throw Exception('Anonymous sign in failed: ${e.toString()}');
    }
  }

  // Convert anonymous account to permanent account
  Future<UserCredential?> linkAnonymousWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      if (_auth.currentUser == null || !_auth.currentUser!.isAnonymous) {
        throw Exception('No anonymous user to link');
      }

      // Create email/password credential
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      // Link the credential to the anonymous user
      UserCredential result = await _auth.currentUser!.linkWithCredential(
        credential,
      );

      // Update display name and user document
      await result.user?.updateDisplayName(displayName);
      await _updateUserDocumentAfterLink(result.user!, displayName, email);

      return result;
    } catch (e) {
      throw Exception('Account linking failed: ${e.toString()}');
    }
  }

  // Link anonymous account with Google
  Future<UserCredential?> linkAnonymousWithGoogle() async {
    try {
      if (_auth.currentUser == null || !_auth.currentUser!.isAnonymous) {
        throw Exception('No anonymous user to link');
      }

      // Get Google credentials
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Link the credential to the anonymous user
      UserCredential result = await _auth.currentUser!.linkWithCredential(
        credential,
      );

      // Update user document with Google info
      if (result.user != null) {
        await _updateUserDocumentAfterLink(
          result.user!,
          result.user!.displayName ?? 'User',
          result.user!.email ?? '',
        );
      }

      return result;
    } catch (e) {
      throw Exception('Google account linking failed: ${e.toString()}');
    }
  }

  // Helper method to create or update user document
  Future<void> _createOrUpdateUserDocument(
    User user, {
    required bool isNewUser,
    bool isAnonymous = false,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (isNewUser || !userDoc.exists) {
        // Create new user document
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email ?? '',
          'displayName':
              user.displayName ?? (isAnonymous ? 'Anonymous User' : 'User'),
          'bio': '',
          'location': '',
          'website': '',
          'profileImageUrl': user.photoURL ?? '',
          'graffitiCount': 0,
          'followersCount': 0,
          'followingCount': 0,
          'isAnonymous': isAnonymous,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing user document
        await _firestore.collection('users').doc(user.uid).update({
          'email': user.email ?? userDoc.data()?['email'] ?? '',
          'displayName':
              user.displayName ?? userDoc.data()?['displayName'] ?? 'User',
          'profileImageUrl':
              user.photoURL ?? userDoc.data()?['profileImageUrl'] ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to create/update user document: ${e.toString()}');
    }
  }

  // Helper method to update user document after linking
  Future<void> _updateUserDocumentAfterLink(
    User user,
    String displayName,
    String email,
  ) async {
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'email': email,
        'displayName': displayName,
        'profileImageUrl': user.photoURL ?? '',
        'isAnonymous': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception(
        'Failed to update user document after linking: ${e.toString()}',
      );
    }
  }

  // Check if current user is anonymous
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? false;

  // Get current authentication provider
  String get currentAuthProvider {
    final user = _auth.currentUser;
    if (user == null) return 'none';
    if (user.isAnonymous) return 'anonymous';

    for (final providerData in user.providerData) {
      switch (providerData.providerId) {
        case 'google.com':
          return 'google';
        case 'password':
          return 'email';
        default:
          continue;
      }
    }
    return 'unknown';
  }

  // Get sign-in methods for email
  Future<List<String>> getSignInMethodsForEmail(String email) async {
    try {
      return await _auth.fetchSignInMethodsForEmail(email);
    } catch (e) {
      throw Exception('Failed to get sign-in methods: ${e.toString()}');
    }
  }
}
