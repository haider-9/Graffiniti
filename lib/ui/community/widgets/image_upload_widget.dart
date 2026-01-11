import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/config/cloudinary_config.dart';

class ImageUploadWidget extends StatefulWidget {
  final String? initialImageUrl;
  final String label;
  final String hint;
  final IconData icon;
  final double height;
  final int maxSizeBytes;
  final Function(File?) onImageSelected;
  final Function(String?)? onImageUrlChanged;
  final bool isUploading;

  const ImageUploadWidget({
    super.key,
    this.initialImageUrl,
    required this.label,
    required this.hint,
    required this.icon,
    this.height = 120,
    required this.maxSizeBytes,
    required this.onImageSelected,
    this.onImageUrlChanged,
    this.isUploading = false,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  File? _selectedImage;
  String? _currentImageUrl;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentImageUrl = widget.initialImageUrl;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _buildImageContent(colorScheme),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildActionButton(
              icon: Icons.camera_alt,
              label: 'Camera',
              onTap: () => _pickImage(ImageSource.camera),
              colorScheme: colorScheme,
            ),
            const SizedBox(width: 12),
            _buildActionButton(
              icon: Icons.photo_library,
              label: 'Gallery',
              onTap: () => _pickImage(ImageSource.gallery),
              colorScheme: colorScheme,
            ),
            if (_selectedImage != null || _currentImageUrl != null) ...[
              const SizedBox(width: 12),
              _buildActionButton(
                icon: Icons.delete_outline,
                label: 'Remove',
                onTap: _removeImage,
                colorScheme: colorScheme,
                isDestructive: true,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildImageContent(ColorScheme colorScheme) {
    if (widget.isUploading) {
      return Container(
        color: colorScheme.surface,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text('Uploading...'),
            ],
          ),
        ),
      );
    }

    if (_selectedImage != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(_selectedImage!, fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.6],
              ),
            ),
          ),
        ],
      );
    }

    if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _currentImageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholder(colorScheme);
            },
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.6],
              ),
            ),
          ),
        ],
      );
    }

    return _buildPlaceholder(colorScheme);
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, color: colorScheme.onSurfaceVariant, size: 32),
            const SizedBox(height: 8),
            Text(
              widget.hint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: widget.isUploading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDestructive
              ? colorScheme.errorContainer
              : colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDestructive
                ? colorScheme.error.withValues(alpha: 0.3)
                : colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isDestructive
                  ? colorScheme.onErrorContainer
                  : colorScheme.onPrimaryContainer,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isDestructive
                    ? colorScheme.onErrorContainer
                    : colorScheme.onPrimaryContainer,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);

        // Validate file size
        final int fileSize = await imageFile.length();
        if (fileSize > widget.maxSizeBytes) {
          if (mounted) {
            _showErrorSnackBar(
              'Image too large. Maximum size is ${_formatFileSize(widget.maxSizeBytes)}',
            );
          }
          return;
        }

        // Validate file format
        final String extension = pickedFile.path.split('.').last.toLowerCase();
        if (!CloudinaryConfig.supportedFormats.contains(extension)) {
          if (mounted) {
            _showErrorSnackBar(
              'Unsupported format. Please use: ${CloudinaryConfig.supportedFormats.join(', ')}',
            );
          }
          return;
        }

        setState(() {
          _selectedImage = imageFile;
        });

        widget.onImageSelected(imageFile);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to pick image: ${e.toString()}');
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _currentImageUrl = null;
    });
    widget.onImageSelected(null);
    widget.onImageUrlChanged?.call(null);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
