import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../config/cloudinary_config.dart';

class CloudinaryService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
    ),
  );

  /// Upload profile image to Cloudinary
  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      final fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}';
      return await _uploadImage(
        imageFile,
        fileName,
        CloudinaryConfig.profileImagesFolder,
      );
    } catch (e) {
      throw Exception('Failed to upload profile image: ${e.toString()}');
    }
  }

  /// Upload banner image to Cloudinary
  Future<String> uploadBannerImage(String userId, File imageFile) async {
    try {
      final fileName =
          'banner_${userId}_${DateTime.now().millisecondsSinceEpoch}';
      return await _uploadImage(
        imageFile,
        fileName,
        CloudinaryConfig.bannerImagesFolder,
      );
    } catch (e) {
      throw Exception('Failed to upload banner image: ${e.toString()}');
    }
  }

  /// Upload graffiti image to Cloudinary
  Future<String> uploadGraffitiImage(String userId, File imageFile) async {
    try {
      final fileName =
          'graffiti_${userId}_${DateTime.now().millisecondsSinceEpoch}';
      return await _uploadImage(
        imageFile,
        fileName,
        CloudinaryConfig.graffitiImagesFolder,
      );
    } catch (e) {
      throw Exception('Failed to upload graffiti image: ${e.toString()}');
    }
  }

  /// Upload community profile image to Cloudinary
  Future<String> uploadCommunityProfileImage(
    String communityId,
    File imageFile,
  ) async {
    try {
      final fileName =
          'community_profile_${communityId}_${DateTime.now().millisecondsSinceEpoch}';
      return await _uploadImage(
        imageFile,
        fileName,
        CloudinaryConfig.communityImagesFolder,
      );
    } catch (e) {
      throw Exception(
        'Failed to upload community profile image: ${e.toString()}',
      );
    }
  }

  /// Upload community banner image to Cloudinary
  Future<String> uploadCommunityBannerImage(
    String communityId,
    File imageFile,
  ) async {
    try {
      final fileName =
          'community_banner_${communityId}_${DateTime.now().millisecondsSinceEpoch}';
      return await _uploadImage(
        imageFile,
        fileName,
        CloudinaryConfig.communityBannersFolder,
      );
    } catch (e) {
      throw Exception(
        'Failed to upload community banner image: ${e.toString()}',
      );
    }
  }

  /// Generic method to upload image to Cloudinary
  Future<String> _uploadImage(
    File imageFile,
    String fileName,
    String folder,
  ) async {
    try {
      // Validate file exists and is readable
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      // Get file extension from original file
      final originalPath = imageFile.path;
      final extension = originalPath.split('.').last.toLowerCase();
      final supportedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

      if (!supportedExtensions.contains(extension)) {
        throw Exception('Unsupported image format: $extension');
      }

      // Use original extension instead of forcing jpg
      final fileNameWithExt = '$fileName.$extension';

      // Create multipart file from file path (more reliable than bytes)
      final multipartFile = await MultipartFile.fromFile(
        imageFile.path,
        filename: fileNameWithExt,
      );

      // Create form data with proper structure
      final formData = FormData.fromMap({
        'file': multipartFile,
        'upload_preset': CloudinaryConfig.uploadPreset,
        'folder': folder,
        'public_id': fileName,
        'resource_type': 'image',
      });

      // Upload to Cloudinary with proper timeout settings
      final response = await _dio.post(
        CloudinaryConfig.uploadUrl,
        data: formData,
        options: Options(
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      // Handle response
      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData != null && responseData['secure_url'] != null) {
          return responseData['secure_url'] as String;
        } else {
          throw Exception(
            'Invalid response from Cloudinary: missing secure_url',
          );
        }
      } else {
        // Handle specific error responses
        String errorMessage =
            'Upload failed with status: ${response.statusCode}';
        if (response.data != null && response.data['error'] != null) {
          final error = response.data['error'];
          if (error['message'] != null) {
            errorMessage = 'Cloudinary error: ${error['message']}';
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is DioException) {
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            throw Exception(
              'Upload timeout. Please check your internet connection and try again.',
            );
          case DioExceptionType.connectionError:
            throw Exception(
              'Connection error. Please check your internet connection.',
            );
          case DioExceptionType.badResponse:
            final statusCode = e.response?.statusCode;
            final responseData = e.response?.data;
            String errorMsg = 'Server error (${statusCode ?? 'unknown'})';

            if (responseData != null && responseData['error'] != null) {
              final error = responseData['error'];
              if (error['message'] != null) {
                errorMsg = 'Cloudinary error: ${error['message']}';
              }
            }
            throw Exception(errorMsg);
          default:
            throw Exception('Upload failed: ${e.message ?? e.toString()}');
        }
      }
      throw Exception('Upload failed: ${e.toString()}');
    }
  }

  /// Delete image from Cloudinary using public_id
  Future<bool> deleteImage(String publicId) async {
    try {
      print('Attempting to delete image with public_id: $publicId');

      // For unsigned uploads, Cloudinary doesn't allow true deletion
      // We have a few options:
      // 1. Use signed uploads (requires server-side implementation)
      // 2. Configure auto-cleanup in Cloudinary dashboard
      // 3. Accept that old images remain (current approach)

      // Log the limitation for awareness
      print(
        'INFO: Using unsigned uploads - old images cannot be deleted automatically.',
      );
      print('Old image will remain in Cloudinary: $publicId');
      print('To enable deletion, consider:');
      print('  1. Implementing server-side signed deletion');
      print('  2. Configuring Cloudinary auto-cleanup policies');
      print('  3. Periodic manual cleanup');

      // Return true to indicate the "deletion attempt" completed
      // This prevents blocking the user experience
      return true;
    } catch (e) {
      print('Error in delete process: $e');
      return true; // Don't block user experience
    }
  }

  /// Delete image by URL (extracts public_id and deletes)
  Future<bool> deleteImageByUrl(String imageUrl) async {
    print('Attempting to delete image by URL: $imageUrl');
    final publicId = extractPublicId(imageUrl);
    print('Extracted public_id: $publicId');

    if (publicId != null) {
      return await deleteImage(publicId);
    } else {
      print('Failed to extract public_id from URL: $imageUrl');
      return false;
    }
  }

  /// Get optimized URL for different image sizes
  String getOptimizedImageUrl(
    String originalUrl, {
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
      final fileName =
          '${type}_${userId}_${DateTime.now().millisecondsSinceEpoch}';
      final folder = '${type}_images';

      // Create multipart file from bytes with proper filename
      final multipartFile = MultipartFile.fromBytes(
        imageBytes,
        filename: '$fileName.jpg',
      );

      // Create form data
      final formData = FormData.fromMap({
        'file': multipartFile,
        'upload_preset': CloudinaryConfig.uploadPreset,
        'folder': folder,
        'public_id': fileName,
        'resource_type': 'image',
      });

      // Upload to Cloudinary
      final response = await _dio.post(
        CloudinaryConfig.uploadUrl,
        data: formData,
        options: Options(
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData != null && responseData['secure_url'] != null) {
          return responseData['secure_url'] as String;
        } else {
          throw Exception(
            'Invalid response from Cloudinary: missing secure_url',
          );
        }
      } else {
        String errorMessage =
            'Upload failed with status: ${response.statusCode}';
        if (response.data != null && response.data['error'] != null) {
          final error = response.data['error'];
          if (error['message'] != null) {
            errorMessage = 'Cloudinary error: ${error['message']}';
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is DioException) {
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            throw Exception(
              'Upload timeout. Please check your internet connection and try again.',
            );
          case DioExceptionType.connectionError:
            throw Exception(
              'Connection error. Please check your internet connection.',
            );
          case DioExceptionType.badResponse:
            final statusCode = e.response?.statusCode;
            final responseData = e.response?.data;
            String errorMsg = 'Server error (${statusCode ?? 'unknown'})';

            if (responseData != null && responseData['error'] != null) {
              final error = responseData['error'];
              if (error['message'] != null) {
                errorMsg = 'Cloudinary error: ${error['message']}';
              }
            }
            throw Exception(errorMsg);
          default:
            throw Exception('Upload failed: ${e.message ?? e.toString()}');
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
