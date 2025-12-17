import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../../pages/auth/login_page.dart';
import '../../main.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking authentication state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.primaryBlack,
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.accentOrange,
                ),
              ),
            ),
          );
        }

        // If user is logged in, show main navigation
        if (snapshot.hasData && snapshot.data != null) {
          return const MainNavigation();
        }

        // If user is not logged in, show login page
        return const LoginPage();
      },
    );
  }
}
