import 'package:flutter/material.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:flutter_svg/flutter_svg.dart';
import '../core/services/ar_sphere_service.dart';
import '../core/theme/app_theme.dart';

class ARSpherePage extends StatefulWidget {
  const ARSpherePage({super.key});

  @override
  State<ARSpherePage> createState() => _ARSpherePageState();
}

class _ARSpherePageState extends State<ARSpherePage> {
  ArCoreController? _arCoreController;
  final ARSphereService _sphereService = ARSphereService();

  bool _isARInitialized = false;
  String? _errorMessage;
  String _statusMessage = 'Initializing AR...';
  List<String> _sphereIds = [];

  @override
  void initState() {
    super.initState();
    _initializeAR();
    _setupListeners();
  }

  @override
  void dispose() {
    _arCoreController?.dispose();
    _sphereService.dispose();
    super.dispose();
  }

  void _setupListeners() {
    // Listen to sphere updates
    _sphereService.spheresStream.listen((sphereIds) {
      if (mounted) {
        setState(() {
          _sphereIds = sphereIds;
        });
      }
    });

    // Listen to status updates
    _sphereService.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _statusMessage = status;
        });
      }
    });
  }

  Future<void> _initializeAR() async {
    try {
      // Check ARCore availability
      final isAvailable = await ArCoreController.checkArCoreAvailability();
      if (!isAvailable) {
        setState(() {
          _errorMessage = 'ARCore is not available on this device';
        });
        return;
      }

      // Check ARCore installation
      final isInstalled = await ArCoreController.checkIsArCoreInstalled();
      if (!isInstalled) {
        setState(() {
          _errorMessage =
              'ARCore is not installed. Please install from Google Play Store';
        });
        return;
      }

      setState(() {
        _isARInitialized = true;
        _statusMessage = 'AR ready. Tap on detected planes to place spheres.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize AR: $e';
      });
    }
  }

  void _onARViewCreated(ArCoreController controller) async {
    try {
      _arCoreController = controller;

      // Initialize sphere service with proper plane detection
      final success = await _sphereService.initialize(controller);
      if (!success) {
        setState(() {
          _errorMessage = 'Failed to initialize AR sphere service';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'AR initialization failed: $e';
      });
    }
  }

  void _createSphereAtCenter() async {
    // Create a sphere 1 meter in front of the camera
    final position = vector.Vector3(0, 0, -1);
    await _sphereService.createSphereAtPosition(position);
  }

  void _createCustomSphere() async {
    // Create a red sphere at a random position
    final position = vector.Vector3(
      (DateTime.now().millisecond % 100 - 50) / 100.0, // -0.5 to 0.5
      0,
      -1.5,
    );

    await _sphereService.createCustomSphere(
      worldPosition: position,
      color: Colors.red,
      radius: 0.15,
      metallic: 0.8,
      roughness: 0.1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppTheme.primaryBlack, body: _buildBody());
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return _buildErrorView();
    }

    if (!_isARInitialized) {
      return _buildLoadingView();
    }

    return Stack(
      children: [
        // AR Camera View with plane detection
        Positioned.fill(
          child: ArCoreView(
            onArCoreViewCreated: _onARViewCreated,
            enableTapRecognizer: true,
          ),
        ),

        // AR Reticle (center crosshair)
        Positioned.fill(
          child: Center(
            child: SvgPicture.asset(
              'assets/icons/ar_reticle.svg',
              width: 48,
              height: 48,
            ),
          ),
        ),

        // Status overlay
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AR Sphere Demo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _statusMessage,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  'Spheres placed: ${_sphereIds.length}',
                  style: TextStyle(
                    color: AppTheme.accentOrange,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Control buttons
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          left: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Instructions
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '💡 Tip: Move your device to detect planes (floors, tables, walls), then tap on them to place world-locked spheres!',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _createSphereAtCenter,
                      icon: Icon(Icons.add_circle_outline),
                      label: Text('Add Sphere'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _createCustomSphere,
                      icon: Icon(Icons.palette),
                      label: Text('Custom'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _sphereService.clearAllSpheres,
                      icon: Icon(Icons.clear_all),
                      label: Text('Clear'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Back button
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withOpacity(0.5),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentOrange),
            ),
            const SizedBox(height: 20),
            Text(
              'Initializing AR Sphere Demo...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Setting up camera and plane detection',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: AppTheme.accentRed),
              const SizedBox(height: 20),
              Text(
                'AR Not Available',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "This device does not support AR capabilities.",
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
