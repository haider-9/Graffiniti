import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import '../main.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/glassmorphic_container.dart';
import 'ar_graffiti_page.dart';

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
  bool _isRecording = false;

  late AnimationController _captureAnimationController;
  late AnimationController _modeAnimationController;

  int _selectedMode = 1; // 0: Photo, 1: AR Graffiti, 2: Video
  final List<String> _modes = ['Photo', 'AR Graffiti', 'Video'];

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
    _initializeCamera();
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
      ResolutionPreset.high,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller!.initialize();
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
        _showImagePreview(image.path);
      } else if (_selectedMode == 2) {
        // Video mode
        if (_isRecording) {
          final video = await _controller!.stopVideoRecording();
          _showVideoPreview(video.path);
          setState(() => _isRecording = false);
        } else {
          await _controller!.startVideoRecording();
          setState(() => _isRecording = true);
        }
      }
    } catch (e) {
      print('Error capturing: $e');
    }
  }

  void _showImagePreview(String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreviewPage(mediaPath: imagePath, isVideo: false),
      ),
    );
  }

  void _showVideoPreview(String videoPath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreviewPage(mediaPath: videoPath, isVideo: true),
      ),
    );
  }

  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
    _controller?.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
  }

  void _switchCamera() async {
    setState(() {
      _isRearCamera = !_isRearCamera;
    });
    await _controller?.dispose();
    _initializeCamera();
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
                // Camera preview
                Positioned.fill(
                  child: ClipRRect(
                    child: OverflowBox(
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.fitHeight,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height:
                              MediaQuery.of(context).size.width *
                              _controller!.value.aspectRatio,
                          child: CameraPreview(_controller!),
                        ),
                      ),
                    ),
                  ),
                ),

                // Top overlay with controls
                _buildTopOverlay(),

                // Side tools (left)
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
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Flash toggle
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
          ),
          // Settings
          GestureDetector(
            onTap: () {
              // Settings action
            },
            child: GlassmorphicContainer(
              width: 44,
              height: 44,
              borderRadius: BorderRadius.circular(22),
              child: const Icon(Icons.tune, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideTools() {
    return Positioned(
      right: 16,
      top: MediaQuery.of(context).size.height * 0.3,
      child: Column(
        children: [
          // Switch camera
          GestureDetector(
            onTap: _switchCamera,
            child: GlassmorphicContainer(
              width: 50,
              height: 50,
              borderRadius: BorderRadius.circular(25),
              child: const Icon(
                Icons.flip_camera_ios,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // AR mode indicator
          if (_selectedMode == 1)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentOrange.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.view_in_ar,
                color: Colors.white,
                size: 24,
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
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.lightGray,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: const Icon(
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
                      gradient: _selectedMode == 1
                          ? AppTheme.accentGradient
                          : LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.white.withValues(alpha: 0.8),
                              ],
                            ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (_selectedMode == 1
                                      ? AppTheme.accentOrange
                                      : Colors.white)
                                  .withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRecording
                            ? Colors.red
                            : (_selectedMode == 1
                                  ? Colors.white
                                  : AppTheme.primaryBlack),
                      ),
                      child: _selectedMode == 1
                          ? const Icon(
                              Icons.brush,
                              color: AppTheme.accentOrange,
                              size: 32,
                            )
                          : _isRecording
                          ? const Icon(
                              Icons.stop,
                              color: Colors.white,
                              size: 32,
                            )
                          : null,
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
              child: const Icon(
                Icons.auto_fix_high,
                color: Colors.white,
                size: 24,
              ),
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
      child: Container(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _modes.length,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          itemBuilder: (context, index) {
            final isSelected = _selectedMode == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMode = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
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
          },
        ),
      ),
    );
  }
}

class PreviewPage extends StatelessWidget {
  final String mediaPath;
  final bool isVideo;

  const PreviewPage({
    super.key,
    required this.mediaPath,
    required this.isVideo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: Stack(
        children: [
          // Media preview
          Positioned.fill(
            child: isVideo
                ? const Center(
                    child: Text(
                      'Video Preview',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : Image.file(File(mediaPath), fit: BoxFit.cover),
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
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // Save media
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
