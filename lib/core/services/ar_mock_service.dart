import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import '../../models/ar_sticker.dart';

// Mock AR service for demonstration purposes
// In production, this would be replaced with actual AR Flutter Plugin integration

class MockARController {
  static Future<bool> checkArCoreAvailability() async {
    // Simulate ARCore availability check
    await Future.delayed(const Duration(milliseconds: 500));
    return true; // Mock: always available
  }

  static Future<bool> checkIsArCoreInstalled() async {
    // Simulate ARCore installation check
    await Future.delayed(const Duration(milliseconds: 300));
    return true; // Mock: always installed
  }

  void dispose() {
    // Mock disposal
  }
}

class MockARView extends StatelessWidget {
  final Function(MockARController)? onArCoreViewCreated;
  final bool enableTapRecognizer;
  final bool enablePanRecognizer;
  final bool enableRotationRecognizer;
  final bool enableScaleRecognizer;

  const MockARView({
    super.key,
    this.onArCoreViewCreated,
    this.enableTapRecognizer = false,
    this.enablePanRecognizer = false,
    this.enableRotationRecognizer = false,
    this.enableScaleRecognizer = false,
  });

  @override
  Widget build(BuildContext context) {
    // Simulate AR view creation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onArCoreViewCreated?.call(MockARController());
    });

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1a1a1a), Color(0xFF2d2d2d)],
        ),
      ),
      child: Stack(
        children: [
          // Mock camera feed
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [
                    Colors.grey.withValues(alpha: 0.1),
                    Colors.grey.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
          ),

          // Mock plane detection visualization
          _buildMockPlanes(),

          // Mock AR content overlay
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.view_in_ar,
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'AR Camera View',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mock implementation for demonstration',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockPlanes() {
    return Stack(
      children: [
        // Mock horizontal plane
        Positioned(
          bottom: 100,
          left: 50,
          right: 50,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),

        // Mock vertical plane
        Positioned(
          top: 150,
          right: 30,
          bottom: 200,
          child: Container(
            width: 2,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.4),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.2),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ARService {
  static final ARService _instance = ARService._internal();
  factory ARService() => _instance;
  ARService._internal();

  final Map<String, ARSticker> _stickers = {};
  final StreamController<List<ARSticker>> _stickersController =
      StreamController<List<ARSticker>>.broadcast();
  final StreamController<bool> _trackingStateController =
      StreamController<bool>.broadcast();
  final StreamController<List<MockPlane>> _planesController =
      StreamController<List<MockPlane>>.broadcast();

  bool _isInitialized = false;
  bool _isTrackingEnabled = true;
  final List<MockPlane> _detectedPlanes = [];

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isTrackingEnabled => _isTrackingEnabled;
  List<ARSticker> get stickers => _stickers.values.toList();
  Stream<List<ARSticker>> get stickersStream => _stickersController.stream;
  Stream<bool> get trackingStateStream => _trackingStateController.stream;
  Stream<List<MockPlane>> get planesStream => _planesController.stream;

  Future<bool> initialize(MockARController controller) async {
    try {
      // Store controller reference if needed for future use

      // Simulate initialization
      await Future.delayed(const Duration(milliseconds: 1000));

      // Mock plane detection
      _detectedPlanes.addAll([
        MockPlane(id: 'plane_1', type: PlaneType.horizontal),
        MockPlane(id: 'plane_2', type: PlaneType.vertical),
      ]);

      _isInitialized = true;
      _trackingStateController.add(true);
      _planesController.add(_detectedPlanes);

      // Simulate tracking state changes
      _simulateTrackingChanges();

      return true;
    } catch (e) {
      debugPrint('Mock AR Service initialization failed: $e');
      return false;
    }
  }

  void _simulateTrackingChanges() {
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!_isInitialized) {
        timer.cancel();
        return;
      }

      // Occasionally simulate tracking loss/recovery
      if (Random().nextDouble() < 0.1) {
        _isTrackingEnabled = false;
        _trackingStateController.add(false);

        // Recover after 2 seconds
        Timer(const Duration(seconds: 2), () {
          _isTrackingEnabled = true;
          _trackingStateController.add(true);
        });
      }
    });
  }

  Future<String?> addSticker(
    ARSticker sticker,
    vector.Vector3 worldPosition,
  ) async {
    if (!_isInitialized) return null;

    try {
      // Simulate adding sticker to AR scene
      await Future.delayed(const Duration(milliseconds: 200));

      final updatedSticker = sticker.copyWith(
        position: worldPosition,
        state: StickerState.locked,
      );

      _stickers[sticker.id] = updatedSticker;
      _stickersController.add(stickers);

      debugPrint(
        'Mock: Added sticker ${sticker.id} at position $worldPosition',
      );
      return sticker.id;
    } catch (e) {
      debugPrint('Failed to add mock sticker: $e');
      return null;
    }
  }

  Future<bool> updateStickerTransform(
    String stickerId,
    vector.Vector3? position,
    vector.Vector3? rotation,
    vector.Vector3? scale,
  ) async {
    if (!_stickers.containsKey(stickerId)) return false;

    try {
      final sticker = _stickers[stickerId]!;
      final updatedSticker = sticker.copyWith(
        position: position ?? sticker.position,
        rotation: rotation ?? sticker.rotation,
        scale: scale ?? sticker.scale,
      );

      _stickers[stickerId] = updatedSticker;
      _stickersController.add(stickers);

      debugPrint('Mock: Updated sticker $stickerId transform');
      return true;
    } catch (e) {
      debugPrint('Failed to update mock sticker transform: $e');
      return false;
    }
  }

  Future<bool> removeSticker(String stickerId) async {
    if (!_stickers.containsKey(stickerId)) return false;

    try {
      _stickers.remove(stickerId);
      _stickersController.add(stickers);

      debugPrint('Mock: Removed sticker $stickerId');
      return true;
    } catch (e) {
      debugPrint('Failed to remove mock sticker: $e');
      return false;
    }
  }

  Future<void> clearAllStickers() async {
    try {
      _stickers.clear();
      _stickersController.add(stickers);

      debugPrint('Mock: Cleared all stickers');
    } catch (e) {
      debugPrint('Failed to clear mock stickers: $e');
    }
  }

  vector.Vector3? hitTestPlane(Offset screenPosition) {
    if (_detectedPlanes.isEmpty) return null;

    // Mock hit test - return a position based on screen coordinates
    final random = Random();
    return vector.Vector3(
      (screenPosition.dx / 500 - 1.0) + (random.nextDouble() - 0.5) * 0.1,
      0.0,
      (screenPosition.dy / 500 - 1.0) + (random.nextDouble() - 0.5) * 0.1,
    );
  }

  Future<List<Map<String, dynamic>>> exportStickers() async {
    return stickers.map((sticker) => sticker.toJson()).toList();
  }

  Future<void> importStickers(List<Map<String, dynamic>> stickerData) async {
    for (final data in stickerData) {
      try {
        final sticker = ARSticker.fromJson(data);
        await addSticker(sticker, sticker.position);
      } catch (e) {
        debugPrint('Failed to import mock sticker: $e');
      }
    }
  }

  void dispose() {
    _stickersController.close();
    _trackingStateController.close();
    _planesController.close();
    _stickers.clear();
    _detectedPlanes.clear();
    _isInitialized = false;
  }
}

class MockPlane {
  final String id;
  final PlaneType type;

  MockPlane({required this.id, required this.type});
}

enum PlaneType { horizontal, vertical }
