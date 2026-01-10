import 'dart:math';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import '../main.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/permission_helper.dart';
import '../core/services/media_service.dart';
import '../core/services/share_service.dart';
import 'ar_graffiti_page.dart';
import 'ar_demo_launcher.dart';

class CameraPageController {
  static _CameraPageState? _currentInstance;

  static void setPageVisible(bool isVisible) {
    if (isVisible) {
      _currentInstance?.onPageVisible();
    } else {
      _currentInstance?.onPageInvisible();
    }
  }

  static void registerInstance(_CameraPageState instance) {
    _currentInstance = instance;
  }

  static void unregisterInstance() {
    _currentInstance = null;
  }
}

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
    with
        WidgetsBindingObserver,
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isFlashOn = false;
  bool _isRearCamera = true;
  bool _isPageVisible =
      false; // Start as invisible since camera is not the default page

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
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    CameraPageController.registerInstance(this);
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
    // Initialize camera immediately on app load for faster access
    _initializeCamera();
  }

  // Method to be called when page becomes visible
  void onPageVisible() {
    _isPageVisible = true;
    // Only initialize if not already initialized
    if (_controller == null || !_controller!.value.isInitialized) {
      _initializeCamera();
    }
  }

  // Method to be called when page becomes invisible
  void onPageInvisible() {
    _isPageVisible = false;
    // Keep camera running for faster access when returning to camera page
    // Only dispose on app lifecycle changes or when explicitly needed
  }

  Future<void> _disposeCamera() async {
    await _controller?.dispose();
    _controller = null;
    _initializeControllerFuture = null;
    if (mounted) {
      setState(() {});
    }
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
    CameraPageController.unregisterInstance();
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _captureAnimationController.dispose();
    _modeAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    // Only handle lifecycle changes if camera is initialized
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    switch (state) {
      case AppLifecycleState.paused:
        // App is paused - dispose camera to free resources
        _disposeCamera();
        break;
      case AppLifecycleState.inactive:
        // App is inactive but still visible - keep camera running
        break;
      case AppLifecycleState.detached:
        // App is detached, dispose camera
        _disposeCamera();
        break;
      case AppLifecycleState.resumed:
        // App is resumed, reinitialize camera
        _initializeCamera();
        break;
      case AppLifecycleState.hidden:
        // App is hidden, dispose camera to free resources
        _disposeCamera();
        break;
    }
  }

  Future<void> _initializeCamera() async {
    if (cameras.isEmpty) return;

    // Dispose existing controller if it exists
    await _controller?.dispose();

    final camera = _isRearCamera ? cameras.first : cameras.last;
    _controller = CameraController(
      camera,
      ResolutionPreset.veryHigh,
      enableAudio: false, // Audio not needed without video mode
      imageFormatGroup: ImageFormatGroup.jpeg, // Ensure consistent format
    );

    try {
      _initializeControllerFuture = _controller!.initialize().then((_) async {
        if (!mounted) return;

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
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      // Show error to user only if page is visible
      if (mounted && _isPageVisible) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Camera initialization failed. Please try again.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppTheme.primaryBlack,
            duration: Duration(seconds: 3),
          ),
        );
      }
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
            content: Text(
              'Flash not available on this camera',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppTheme.primaryBlack,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _switchCamera() async {
    if (_controller == null) return;

    // Show loading indicator during switch
    setState(() {
      _controller = null;
      _initializeControllerFuture = null;
    });

    // Switch camera state
    setState(() {
      _isRearCamera = !_isRearCamera;
      // Turn off flash when switching to front camera (usually no flash)
      if (!_isRearCamera) {
        _isFlashOn = false;
      }
    });

    // Small delay to ensure smooth transition
    await Future.delayed(const Duration(milliseconds: 100));

    // Initialize new camera
    await _initializeCamera();
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
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryBlack.withValues(alpha: 0.95),
              AppTheme.primaryBlack,
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Row(
              children: [
                Icon(Icons.settings, color: AppTheme.accentOrange, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Camera Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Aspect Ratio Section
            Row(
              children: [
                Icon(
                  Icons.crop,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Aspect Ratio',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

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
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppTheme.accentGradient : null,
                        color: isSelected
                            ? null
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.accentOrange.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.accentOrange.withValues(
                                    alpha: 0.2,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            option.icon,
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.7),
                            size: 28,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            option.label,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
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
              child: Stack(
                children: [
                  // Professional loading background
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.primaryBlack,
                            AppTheme.primaryBlack.withValues(alpha: 0.8),
                            AppTheme.primaryBlack,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Animated camera icon
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppTheme.primaryGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.accentOrange.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.camera_alt_outlined,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Loading indicator
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.accentOrange,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Loading text
                            Text(
                              'Initializing Camera...',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Top controls (still visible during loading)
                  _buildTopOverlay(),
                ],
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
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _isFlashOn
                      ? AppTheme.accentOrange.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _isFlashOn
                        ? AppTheme.accentOrange.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  color: _isFlashOn ? AppTheme.accentOrange : Colors.white,
                  size: 22,
                ),
              ),
            )
          else
            // Placeholder to maintain layout
            SizedBox(width: 48, height: 48),

          // Settings
          GestureDetector(
            onTap: _showSettingsMenu,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.tune, color: Colors.white, size: 22),
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
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.withValues(alpha: 0.9),
                    Colors.blue.withValues(alpha: 0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.view_in_ar_outlined,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Direct AR Graffiti button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ARGraffitiPage()),
              );
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentOrange.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.view_in_ar, color: Colors.white, size: 26),
            ),
          ),
          const SizedBox(height: 16),

          // Switch camera
          GestureDetector(
            onTap: _switchCamera,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.flip_camera_ios, color: Colors.white, size: 26),
            ),
          ),
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
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.photo_library_outlined,
                color: Colors.white,
                size: 26,
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
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          Colors.white.withValues(alpha: 0.9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(6),
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
            child: SizedBox(width: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 130,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
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
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppTheme.primaryGradient : null,
                    color: isSelected ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.accentOrange.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    _modes[index],
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.7),
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }),
          ),
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
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(Icons.close, color: Colors.white, size: 22),
                  ),
                ),
                GestureDetector(
                  onTap: _isSaving ? null : _saveMedia,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: _isSaving
                          ? LinearGradient(
                              colors: [
                                Colors.grey.withValues(alpha: 0.6),
                                Colors.grey.withValues(alpha: 0.8),
                              ],
                            )
                          : AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isSaving
                              ? Colors.black.withValues(alpha: 0.2)
                              : AppTheme.accentOrange.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
                            fontSize: 15,
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
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
