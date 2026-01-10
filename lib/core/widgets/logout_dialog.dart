import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/toast_helper.dart';

class LogoutDialog extends StatefulWidget {
  const LogoutDialog({super.key});

  @override
  State<LogoutDialog> createState() => _LogoutDialogState();
}

class _LogoutDialogState extends State<LogoutDialog> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  String get _authProviderText {
    switch (_authService.currentAuthProvider) {
      case 'google':
        return 'Google account';
      case 'email':
        return 'email account';
      case 'anonymous':
        return 'guest session';
      default:
        return 'account';
    }
  }

  IconData get _authProviderIcon {
    switch (_authService.currentAuthProvider) {
      case 'google':
        return Icons.account_circle;
      case 'email':
        return Icons.email;
      case 'anonymous':
        return Icons.person_outline;
      default:
        return Icons.account_circle;
    }
  }

  Color get _authProviderColor {
    switch (_authService.currentAuthProvider) {
      case 'google':
        return Colors.red;
      case 'email':
        return AppTheme.accentBlue;
      case 'anonymous':
        return AppTheme.accentOrange;
      default:
        return AppTheme.secondaryText;
    }
  }

  Future<void> _performLogout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.signOut();

      if (mounted) {
        Navigator.of(context).pop();
        ToastHelper.success(context, 'Successfully signed out');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ToastHelper.authError(context, 'Logout failed: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.secondaryBlack,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.logout, color: Colors.red, size: 24),
          const SizedBox(width: 12),
          Text(
            'Sign Out',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to sign out of your $_authProviderText?',
            style: TextStyle(color: AppTheme.secondaryText, fontSize: 16),
          ),
          const SizedBox(height: 16),

          // Current account info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accentGray,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _authProviderColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(_authProviderIcon, color: _authProviderColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _authService.currentUser?.displayName ?? 'User',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_authService.currentUser?.email != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          _authService.currentUser!.email!,
                          style: TextStyle(
                            color: AppTheme.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _authProviderColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _authService.currentAuthProvider.toUpperCase(),
                    style: TextStyle(
                      color: _authProviderColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_authService.isAnonymous) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.accentOrange.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: AppTheme.accentOrange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your progress will be lost if you sign out as a guest.',
                      style: TextStyle(
                        color: AppTheme.accentOrange,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: AppTheme.secondaryText, fontSize: 14),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _performLogout,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Sign Out',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
        ),
      ],
    );
  }
}
