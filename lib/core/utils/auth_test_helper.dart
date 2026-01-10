import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthTestHelper {
  static Future<Map<String, dynamic>> testGoogleSignInConfiguration() async {
    final results = <String, dynamic>{};

    try {
      // Test 1: Check if GoogleSignIn can be initialized
      results['google_signin_init'] = await _testGoogleSignInInit();

      // Test 2: Check Firebase Auth
      results['firebase_auth'] = await _testFirebaseAuth();

      // Test 3: Check if we can get Google Sign-In client
      results['google_client'] = await _testGoogleClient();

      results['overall_status'] = 'completed';
    } catch (e) {
      results['error'] = e.toString();
      results['overall_status'] = 'failed';
    }

    return results;
  }

  static Future<Map<String, dynamic>> _testGoogleSignInInit() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      return {
        'status': 'success',
        'client_id': googleSignIn.clientId,
        'scopes': googleSignIn.scopes,
      };
    } catch (e) {
      return {'status': 'failed', 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> _testFirebaseAuth() async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final User? currentUser = auth.currentUser;

      return {
        'status': 'success',
        'current_user': currentUser?.uid,
        'app_name': auth.app.name,
      };
    } catch (e) {
      return {'status': 'failed', 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> _testGoogleClient() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // Try to sign in silently (won't show UI)
      final GoogleSignInAccount? account = await googleSignIn.signInSilently();

      return {
        'status': 'success',
        'silent_signin': account != null ? 'user_found' : 'no_user',
        'account_email': account?.email,
      };
    } catch (e) {
      return {'status': 'failed', 'error': e.toString()};
    }
  }

  static void printDebugInfo(Map<String, dynamic> results) {
    if (kDebugMode) {
      print('=== Google Sign-In Debug Results ===');
      results.forEach((key, value) {
        print('$key: $value');
      });
      print('=====================================');
    }
  }
}
