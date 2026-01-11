import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import '../../models/ar_sticker.dart';

class ARService {
  static final ARService _instance = ARService._internal();
  factory ARService() => _instance;
  ARService._internal();

  ArCoreController? _arCoreController;

  final Map<String, ARSticker> _stickers = {};
  final Map<String, ArCoreNode> _nodes = {};
  final Map<String, Uint8List> _loadedAssets = {}; // Cache for loaded assets

  final StreamController<List<ARSticker>> _stickersController =
      StreamController<List<ARSticker>>.broadcast();
  final StreamController<bool> _trackingStateController =
      StreamController<bool>.broadcast();

  bool _isInitialized = false;
  final bool _isTrackingEnabled = true;

  // Asset paths for spray icons
  static const String sprayIcon1Path = 'assets/icons/spray.png';
  static const String sprayIcon2Path = 'assets/icons/spray-2.png';

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isTrackingEnabled => _isTrackingEnabled;
  List<ARSticker> get stickers => _stickers.values.toList();
  Stream<List<ARSticker>> get stickersStream => _stickersController.stream;
  Stream<bool> get trackingStateStream => _trackingStateController.stream;

  Future<bool> initialize(ArCoreController controller) async {
    try {
      _arCoreController = controller;

      // Configure AR session
      await _configureSession();

      // Preload spray icon assets
      await _preloadAssets();

      _isInitialized = true;
      _trackingStateController.add(true);

      return true;
    } catch (e) {
      debugPrint('AR Service initialization failed: $e');
      return false;
    }
  }

  /// Preload commonly used assets for better performance
  Future<void> _preloadAssets() async {
    try {
      // Load spray icons
      await loadAsset(sprayIcon1Path);
      await loadAsset(sprayIcon2Path);

      debugPrint('Successfully preloaded ${_loadedAssets.length} assets');
    } catch (e) {
      debugPrint('Failed to preload assets: $e');
    }
  }

  /// Load an asset from the assets folder and cache it
  Future<Uint8List?> loadAsset(String assetPath) async {
    try {
      // Check if already cached
      if (_loadedAssets.containsKey(assetPath)) {
        return _loadedAssets[assetPath];
      }

      // Load the asset
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();

      // Cache it
      _loadedAssets[assetPath] = bytes;

      debugPrint('Loaded asset: $assetPath (${bytes.length} bytes)');
      return bytes;
    } catch (e) {
      debugPrint('Failed to load asset $assetPath: $e');
      return null;
    }
  }

  /// Get spray icon 1 bytes
  Future<Uint8List?> getSprayIcon1() async {
    return await loadAsset(sprayIcon1Path);
  }

  /// Get spray icon 2 bytes
  Future<Uint8List?> getSprayIcon2() async {
    return await loadAsset(sprayIcon2Path);
  }

  /// Create a spray sticker with the specified icon
  Future<ARSticker?> createSpraySticker({
    required int iconNumber, // 1 or 2
    double size = 0.2,
    double opacity = 1.0,
  }) async {
    final String assetPath = iconNumber == 1 ? sprayIcon1Path : sprayIcon2Path;
    final Uint8List? imageBytes = await loadAsset(assetPath);

    if (imageBytes == null) {
      debugPrint('Failed to load spray icon $iconNumber');
      return null;
    }

    return ARSticker(
      id: 'spray_${DateTime.now().millisecondsSinceEpoch}',
      type: StickerType.image,
      content: assetPath,
      position: vector.Vector3.zero(),
      properties: {
        'size': size,
        'opacity': opacity,
        'imageBytes': imageBytes,
        'assetPath': assetPath,
      },
    );
  }

  Future<void> _configureSession() async {
    if (_arCoreController == null) return;

    try {
      // Enable plane detection (if method exists)
      // Note: enablePlaneRenderer might not be available in all versions
      // await _arCoreController!.enablePlaneRenderer(true);

      // Set up tracking state monitoring
      _setupTrackingStateMonitoring();

      debugPrint('AR session configured successfully');
    } catch (e) {
      debugPrint('Failed to configure AR session: $e');
    }
  }

  void _setupTrackingStateMonitoring() {
    // Monitor AR session state
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isInitialized) {
        timer.cancel();
        return;
      }

