import 'package:flutter/material.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import '../core/services/ar_service.dart';
import '../widgets/spray_icon_selector.dart';
import '../models/ar_sticker.dart';

class SprayIconExample extends StatefulWidget {
  const SprayIconExample({super.key});

  @override
  State<SprayIconExample> createState() => _SprayIconExampleState();
}

class _SprayIconExampleState extends State<SprayIconExample> {
  ArCoreController? _arCoreController;
  final ARService _arService = ARService();
  bool _isInitialized = false;
  ARSticker? _selectedSticker;

  @override
  void dispose() {
    _arCoreController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spray Icon AR Demo'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // AR View
          ArCoreView(
            onArCoreViewCreated: _onArCoreViewCreated,
            enableTapRecognizer: true,
          ),

          // UI Overlay
          if (_isInitialized) ...[
            // Spray Icon Selector
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: SprayIconSelector(onStickerSelected: _onStickerSelected),
            ),

            // Instructions
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Select a spray icon below, then tap on a surface to place it',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Clear All Button
            Positioned(
              top: 100,
              right: 20,
              child: FloatingActionButton(
                mini: true,
                onPressed: _clearAllStickers,
                backgroundColor: Colors.red,
                child: const Icon(Icons.clear_all, color: Colors.white),
              ),
            ),
          ],

          // Loading indicator
          if (!_isInitialized)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Initializing AR...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _onArCoreViewCreated(ArCoreController controller) async {
    _arCoreController = controller;

    // Initialize AR service
    final success = await _arService.initialize(controller);

    if (success) {
      setState(() {
        _isInitialized = true;
      });

      // Set up tap listener
      controller.onPlaneTap = _onPlaneTapped;

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AR initialized successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to initialize AR'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _onStickerSelected(ARSticker sticker) {
    setState(() {
      _selectedSticker = sticker;
    });

    debugPrint('Selected sticker: ${sticker.content}');
  }

  void _onPlaneTapped(List<ArCoreHitTestResult> hits) async {
    if (_selectedSticker == null || hits.isEmpty) return;

    final hit = hits.first;
    final position = vector.Vector3(
      hit.pose.translation.x,
      hit.pose.translation.y,
      hit.pose.translation.z,
    );

    // Add the selected sticker at the tapped position
    final stickerId = await _arService.addSticker(_selectedSticker!, position);

    if (stickerId != null) {
      debugPrint('Added spray sticker at position: $position');

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Spray icon placed!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } else {
      debugPrint('Failed to add spray sticker');

      // Show error feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to place spray icon'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _clearAllStickers() async {
    await _arService.clearAllStickers();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All stickers cleared!'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
}
