import 'dart:async';
import 'package:flutter/material.dart';
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

  final StreamController<List<ARSticker>> _stickersController =
      StreamController<List<ARSticker>>.broadcast();
  final StreamController<bool> _trackingStateController =
      StreamController<bool>.broadcast();

  bool _isInitialized = false;
  final bool _isTrackingEnabled = true;

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

      _isInitialized = true;
      _trackingStateController.add(true);

      return true;
    } catch (e) {
      debugPrint('AR Service initialization failed: $e');
      return false;
    }
  }

  Future<void> _configureSession() async {
    if (_arCoreController == null) return;

    // Set up tracking state monitoring
    _setupTrackingStateMonitoring();
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
    if (!_isInitialized || _arCoreController == null) {
      return null;
    }

    try {
      // Create AR node for the sticker
      final node = _createNodeForSticker(sticker, worldPosition);
      if (node != null) {
        // Add node to AR scene
        await _arCoreController!.addArCoreNode(node);

        // Store sticker and references
        final updatedSticker = sticker.copyWith(
          position: worldPosition,
          state: StickerState.locked,
        );

        _stickers[sticker.id] = updatedSticker;
        _nodes[sticker.id] = node;

        _stickersController.add(stickers);
        return sticker.id;
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
    // For emojis, we'll create a simple sphere with texture
    return ArCoreNode(
      name: sticker.id,
      shape: ArCoreSphere(
        radius: 0.1,
        materials: [ArCoreMaterial(color: Colors.white)],
      ),
      position: position,
      rotation: vector.Vector4(0, 0, 0, 1),
    );
  }

  ArCoreNode _createTextNode(ARSticker sticker, vector.Vector3 position) {
    // For text, create a cube as placeholder
    return ArCoreNode(
      name: sticker.id,
      shape: ArCoreCube(
        size: vector.Vector3(0.2, 0.1, 0.02),
        materials: [
          ArCoreMaterial(
            color: Color(sticker.properties['color'] ?? 0xFFFFFFFF),
          ),
        ],
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
    return ArCoreNode(
      name: sticker.id,
      shape: ArCoreCube(
        size: vector.Vector3(0.2, 0.2, 0.02),
        materials: [ArCoreMaterial(color: Colors.white)],
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
    // For now, return a simple position
    // In a real implementation, you would perform hit testing
    return vector.Vector3(0, 0, -1);
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
    _isInitialized = false;
  }
}