      // Check actual AR tracking state
      _trackingStateController.add(_isTrackingEnabled);
    });
  }

  Future<String?> addSticker(
    ARSticker sticker,
    vector.Vector3 worldPosition,
  ) async {
    debugPrint('Adding sticker: ${sticker.id} at position: $worldPosition');

    if (!_isInitialized || _arCoreController == null) {
      debugPrint('AR Service not initialized or controller is null');
      return null;
    }

    try {
      // Create AR node for the sticker
      final node = _createNodeForSticker(sticker, worldPosition);
      if (node != null) {
        debugPrint('Created AR node for sticker: ${sticker.id}');

        // Add node to AR scene
        await _arCoreController!.addArCoreNode(node);
        debugPrint('Successfully added AR node to scene');

        // Store sticker and references
        final updatedSticker = sticker.copyWith(
          position: worldPosition,
          state: StickerState.locked,
        );

        _stickers[sticker.id] = updatedSticker;
        _nodes[sticker.id] = node;

        _stickersController.add(stickers);
        debugPrint('Sticker added successfully: ${sticker.id}');
        return sticker.id;
      } else {
        debugPrint('Failed to create AR node for sticker: ${sticker.id}');
      }

      return null;
    } catch (e) {
      debugPrint('Failed to add sticker: $e');
      return null;
    }
  }

  ArCoreNode? _createNodeForSticker(
    ARSticker sticker,
    vector.Vector3 position,
  ) {
    switch (sticker.type) {
      case StickerType.emoji:
        return _createEmojiNode(sticker, position);
      case StickerType.text:
        return _createTextNode(sticker, position);
      case StickerType.shape:
        return _createShapeNode(sticker, position);
      case StickerType.image:
        return _createImageNode(sticker, position);
    }
  }

  ArCoreNode _createEmojiNode(ARSticker sticker, vector.Vector3 position) {
    // For emojis, create a plane with the emoji as texture
    // Since ARCore doesn't directly support text rendering, we'll create a simple colored cube for now
    // In a production app, you'd render the emoji to a texture first

    final fontSize = sticker.properties['fontSize'] as double? ?? 48.0;
    final size = fontSize / 100.0; // Convert font size to world scale

    return ArCoreNode(
      name: sticker.id,
      shape: ArCoreCube(
        size: vector.Vector3(size, size, 0.01), // Very thin cube like a plane
        materials: [
          ArCoreMaterial(
            color: Colors.white,
            // Note: In a real implementation, you'd render the emoji to a texture
            // and use textureBytes here
          ),
        ],
      ),
      position: position,
      rotation: vector.Vector4(0, 0, 0, 1),
    );
  }

  ArCoreNode _createTextNode(ARSticker sticker, vector.Vector3 position) {
    // For text, create a colored cube with the text color
    final color = sticker.properties['color'] as int? ?? 0xFFFFFFFF;
    final fontSize = sticker.properties['fontSize'] as double? ?? 24.0;
    final size = fontSize / 100.0; // Convert font size to world scale

    return ArCoreNode(
      name: sticker.id,
      shape: ArCoreCube(
        size: vector.Vector3(size * 2, size, 0.02), // Wider for text
        materials: [ArCoreMaterial(color: Color(color))],
      ),
      position: position,
      rotation: vector.Vector4(0, 0, 0, 1),
    );
  }

  ArCoreNode _createShapeNode(ARSticker sticker, vector.Vector3 position) {
    switch (sticker.content) {
      case 'circle':
        return ArCoreNode(
          name: sticker.id,
          shape: ArCoreSphere(
            radius: 0.05,
            materials: [ArCoreMaterial(color: Colors.orange)],
          ),
          position: position,
          rotation: vector.Vector4(0, 0, 0, 1),
        );
      case 'square':
        return ArCoreNode(
          name: sticker.id,
          shape: ArCoreCube(
            size: vector.Vector3.all(0.1),
            materials: [ArCoreMaterial(color: Colors.orange)],
          ),
          position: position,
          rotation: vector.Vector4(0, 0, 0, 1),
        );
      case 'triangle':
        return ArCoreNode(
          name: sticker.id,
          shape: ArCoreCylinder(
            radius: 0.05,
            height: 0.1,
            materials: [ArCoreMaterial(color: Colors.orange)],
          ),
          position: position,
          rotation: vector.Vector4(0, 0, 0, 1),
        );
      default:
        return ArCoreNode(
          name: sticker.id,
          shape: ArCoreSphere(
            radius: 0.05,
            materials: [ArCoreMaterial(color: Colors.orange)],
          ),
          position: position,
          rotation: vector.Vector4(0, 0, 0, 1),
        );
    }
  }

  ArCoreNode _createImageNode(ARSticker sticker, vector.Vector3 position) {
    // Create a thin cube to display the PNG image (simulating a plane)
    final size = sticker.properties['size'] as double? ?? 0.2;
    final opacity = sticker.properties['opacity'] as double? ?? 1.0;
    final imageBytes = sticker.properties['imageBytes'] as Uint8List?;

    debugPrint(
      'Creating image node for ${sticker.id} with size: $size, has imageBytes: ${imageBytes != null}',
    );

    // Create material with texture if image bytes are available
    ArCoreMaterial material;
    if (imageBytes != null) {
      material = ArCoreMaterial(
        color: Colors.white.withValues(alpha: opacity),
        textureBytes: imageBytes,
      );
      debugPrint(
        'Created material with texture bytes (${imageBytes.length} bytes)',
      );
    } else {
      // Fallback to colored material with a distinct color to show it's working
      material = ArCoreMaterial(
        color: Colors.orange.withValues(alpha: opacity),
      );
      debugPrint('Created fallback orange material (no image bytes available)');
    }

    return ArCoreNode(
      name: sticker.id,
      shape: ArCoreCube(
        size: vector.Vector3(
          size,
          size,
          0.01,
        ), // Very thin cube to simulate plane
        materials: [material],
      ),
      position: position,
      rotation: vector.Vector4(0, 0, 0, 1),
    );
  }

  Future<bool> updateStickerTransform(
    String stickerId,
    vector.Vector3? position,
    vector.Vector3? rotation,
    vector.Vector3? scale,
  ) async {
    if (!_stickers.containsKey(stickerId) || _arCoreController == null) {
      return false;
    }

    try {
      // For arcore_flutter_plugin, we need to remove and re-add the node
      // with updated properties since nodes are immutable
      await _arCoreController!.removeNode(nodeName: stickerId);

      final sticker = _stickers[stickerId]!;
      final newPosition = position ?? sticker.position;

      // Create new node with updated transform
      final newNode = _createNodeForSticker(sticker, newPosition);
      if (newNode != null) {
        await _arCoreController!.addArCoreNode(newNode);
        _nodes[stickerId] = newNode;

        // Update local sticker data
        final updatedSticker = sticker.copyWith(
          position: newPosition,
          rotation: rotation ?? sticker.rotation,
          scale: scale ?? sticker.scale,
        );

        _stickers[stickerId] = updatedSticker;
        _stickersController.add(stickers);
      }

      return true;
    } catch (e) {
      debugPrint('Failed to update sticker transform: $e');
      return false;
    }
  }

  Future<bool> removeSticker(String stickerId) async {
    if (!_stickers.containsKey(stickerId) || _arCoreController == null) {
      return false;
    }

    try {
      // Remove from AR scene
      await _arCoreController!.removeNode(nodeName: stickerId);

      // Remove from local storage
      _stickers.remove(stickerId);
      _nodes.remove(stickerId);

      _stickersController.add(stickers);
      return true;
    } catch (e) {
      debugPrint('Failed to remove sticker: $e');
      return false;
    }
  }

  Future<void> clearAllStickers() async {
    if (_arCoreController == null) return;

    try {
      // Remove all nodes
      for (final stickerId in _stickers.keys) {
        await _arCoreController!.removeNode(nodeName: stickerId);
      }

      // Clear local storage
      _stickers.clear();
      _nodes.clear();

      _stickersController.add(stickers);
    } catch (e) {
      debugPrint('Failed to clear stickers: $e');
    }
  }

  vector.Vector3? hitTestPlane(Offset screenPosition) {
    if (_arCoreController == null) {
      debugPrint('AR Controller not initialized for hit testing');
      return null;
    }

    try {
      // Use more realistic screen dimensions for modern phones
      const double screenWidth = 1080.0; // Typical phone width in pixels
      const double screenHeight = 2280.0; // Typical phone height in pixels

      // Convert screen coordinates to normalized device coordinates [-1, 1]
      final double normalizedX = (screenPosition.dx / screenWidth) * 2.0 - 1.0;
      final double normalizedY =
          -((screenPosition.dy / screenHeight) * 2.0 - 1.0); // Invert Y

      // Create placement positions based on where user tapped
      vector.Vector3 worldPosition;

      // If user tapped in lower part of screen (floor/table)
      if (screenPosition.dy > screenHeight * 0.6) {
        // Floor placement - lower Y position
        worldPosition = vector.Vector3(
          normalizedX * 0.4,
          -0.5, // Below camera level (floor)
          -0.8, // Closer distance
        );
        debugPrint('Floor placement detected');
      }
      // If user tapped in upper part of screen (wall/ceiling)
      else if (screenPosition.dy < screenHeight * 0.4) {
        // Wall/ceiling placement - higher Y position
        worldPosition = vector.Vector3(
          normalizedX * 0.3,
          normalizedY * 0.4, // Higher up
          -1.2, // Further distance for walls
        );
        debugPrint('Wall placement detected');
      }
      // Middle area - table/surface level
      else {
        // Table/surface placement - camera level
        worldPosition = vector.Vector3(
          normalizedX * 0.3,
          normalizedY * 0.2, // Slightly below camera
          -1.0, // Standard distance
        );
        debugPrint('Surface placement detected');
      }

      debugPrint(
        'Hit test: screen($screenPosition) -> normalized($normalizedX, $normalizedY) -> world($worldPosition)',
      );

      return worldPosition;
    } catch (e) {
      debugPrint('Hit test failed: $e');
      return null;
    }
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
        debugPrint('Failed to import sticker: $e');
      }
    }
  }

  void dispose() {
    _stickersController.close();
    _trackingStateController.close();
    _stickers.clear();
    _nodes.clear();
    _loadedAssets.clear(); // Clear cached assets
    _isInitialized = false;
  }
}
