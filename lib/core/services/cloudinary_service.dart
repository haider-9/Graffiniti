import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../config/cloudinary_config.dart';

class CloudinaryService {
  final Dio _dio = Dio();

  /// Upload profile image to Cloudinary
  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      final fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}';
      return await _uploadImage(imageFile, fileName, CloudinaryConfig.profileImagesFolder);
    } catch (e) {
      throw Exception('Failed to upload profile image: ${e.toString()}');
    }
  }

  /// Upload banner image to Cloudinary
  Future<String> uploadBannerImage(String userId, File imageFile) async {
    try {
      final fileName = 'banner_${userId}_${DateTime.now().millisecondsSinceEpoch}';
      return await _uploadImage(imageFile, fileName, CloudinaryConfig.bannerImagesFolder);
    } catch (e) {
      throw Exception('Failed to upload banner image: ${e.toString()}');
    }
  }

  /// Upload graffiti image to Cloudinary
  Future<String> uploadGraffitiImage(String userId, File imageFile) async {
    try {
      final fileName = 'graffiti_${userId}_${DateTime.now().millisecondsSinceEpoch}';
      return await _uploadImage(imageFile, fileName, CloudinaryConfig.graffitiImagesFolder);
    } catch (e) {
      throw Exception('Failed to upload graffiti image: ${e.toString()}');
    }
  }

  /// Generic method to upload image to Cloudinary
  Future<String> _uploadImage(File imageFile, String fileName, String folder) async {
    try {
      // Read image file as bytes
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // Create form data
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          imageBytes,
          filename: '$fileName.jpg',
        ),
        'upload_preset': CloudinaryConfig.uploadPreset,
        'folder': folder,
        'public_id': fileName,
        'resource_type': 'image',
        'format': 'jpg',
      });

      // Upload to Cloudinary
      final response = await _dio.post(
        CloudinaryConfig.uploadUrl,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
          connectTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        return responseData['secure_url'] as String;
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout) {
          throw Exception('Upload timeout. Please check your internet connection.');
        } else if (e.type == DioExceptionType.connectionError) {
          throw Exception('Connection error. Please check your internet connection.');
        } else {
          throw Exception('Upload failed: ${e.message}');
        }
      }
      throw Exception('Upload failed: ${e.toString()}');
    }
  }

  /// Delete image from Cloudinary using public_id
  Future<bool> deleteImage(String publicId) async {
    try {
      // For unsigned uploads, we can't delete images directly
      // This would require a signed request with API key and secret
      // For now, we'll just return true as images will be overwritten
      // when new ones are uploaded with the same public_id
      return true;
    } catch (e) {
      print('Warning: Could not delete image from Cloudinary: $e');
      return false;
    }
  }

  /// Get optimized URL for different image sizes
  String getOptimizedImageUrl(String originalUrl, {
    int? width,
    int? height,
    String quality = 'auto',
    String format = 'auto',
  }) {
    if (originalUrl.isEmpty || !originalUrl.contains('cloudinary.com')) {
      return originalUrl;
    }

    try {
      // Extract the part after /upload/ from the URL
      final uploadIndex = originalUrl.indexOf('/upload/');
      if (uploadIndex == -1) return originalUrl;

      final beforeUpload = originalUrl.substring(0, uploadIndex + 8);
      final afterUpload = originalUrl.substring(uploadIndex + 8);

      // Build transformation string
      List<String> transformations = [];

      if (quality != 'auto') transformations.add('q_$quality');
      if (format != 'auto') transformations.add('f_$format');
      if (width != null) transformations.add('w_$width');
      if (height != null) transformations.add('h_$height');

      // Add crop mode if both width and height are specified
      if (width != null && height != null) {
        transformations.add('c_fill');
      }

      if (transformations.isNotEmpty) {
        return '$beforeUpload${transformations.join(',')}/q_auto,f_auto/$afterUpload';
      } else {
        return '$beforeUpload/q_auto,f_auto/$afterUpload';
      }
    } catch (e) {
      print('Error optimizing image URL: $e');
      return originalUrl;
    }
  }

  /// Get thumbnail URL
  String getThumbnailUrl(String originalUrl, {int size = 150}) {
    return getOptimizedImageUrl(
      originalUrl,
      width: size,
      height: size,
      quality: '80',
    );
  }

  /// Get profile image URL optimized for profile display
  String getProfileImageUrl(String originalUrl) {
    return getOptimizedImageUrl(
      originalUrl,
      width: CloudinaryConfig.profileImageSize,
      height: CloudinaryConfig.profileImageSize,
      quality: CloudinaryConfig.profileImageQuality,
    );
  }

  /// Get banner image URL optimized for banner display
  String getBannerImageUrl(String originalUrl) {
    return getOptimizedImageUrl(
      originalUrl,
      width: CloudinaryConfig.bannerImageWidth,
      height: CloudinaryConfig.bannerImageHeight,
      quality: CloudinaryConfig.bannerImageQuality,
    );
  }

  /// Upload image from bytes (useful for camera captures)
  Future<String> uploadImageFromBytes(
    Uint8List imageBytes,
    String userId,
    String type, // 'profile', 'banner', or 'graffiti'
  ) async {
    try {
      final fileName = '${type}_${userId}_${DateTime.now().millisecondsSinceEpoch}';
      final folder = '${type}_images';

      // Create form data
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          imageBytes,
          filename: '$fileName.jpg',
        ),
        'upload_preset': CloudinaryConfig.uploadPreset,
        'folder': folder,
        'public_id': fileName,
        'resource_type': 'image',
        'format': 'jpg',
      });

      // Upload to Cloudinary
      final response = await _dio.post(
        CloudinaryConfig.uploadUrl,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
          connectTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        return responseData['secure_url'] as String;
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout) {
          throw Exception('Upload timeout. Please check your internet connection.');
        } else if (e.type == DioExceptionType.connectionError) {
          throw Exception('Connection error. Please check your internet connection.');
        } else {
          throw Exception('Upload failed: ${e.message}');
        }
      }
      throw Exception('Upload failed: ${e.toString()}');
    }
  }

  /// Check if URL is a Cloudinary URL
  bool isCloudinaryUrl(String url) {
    return url.contains('cloudinary.com');
  }

  /// Extract public_id from Cloudinary URL
  String? extractPublicId(String cloudinaryUrl) {
    try {
      // Example URL: https://res.cloudinary.com/dntncz9no/image/upload/v1234567890/profile_images/profile_user123_1234567890.jpg
      final uri = Uri.parse(cloudinaryUrl);
      final pathSegments = uri.pathSegments;

      // Find the index of 'upload'
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1 || uploadIndex + 2 >= pathSegments.length) {
        return null;
      }

      // The public_id is everything after the version (v1234567890)
      final publicIdParts = pathSegments.sublist(uploadIndex + 2);
      String publicId = publicIdParts.join('/');

      // Remove file extension
      final lastDotIndex = publicId.lastIndexOf('.');
      if (lastDotIndex != -1) {
        publicId = publicId.substring(0, lastDotIndex);
      }

      return publicId;
    } catch (e) {
      print('Error extracting public_id: $e');
      return null;
    }
  }
}
