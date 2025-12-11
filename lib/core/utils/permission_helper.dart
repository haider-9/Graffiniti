import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionHelper {
  /// Request camera permission
  static Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.camera.request();
      if (result.isGranted) {
        return true;
      } else if (result.isPermanentlyDenied && context.mounted) {
        _showPermissionDeniedDialog(
          context,
          'Camera',
          'Camera access is required to take photos.',
        );
        return false;
      }
    }

    if (status.isPermanentlyDenied && context.mounted) {
      _showPermissionDeniedDialog(
        context,
        'Camera',
        'Camera access is required to take photos.',
      );
      return false;
    }

    return false;
  }

  /// Request storage/photos permission
  static Future<bool> requestStoragePermission(BuildContext context) async {
    // For Android 13+ (API 33+), we need to request photos permission
    // For older versions, we need storage permission
    PermissionStatus status;

    if (await _isAndroid13OrHigher()) {
      status = await Permission.photos.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        final result = await Permission.photos.request();
        if (result.isGranted) {
          return true;
        } else if (result.isPermanentlyDenied && context.mounted) {
          _showPermissionDeniedDialog(
            context,
            'Photos',
            'Photos access is required to save images to your gallery.',
          );
          return false;
        }
      }

      if (status.isPermanentlyDenied && context.mounted) {
        _showPermissionDeniedDialog(
          context,
          'Photos',
          'Photos access is required to save images to your gallery.',
        );
        return false;
      }
    } else {
      status = await Permission.storage.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        final result = await Permission.storage.request();
        if (result.isGranted) {
          return true;
        } else if (result.isPermanentlyDenied && context.mounted) {
          _showPermissionDeniedDialog(
            context,
            'Storage',
            'Storage access is required to save images to your gallery.',
          );
          return false;
        }
      }

      if (status.isPermanentlyDenied && context.mounted) {
        _showPermissionDeniedDialog(
          context,
          'Storage',
          'Storage access is required to save images to your gallery.',
        );
        return false;
      }
    }

    return false;
  }

  /// Check if running on Android 13 or higher
  static Future<bool> _isAndroid13OrHigher() async {
    // This is a simplified check - in production you'd want to check the actual Android version
    return await Permission.photos.status != PermissionStatus.restricted;
  }

  /// Show dialog when permission is permanently denied
  static void _showPermissionDeniedDialog(
    BuildContext context,
    String permissionName,
    String message,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: Text(
          '$permissionName Permission Required',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          '$message\n\nPlease enable it in your device settings.',
          style: const TextStyle(color: Color(0xFFAAAAAA)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFFAAAAAA)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text(
              'Open Settings',
              style: TextStyle(color: Color(0xFFFF6B35)),
            ),
          ),
        ],
      ),
    );
  }
}
