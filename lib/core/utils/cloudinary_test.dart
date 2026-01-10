import 'package:dio/dio.dart';
import '../config/cloudinary_config.dart';

class CloudinaryTest {
  static Future<void> testConnection() async {
    try {
      final dio = Dio();

      // Test basic connection to Cloudinary
      final testUrl =
          'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload';

      print('Testing Cloudinary connection...');
      print('Cloud Name: ${CloudinaryConfig.cloudName}');
      print('Upload Preset: ${CloudinaryConfig.uploadPreset}');
      print('Upload URL: $testUrl');

      // Try a simple POST to see if the endpoint responds
      try {
        final response = await dio.post(
          testUrl,
          data: FormData.fromMap({
            'upload_preset': CloudinaryConfig.uploadPreset,
          }),
          options: Options(
            validateStatus: (status) => true, // Accept any status code
          ),
        );

        print('Response Status: ${response.statusCode}');
        print('Response Data: ${response.data}');

        if (response.statusCode == 400) {
          final error = response.data['error'];
          if (error != null && error['message'] != null) {
            print('Cloudinary Error: ${error['message']}');

            if (error['message'].toString().contains('Invalid upload preset')) {
              print(
                '❌ Upload preset "${CloudinaryConfig.uploadPreset}" does not exist or is not unsigned',
              );
              print(
                '✅ Create an unsigned upload preset named "${CloudinaryConfig.uploadPreset}" in your Cloudinary console',
              );
            }
          }
        } else if (response.statusCode == 200) {
          print('✅ Cloudinary connection successful!');
        }
      } catch (e) {
        print('❌ Connection test failed: $e');
      }
    } catch (e) {
      print('❌ Test setup failed: $e');
    }
  }

  static Future<void> testUploadPreset() async {
    try {
      final dio = Dio();

      // Test if upload preset exists by making a request without file
      final response = await dio.post(
        CloudinaryConfig.uploadUrl,
        data: FormData.fromMap({
          'upload_preset': CloudinaryConfig.uploadPreset,
        }),
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 400) {
        final error = response.data['error'];
        if (error != null) {
          final message = error['message'].toString();
          if (message.contains('Invalid upload preset')) {
            print(
              '❌ Upload preset "${CloudinaryConfig.uploadPreset}" not found',
            );
            print('📝 Steps to fix:');
            print('1. Go to https://cloudinary.com/console');
            print('2. Navigate to Settings → Upload');
            print('3. Click "Add upload preset"');
            print('4. Set name to: ${CloudinaryConfig.uploadPreset}');
            print('5. Set Signing Mode to: Unsigned');
            print('6. Save the preset');
          } else if (message.contains('Missing required parameter - file')) {
            print(
              '✅ Upload preset "${CloudinaryConfig.uploadPreset}" exists and is configured correctly',
            );
          } else {
            print('⚠️  Unexpected error: $message');
          }
        }
      }
    } catch (e) {
      print('❌ Preset test failed: $e');
    }
  }
}
