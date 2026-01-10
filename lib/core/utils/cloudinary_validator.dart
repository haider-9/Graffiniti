import 'package:dio/dio.dart';
import '../config/cloudinary_config.dart';

class CloudinaryValidator {
  static Future<Map<String, dynamic>> validateConfiguration() async {
    final results = <String, dynamic>{
      'isValid': false,
      'errors': <String>[],
      'warnings': <String>[],
      'info': <String>[],
    };

    try {
      // Check basic configuration
      if (CloudinaryConfig.cloudName.isEmpty) {
        results['errors'].add('Cloud name is empty');
      } else {
        results['info'].add('Cloud name: ${CloudinaryConfig.cloudName}');
      }

      if (CloudinaryConfig.uploadPreset.isEmpty) {
        results['errors'].add('Upload preset is empty');
      } else {
        results['info'].add('Upload preset: ${CloudinaryConfig.uploadPreset}');
      }

      // Test connection to Cloudinary
      final dio = Dio();
      try {
        final response = await dio.post(
          CloudinaryConfig.uploadUrl,
          data: FormData.fromMap({
            'upload_preset': CloudinaryConfig.uploadPreset,
          }),
          options: Options(
            validateStatus: (status) => true,
            receiveTimeout: const Duration(seconds: 10),
          ),
        );

        if (response.statusCode == 400) {
          final error = response.data?['error'];
          if (error != null) {
            final message = error['message']?.toString() ?? '';
            if (message.contains('Invalid upload preset')) {
              results['errors'].add(
                'Upload preset "${CloudinaryConfig.uploadPreset}" does not exist or is not unsigned',
              );
              results['info'].add(
                'Create an unsigned upload preset in your Cloudinary console',
              );
            } else if (message.contains('Missing required parameter - file')) {
              results['info'].add('Upload preset is correctly configured');
              results['isValid'] = true;
            } else {
              results['warnings'].add('Unexpected response: $message');
            }
          }
        } else if (response.statusCode == 200) {
          results['info'].add('Connection successful');
          results['isValid'] = true;
        } else {
          results['warnings'].add(
            'Unexpected status code: ${response.statusCode}',
          );
        }
      } catch (e) {
        if (e is DioException) {
          switch (e.type) {
            case DioExceptionType.connectionTimeout:
            case DioExceptionType.receiveTimeout:
              results['errors'].add(
                'Connection timeout - check internet connection',
              );
              break;
            case DioExceptionType.connectionError:
              results['errors'].add(
                'Connection error - check internet connection',
              );
              break;
            default:
              results['errors'].add('Network error: ${e.message}');
          }
        } else {
          results['errors'].add('Test failed: ${e.toString()}');
        }
      }
    } catch (e) {
      results['errors'].add('Validation failed: ${e.toString()}');
    }

    return results;
  }

  static String formatValidationResults(Map<String, dynamic> results) {
    final buffer = StringBuffer();

    buffer.writeln('=== Cloudinary Configuration Validation ===\n');

    if (results['isValid'] == true) {
      buffer.writeln('✅ Configuration is valid and working!\n');
    } else {
      buffer.writeln('❌ Configuration has issues that need to be fixed\n');
    }

    final errors = results['errors'] as List<String>;
    if (errors.isNotEmpty) {
      buffer.writeln('🚨 ERRORS:');
      for (final error in errors) {
        buffer.writeln('  • $error');
      }
      buffer.writeln();
    }

    final warnings = results['warnings'] as List<String>;
    if (warnings.isNotEmpty) {
      buffer.writeln('⚠️  WARNINGS:');
      for (final warning in warnings) {
        buffer.writeln('  • $warning');
      }
      buffer.writeln();
    }

    final info = results['info'] as List<String>;
    if (info.isNotEmpty) {
      buffer.writeln('ℹ️  INFO:');
      for (final infoItem in info) {
        buffer.writeln('  • $infoItem');
      }
      buffer.writeln();
    }

    if (errors.isNotEmpty) {
      buffer.writeln('📝 TO FIX UPLOAD PRESET ISSUES:');
      buffer.writeln('1. Go to https://cloudinary.com/console');
      buffer.writeln('2. Navigate to Settings → Upload');
      buffer.writeln('3. Click "Add upload preset"');
      buffer.writeln('4. Set name to: ${CloudinaryConfig.uploadPreset}');
      buffer.writeln('5. Set Signing Mode to: Unsigned');
      buffer.writeln('6. Save the preset');
    }

    return buffer.toString();
  }
}
