import 'package:flutter/material.dart';
import '../config/cloudinary_config.dart';
import 'cloudinary_validator.dart';

class CloudinaryDebugDialog extends StatefulWidget {
  const CloudinaryDebugDialog({super.key});

  @override
  State<CloudinaryDebugDialog> createState() => _CloudinaryDebugDialogState();
}

class _CloudinaryDebugDialogState extends State<CloudinaryDebugDialog> {
  String _status = 'Ready to test';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text(
        'Cloudinary Debug',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cloud Name: ${CloudinaryConfig.cloudName}',
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            'Upload Preset: ${CloudinaryConfig.uploadPreset}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _status,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : _testConnection,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Test Connection'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing connection...';
    });

    try {
      final results = await CloudinaryValidator.validateConfiguration();
      final formattedResults = CloudinaryValidator.formatValidationResults(
        results,
      );

      setState(() {
        _status = formattedResults;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Validation failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
