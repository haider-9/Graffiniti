import 'package:flutter/material.dart';
import '../widgets/toast_notification.dart';

/// Helper class for showing toast notifications throughout the app
/// Provides convenient static methods for common toast scenarios
class ToastHelper {
  /// Show a success toast
  static void success(BuildContext context, String message) {
    ToastNotification.show(context, message: message, type: ToastType.success);
  }

  /// Show an error toast
  static void error(BuildContext context, String message) {
    ToastNotification.show(context, message: message, type: ToastType.error);
  }

  /// Show an info toast
  static void info(BuildContext context, String message) {
    ToastNotification.show(context, message: message, type: ToastType.info);
  }

  /// Show a warning toast
  static void warning(BuildContext context, String message) {
    ToastNotification.show(context, message: message, type: ToastType.warning);
  }

  /// Convert technical error to user-friendly message
  static String _getUserFriendlyError(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    // Network errors
    if (errorStr.contains('network') ||
        errorStr.contains('socket') ||
        errorStr.contains('connection')) {
      return 'No internet connection';
    }

    // Firebase errors
    if (errorStr.contains('permission-denied') ||
        errorStr.contains('permission denied')) {
      return 'Access denied. Please check your permissions';
    }

    if (errorStr.contains('not-found') || errorStr.contains('not found')) {
      return 'Data not found';
    }

    if (errorStr.contains('already-exists') ||
        errorStr.contains('already exists')) {
      return 'This item already exists';
    }

    if (errorStr.contains('invalid-email')) {
      return 'Invalid email address';
    }

    if (errorStr.contains('weak-password')) {
      return 'Password is too weak';
    }

    if (errorStr.contains('email-already-in-use')) {
      return 'This email is already registered';
    }

    if (errorStr.contains('user-not-found')) {
      return 'Account not found';
    }

    if (errorStr.contains('wrong-password')) {
      return 'Incorrect password';
    }

    if (errorStr.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later';
    }

    if (errorStr.contains('unavailable') || errorStr.contains('offline')) {
      return 'Service unavailable. Please try again';
    }

    if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
      return 'Request timed out. Please try again';
    }

    if (errorStr.contains('cancelled') || errorStr.contains('canceled')) {
      return 'Operation cancelled';
    }

    // Storage errors
    if (errorStr.contains('storage') && errorStr.contains('quota')) {
      return 'Storage limit reached';
    }

    if (errorStr.contains('file') && errorStr.contains('too large')) {
      return 'File is too large';
    }

    // Auth errors
    if (errorStr.contains('requires-recent-login')) {
      return 'Please log in again to continue';
    }

    if (errorStr.contains('user-disabled')) {
      return 'This account has been disabled';
    }

    // Default: clean up the error message
    String cleanMessage = error
        .toString()
        .replaceAll('Exception: ', '')
        .replaceAll('Failed to ', '')
        .replaceAll('Error: ', '')
        .replaceAll('[firebase_', '')
        .replaceAll(']', '')
        .trim();

    // Capitalize first letter
    if (cleanMessage.isNotEmpty) {
      cleanMessage = cleanMessage[0].toUpperCase() + cleanMessage.substring(1);
    }

    return cleanMessage.isEmpty ? 'Something went wrong' : cleanMessage;
  }

  /// Show a database error toast with user-friendly message
  static void databaseError(BuildContext context, dynamic error) {
    final message = _getUserFriendlyError(error);
    ToastNotification.show(context, message: message, type: ToastType.error);
  }

  /// Show a network error toast with user-friendly message
  static void networkError(BuildContext context, dynamic error) {
    final message = _getUserFriendlyError(error);
    ToastNotification.show(context, message: message, type: ToastType.error);
  }

  /// Show a generic error toast with user-friendly message
  static void genericError(BuildContext context, dynamic error) {
    final message = _getUserFriendlyError(error);
    ToastNotification.show(context, message: message, type: ToastType.error);
  }

  /// Show a save success toast
  static void saveSuccess(BuildContext context, {String? itemName}) {
    final message = itemName != null
        ? '$itemName saved successfully!'
        : 'Saved successfully!';
    ToastNotification.show(context, message: message, type: ToastType.success);
  }

  /// Show a delete success toast
  static void deleteSuccess(BuildContext context, {String? itemName}) {
    final message = itemName != null
        ? '$itemName deleted successfully!'
        : 'Deleted successfully!';
    ToastNotification.show(context, message: message, type: ToastType.success);
  }

  /// Show an update success toast
  static void updateSuccess(BuildContext context, {String? itemName}) {
    final message = itemName != null
        ? '$itemName updated successfully!'
        : 'Updated successfully!';
    ToastNotification.show(context, message: message, type: ToastType.success);
  }

  /// Show a loading error toast
  static void loadingError(BuildContext context, {String? itemName}) {
    final message = itemName != null
        ? 'Couldn\'t load $itemName'
        : 'Couldn\'t load data';
    ToastNotification.show(context, message: message, type: ToastType.error);
  }

  /// Show a permission denied toast
  static void permissionDenied(BuildContext context, String permission) {
    ToastNotification.show(
      context,
      message: 'Please allow $permission access',
      type: ToastType.warning,
    );
  }

  /// Show authentication error
  static void authError(BuildContext context, dynamic error) {
    final errorStr = error.toString().toLowerCase();
    String message;

    if (errorStr.contains('email-already-in-use')) {
      message = 'This email is already registered';
    } else if (errorStr.contains('invalid-email')) {
      message = 'Please enter a valid email';
    } else if (errorStr.contains('weak-password')) {
      message = 'Please use a stronger password';
    } else if (errorStr.contains('user-not-found')) {
      message = 'No account found with this email';
    } else if (errorStr.contains('wrong-password')) {
      message = 'Incorrect password';
    } else if (errorStr.contains('too-many-requests')) {
      message = 'Too many attempts. Try again later';
    } else {
      message = _getUserFriendlyError(error);
    }

    ToastNotification.show(context, message: message, type: ToastType.error);
  }

  /// Show upload error
  static void uploadError(BuildContext context, {String? itemName}) {
    final message = itemName != null
        ? 'Couldn\'t upload $itemName'
        : 'Upload failed';
    ToastNotification.show(context, message: message, type: ToastType.error);
  }

  /// Show connection error
  static void connectionError(BuildContext context) {
    ToastNotification.show(
      context,
      message: 'No internet connection',
      type: ToastType.error,
    );
  }

  /// Show timeout error
  static void timeoutError(BuildContext context) {
    ToastNotification.show(
      context,
      message: 'Request timed out. Please try again',
      type: ToastType.error,
    );
  }

  /// Show a custom toast with duration
  static void custom({
    required BuildContext context,
    required String message,
    required ToastType type,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    ToastNotification.show(
      context,
      message: message,
      type: type,
      duration: duration,
      onTap: onTap,
    );
  }

  /// Dismiss the current toast
  static void dismiss() {
    ToastNotification.dismiss();
  }
}
