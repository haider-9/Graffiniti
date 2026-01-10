import 'dart:math';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import '../main.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/glassmorphic_container.dart';
import '../core/utils/permission_helper.dart';
import '../core/services/media_service.dart';
import '../core/services/share_service.dart';
import 'ar_graffiti_page.dart';
import 'ar_demo_launcher.dart';

class AspectRatioOption {
  final String label;
  final double? ratio; // null means full screen
  final IconData icon;

  AspectRatioOption(this.label, this.ratio, this.icon);
}

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isFlashOn = false;
  bool _isRearCamera = true;

  late AnimationController _captureAnimationController;
  late AnimationController _modeAnimationController;

  int _selectedMode = 0; // 0: Photo
  final List<String> _modes = ['Photo'];

  // Aspect ratio options
  int _selectedAspectRatio = 1; // 0: Full Screen, 1: 1:1, 2: 4:3, 3: 16:9
  final List<AspectRatioOption> _aspectRatios = [
    AspectRatioOption('Full', null, Icons.fullscreen),
    AspectRatioOption('1:1', 1.0, Icons.crop_square),
    AspectRatioOption('4:3', 4.0 / 3.0, Icons.crop_3_2),
    AspectRatioOption('16:9', 16.0 / 9.0, Icons.crop_16_9),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _captureAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _modeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _requestPermissions();
    _initializeCamera();
  }

  Future<void> _requestPermissions() async {
    if (!mounted) return;

    // Request camera permission
    await PermissionHelper.requestCameraPermission(context);

    if (!mounted) return;

    // Request storage permission for saving
    await PermissionHelper.requestStoragePermission(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _captureAnimationController.dispose();
    _modeAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (cameras.isEmpty) return;

    final camera = _isRearCamera ? cameras.first : cameras.last;
    _controller = CameraController(
      camera,
      ResolutionPreset.veryHigh,
      enableAudio: false, // Audio not needed without video mode
    );

    _initializeControllerFuture = _controller!.initialize().then((_) async {
      try {
        // Set initial flash mode after initialization
        await _controller!.setFlashMode(
          _isFlashOn ? FlashMode.torch : FlashMode.off,
        );
      } catch (e) {
        debugPrint('Error setting initial flash mode: $e');
      }
    });

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleCapture() async {
    if (_selectedMode == 1) {
      // AR Graffiti mode
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ARGraffitiPage()),
      );
      return;
    }

    _captureAnimationController.forward().then((_) {
      _captureAnimationController.reverse();
    });

    try {
      await _initializeControllerFuture;

      if (_selectedMode == 0) {
        // Photo mode
        final image = await _controller!.takePicture();

        // Crop image to selected aspect ratio
        final String? croppedPath = await _cropImageToAspectRatio(image.path);
        _showImagePreview(croppedPath ?? image.path);
      }
    } catch (e) {
      debugPrint('Error capturing: $e');
    }
  }

  Future<String?> _cropImageToAspectRatio(String imagePath) async {
    try {
      final selectedRatio = _aspectRatios[_selectedAspectRatio];

      // If full screen is selected, no cropping needed
      if (selectedRatio.ratio == null) {
        return imagePath;
      }

      // Read the image file
      final File imageFile = File(imagePath);
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // Decode the image
      final img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return imagePath;

      // Calculate crop dimensions
      final int originalWidth = originalImage.width;
      final int originalHeight = originalImage.height;
      final double targetRatio = selectedRatio.ratio!;

      int cropWidth, cropHeight;
      int offsetX = 0, offsetY = 0;

      // Determine crop dimensions based on target aspect ratio
      if (originalWidth / originalHeight > targetRatio) {
        // Image is wider than target ratio, crop width
        cropHeight = originalHeight;
        cropWidth = (originalHeight * targetRatio).round();
        offsetX = (originalWidth - cropWidth) ~/ 2;
      } else {
        // Image is taller than target ratio, crop height
        cropWidth = originalWidth;
        cropHeight = (originalWidth / targetRatio).round();
        offsetY = (originalHeight - cropHeight) ~/ 2;
      }

      // Crop the image
      final img.Image croppedImage = img.copyCrop(
        originalImage,
        x: offsetX,
        y: offsetY,
        width: cropWidth,
        height: cropHeight,
      );

      // Create new file path for cropped image
      final String directory = path.dirname(imagePath);
      final String fileName = path.basenameWithoutExtension(imagePath);
      final String extension = path.extension(imagePath);
      final String croppedPath = path.join(
        directory,
        '${fileName}_cropped$extension',
      );

      // Save cropped image
      final File croppedFile = File(croppedPath);
      await croppedFile.writeAsBytes(img.encodeJpg(croppedImage, quality: 95));

      // Delete original uncropped image
      await imageFile.delete();

      return croppedPath;
    } catch (e) {
      debugPrint('Error cropping image: $e');
      return imagePath; // Return original path if cropping fails
    }
  }

  void _showImagePreview(String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreviewPage(mediaPath: imagePath),
      ),
    );
  }

  void _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      debugPrint('Camera not initialized');
      return;
    }

    try {
      final newFlashState = !_isFlashOn;
      final flashMode = newFlashState ? FlashMode.torch : FlashMode.off;

      debugPrint('Setting flash mode to: $flashMode');
      await _controller!.setFlashMode(flashMode);

      setState(() {
        _isFlashOn = newFlashState;
      });

      debugPrint('Flash ${newFlashState ? 'enabled' : 'disabled'}');
    } catch (e) {
      debugPrint('Error toggling flash: $e');
      // Show a snackbar to inform user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Flash not available on this camera'),
            backgroundColor: AppTheme.primaryBlack,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _switchCamera() async {
    setState(() {
      _isRearCamera = !_isRearCamera;
      // Turn off flash when switching to front camera (usually no flash)
      if (!_isRearCamera) {
        _isFlashOn = false;
      }
    });
    await _controller?.dispose();
    _initializeCamera();
  }

  // Standard mobile camera overlay - shows crop area on fullscreen preview
  Widget _buildAspectRatioOverlay() {
    final size = MediaQuery.of(context).size;
    final selectedRatio = _aspectRatios[_selectedAspectRatio];

    if (selectedRatio.ratio == null) return const SizedBox.shrink();

    final screenWidth = size.width;
    final screenHeight = size.height;
    final targetRatio = selectedRatio.ratio!;
    final screenRatio = screenWidth / screenHeight;

    // Calculate crop area dimensions
    double cropWidth, cropHeight;
    double leftOffset = 0, rightOffset = 0, topOffset = 0, bottomOffset = 0;

    if (screenRatio > targetRatio) {
      // Screen is wider than target - crop sides
      cropHeight = screenHeight;
      cropWidth = screenHeight * targetRatio;
      leftOffset = (screenWidth - cropWidth) / 2;
      rightOffset = leftOffset;
    } else {
      // Screen is taller than target - crop top/bottom
      cropWidth = screenWidth;
      cropHeight = screenWidth / targetRatio;
      topOffset = (screenHeight - cropHeight) / 3;
      bottomOffset = topOffset;
    }

    return Stack(
      children: [
        // Top overlay
        if (topOffset > 0)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topOffset,
            child: Container(
              color: AppTheme.primaryBlack.withValues(alpha: 0.7),
            ),
          ),

        // Bottom overlay
        if (bottomOffset > 0)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: bottomOffset,
            child: Container(
              color: AppTheme.primaryBlack.withValues(alpha: 0.7),
            ),
          ),

        // Left overlay
        if (leftOffset > 0)
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            width: leftOffset,
            child: Container(
              color: AppTheme.primaryBlack.withValues(alpha: 0.7),
            ),
          ),

        // Right overlay
        if (rightOffset > 0)
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: rightOffset,
            child: Container(
              color: AppTheme.primaryBlack.withValues(alpha: 0.7),
            ),
          ),

        // Aspect ratio indicator
        Positioned(
          top: topOffset + 20,
          left: leftOffset + 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accentOrange.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.crop, color: Colors.white, size: 12),
                const SizedBox(width: 4),
                Text(
                  selectedRatio.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraPreview() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final selectedRatio = _aspectRatios[_selectedAspectRatio];
    final sensorRatio =
        _controller!.value.aspectRatio; // Natural camera sensor ratio
    final targetRatio = selectedRatio.ratio; // User-selected ratio or null

    /// 1. Base CameraPreview
    Widget preview = CameraPreview(_controller!);

    /// 2. Mirror only the FRONT camera preview
    if (!_isRearCamera) {
      preview = Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..rotateY(2 * pi),
        child: preview,
      );
    }

    // -------------------------------------------------------
    // MODE 1: FULLSCREEN (no selected ratio)
    // -------------------------------------------------------
    if (targetRatio == null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;

          final screenRatio = screenHeight / screenWidth;

          // Scale camera feed so it covers the entire screen without distortion
          final scale = (screenRatio > sensorRatio)
              ? screenRatio / sensorRatio
              : sensorRatio / screenRatio;

          return ClipRect(
            child: OverflowBox(
              alignment: Alignment.center,
              child: Transform.scale(
                scale: scale,
                child: SizedBox(
                  width: screenWidth,
                  height: screenWidth / sensorRatio,
                  child: preview,
                ),
              ),
            ),
          );
        },
      );
    }

    // -------------------------------------------------------
    // MODE 2: FIXED RATIO (square, 3:4, 9:16, etc.)
    // Professional crop, never stretch.
    // -------------------------------------------------------
    return AspectRatio(
      aspectRatio: targetRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boxW = constraints.maxWidth;
          final boxH = constraints.maxHeight;

          final boxRatio = boxW / boxH;

          // Calculate scale to fill the ratio area without stretching
          final scale = (boxRatio > sensorRatio)
              ? boxRatio / sensorRatio
              : sensorRatio / boxRatio;

          return ClipRect(
            child: OverflowBox(
              maxWidth: boxW * scale,
              maxHeight: boxH * scale,
              alignment: Alignment.center,
              child: AspectRatio(aspectRatio: sensorRatio, child: preview),
            ),
          );
        },
      ),
    );
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Camera Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),

            // Aspect Ratio Section
            const Text(
              'Aspect Ratio',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            // Aspect ratio options
            Row(
              children: List.generate(_aspectRatios.length, (index) {
                final option = _aspectRatios[index];
                final isSelected = _selectedAspectRatio == index;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAspectRatio = index;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      margin: EdgeInsets.only(
                        right: index < _aspectRatios.length - 1 ? 8 : 0,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppTheme.accentGradient : null,
                        color: isSelected
                            ? null
                            : AppTheme.lightGray.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? null
                            : Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(option.icon, color: Colors.white, size: 24),
                          const SizedBox(height: 8),
                          Text(
                            option.label,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                // Camera preview - always fullscreen
                Positioned.fill(child: _buildCameraPreview()),

                // Aspect ratio overlay - shows crop area
                if (_aspectRatios[_selectedAspectRatio].ratio != null)
                  _buildAspectRatioOverlay(),

                // Top controls
                _buildTopOverlay(),

                // Side tools
                _buildSideTools(),

                // Bottom controls
                _buildBottomControls(),

                // Mode selector
                _buildModeSelector(),
              ],
            );
          } else {
            return Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.backgroundGradient,
              ),
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.accentOrange),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildTopOverlay() {
    // Check if flash is available (usually not available on front cameras)
    final bool flashAvailable = _isRearCamera;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Flash toggle (only show if available)
          if (flashAvailable)
            GestureDetector(
              onTap: _toggleFlash,
              child: GlassmorphicContainer(
                width: 44,
                height: 44,
                borderRadius: const BorderRadius.all(Radius.circular(22)),
                child: Icon(
                  _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  color: _isFlashOn ? AppTheme.accentOrange : Colors.white,
                  size: 20,
                ),
              ),
            )
          else
            // Placeholder to maintain layout
            SizedBox(width: 44, height: 44),

          // Settings
          GestureDetector(
            onTap: _showSettingsMenu,
            child: GlassmorphicContainer(
              width: 44,
              height: 44,
              borderRadius: BorderRadius.circular(22),
              child: Icon(Icons.tune, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideTools() {
    return Positioned(
      right: 16,
      top: MediaQuery.of(context).size.height * 0.4,
      child: Column(
        children: [
          // AR Demo Launcher
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ARDemoLauncher()),
              );
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple, Colors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.view_in_ar_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Direct AR Graffiti button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ARGraffitiPage()),
              );
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentOrange.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.view_in_ar, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(height: 16),

          // Switch camera
          GestureDetector(
            onTap: _switchCamera,
            child: GlassmorphicContainer(
              width: 50,
              height: 50,
              borderRadius: BorderRadius.circular(25),
              child: Icon(Icons.flip_camera_ios, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 32,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Gallery
          GestureDetector(
            onTap: () {
              // Open gallery
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.lightGray,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: Icon(
                Icons.photo_library_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),

          // Capture button
          GestureDetector(
            onTap: _handleCapture,
            child: AnimatedBuilder(
              animation: _captureAnimationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 - (_captureAnimationController.value * 0.1),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          Colors.white.withValues(alpha: 0.8),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryBlack,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Effects/Filters
          GestureDetector(
            onTap: () {
              // Open effects
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentOrange.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.auto_fix_high, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 120,
      left: 0,
      right: 0,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_modes.length, (index) {
            final isSelected = _selectedMode == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMode = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppTheme.primaryGradient : null,
                  color: isSelected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected ? null : Border.all(color: Colors.white24),
                ),
                child: Text(
                  _modes[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class PreviewPage extends StatefulWidget {
  final String mediaPath;

  const PreviewPage({super.key, required this.mediaPath});

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  bool _isSaving = false;

  Future<void> _saveMedia() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    bool success = await MediaService.saveImageToGallery(
      context,
      widget.mediaPath,
    );

    setState(() {
      _isSaving = false;
    });

    if (success) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: Stack(
        children: [
          // Media preview
          Positioned.fill(
            child: Container(
              color: AppTheme.primaryBlack,
              child: Center(
                child: Image.file(File(widget.mediaPath), fit: BoxFit.contain),
              ),
            ),
          ),

          // Top bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: GlassmorphicContainer(
                    width: 44,
                    height: 44,
                    borderRadius: BorderRadius.circular(22),
                    child: Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
                GestureDetector(
                  onTap: _isSaving ? null : _saveMedia,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: _isSaving
                          ? LinearGradient(
                              colors: [Colors.grey, Colors.grey.shade600],
                            )
                          : AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isSaving) ...[
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          _isSaving ? 'Saving...' : 'Save',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom action buttons
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 32,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.edit,
                  label: 'Edit',
                  onTap: () {
                    // TODO: Implement edit functionality
                  },
                ),
                _buildActionButton(
                  icon: Icons.share,
                  label: 'Share',
                  onTap: () async {
                    await ShareService.shareMediaFile(
                      filePath: widget.mediaPath,
                      caption: 'Check out my AR graffiti creation!',
                    );
                  },
                ),
                _buildActionButton(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  onTap: () {
                    MediaService.deleteTempFile(widget.mediaPath);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlassmorphicContainer(
            width: 56,
            height: 56,
            borderRadius: BorderRadius.circular(28),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
