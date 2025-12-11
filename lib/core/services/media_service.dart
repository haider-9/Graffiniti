import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import '../utils/permission_helper.dart';
import '../utils/toast_helper.dart';

class MediaService {
  /// Save image to gallery
  static Future<bool> saveImageToGallery(
    BuildContext context,
    String imagePath,
  ) async {
    try {
      // Request storage permission
      final hasPermission = await PermissionHelper.requestStoragePermission(
        context,
      );
      if (!hasPermission) {
        return false;
      }

      // Get the file
      final File imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        if (context.mounted) {
          ToastHelper.error(context, 'Image file not found');
        }
        return false;
      }

      // Save to gallery using gal
      await Gal.putImage(imagePath);

      if (context.mounted) {
        ToastHelper.success(context, 'Image saved to gallery');
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ToastHelper.error(context, 'Failed to save image: ${e.toString()}');
      }
      return false;
    }
  }

  /// Delete temporary file
  static Future<void> deleteTempFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting temp file: $e');
    }
  }
}
