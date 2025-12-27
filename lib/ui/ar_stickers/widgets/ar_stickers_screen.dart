import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import '../../../core/theme/app_theme.dart';
import '../view_model/ar_sticker_view_model.dart';
import '../../../core/services/ar_service.dart';
import 'ar_sticker_panel.dart';
import 'ar_controls_overlay.dart';

class ARStickersScreen extends StatefulWidget {
  const ARStickersScreen({super.key});

  @override
  State<ARStickersScreen> createState() => _ARStickersScreenState();
}

class _ARStickersScreenState extends State<ARStickersScreen> {
  ArCoreController? _arCoreController;
  late ARStickerViewModel _viewModel;
  bool _isARInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _viewModel = ARStickerViewModel();
    _initializeAR();
  }

  @override
  void dispose() {
    _arCoreController?.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _initializeAR() async {
    try {
      // Check if ARCore is available
      final isAvailable = await ArCoreController.checkArCoreAvailability();
      if (!isAvailable) {
        setState(() {
          _errorMessage = 'ARCore is not available on this device';
        });
        return;
      }

      // Check if ARCore is installed
      final isInstalled = await ArCoreController.checkIsArCoreInstalled();
      if (!isInstalled) {
        setState(() {
          _errorMessage =
              'ARCore is not installed. Please install ARCore from Google Play Store';
        });
        return;
      }

      setState(() {
        _isARInitialized = true;
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

      // Initialize AR service
      final success = await ARService().initialize(controller);
      if (!success) {
        setState(() {
          _errorMessage = 'Failed to initialize AR service';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'AR initialization failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: AppTheme.primaryBlack,
        body: _buildBody(),
      ),
    );
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
        // AR Camera View
        Positioned.fill(
          child: Builder(
            builder: (context) {
              try {
                return ArCoreView(
                  onArCoreViewCreated: _onARViewCreated,
                  enableTapRecognizer: true,
                );
              } catch (e) {
                // If ArCoreView fails to initialize, show error
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _errorMessage = 'ARCore not supported on this device: $e';
                    });
                  }
                });
                return Container(
                  color: AppTheme.primaryBlack,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.accentOrange,
                      ),
                    ),
                  ),
                );
              }
            },
          ),
        ),

        // AR Controls Overlay
        Consumer<ARStickerViewModel>(
          builder: (context, viewModel, child) {
            return ARControlsOverlay(
              viewModel: viewModel,
              onClose: () => Navigator.pop(context),
            );
          },
        ),

        // Sticker Panel
        Consumer<ARStickerViewModel>(
          builder: (context, viewModel, child) {
            return ARStickerPanel(viewModel: viewModel);
          },
        ),

        // Gesture detector for AR interactions
        Positioned.fill(
          child: Consumer<ARStickerViewModel>(
            builder: (context, viewModel, child) {
              return GestureDetector(
                onTapDown: viewModel.onTapDown,
                onTapUp: viewModel.onTap,
                // Use only scale gestures (includes pan functionality)
                onScaleStart: viewModel.onScaleStart,
                onScaleUpdate: viewModel.onScaleUpdate,
                onScaleEnd: viewModel.onScaleEnd,
                child: Container(color: Colors.transparent),
              );
            },
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
              'Initializing AR...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Please wait while we set up the camera',
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
                _errorMessage!,
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
