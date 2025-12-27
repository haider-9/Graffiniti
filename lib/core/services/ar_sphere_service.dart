import 'dart:async';
import 'package:flutter/material.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class ARSphereService {
  static final ARSphereService _instance = ARSphereService._internal();
  factory ARSphereService() => _instance;
  ARSphereService._internal();

  ArCoreController? _arCoreController;
  final Map<String, ArCoreNode> _sphereNodes = {};

  bool _isInitialized = false;
  int _sphereCounter = 0;

  // Stream controllers for updates
  final StreamController<List<String>> _spheresController =
      StreamController<List<String>>.broadcast();
  final StreamController<String> _statusController =
      StreamController<String>.broadcast();

  // Getters
  bool get isInitialized => _isInitialized;
  List<String> get sphereIds => _sphereNodes.keys.toList();
  Stream<List<String>> get spheresStream => _spheresController.stream;
  Stream<String> get statusStream => _statusController.stream;

  /// Initialize the AR sphere service with proper plane detection
  Future<bool> initialize(ArCoreController controller) async {
    try {
      _arCoreController = controller;

      // Set up plane tap handler for creating world-locked spheres
      _arCoreController!.onPlaneTap = _handlePlaneTap;

      _isInitialized = true;
      _statusController.add(
        'AR Sphere Service initialized. Tap on detected planes to place spheres.',
      );

      return true;
    } catch (e) {
      debugPrint('AR Sphere Service initialization failed: $e');
      _statusController.add('Failed to initialize: $e');
      return false;
    }
  }

  /// Handle plane tap to create world-locked sphere
  void _handlePlaneTap(List<ArCoreHitTestResult> hits) async {
    if (hits.isEmpty || _arCoreController == null) return;

    try {
      final hit = hits.first;

      // Create sphere at the hit position - this position is world-stable!
      final sphereId = await _createSphereAtPosition(hit.pose.translation);

      if (sphereId != null) {
        _statusController.add(
          'Sphere placed! It will stay locked to this real-world location.',
        );
        _spheresController.add(sphereIds);
      }
    } catch (e) {
      debugPrint('Failed to handle plane tap: $e');
      _statusController.add('Failed to place sphere: $e');
    }
  }

  /// Create a sphere at a specific world position
  Future<String?> _createSphereAtPosition(vector.Vector3 worldPosition) async {
    if (_arCoreController == null) return null;

    try {
      _sphereCounter++;
      final sphereId = 'sphere_$_sphereCounter';

      // Create material with a nice gradient-like color
      final material = ArCoreMaterial(
        color: Color.fromARGB(255, 66, 134, 244), // Nice blue color
        metallic: 0.2,
        roughness: 0.3,
      );

      // Create sphere shape - 10cm radius
      final sphere = ArCoreSphere(radius: 0.1, materials: [material]);

      // Create node at the world position
      final node = ArCoreNode(
        name: sphereId,
        shape: sphere,
        position: worldPosition, // World position from hit test
        rotation: vector.Vector4(0, 0, 0, 1),
      );

      // Add node to AR scene
      await _arCoreController!.addArCoreNode(node);

      // Store reference
      _sphereNodes[sphereId] = node;

      return sphereId;
    } catch (e) {
      debugPrint('Failed to create sphere at position: $e');
      return null;
    }
  }

  /// Create a sphere at a specific world position (public method)
  Future<String?> createSphereAtPosition(vector.Vector3 worldPosition) async {
    if (!_isInitialized || _arCoreController == null) return null;

    try {
      final sphereId = await _createSphereAtPosition(worldPosition);

      if (sphereId != null) {
        _spheresController.add(sphereIds);
        _statusController.add(
          'Sphere created at position: ${worldPosition.toString()}',
        );
      }

      return sphereId;
    } catch (e) {
      debugPrint('Failed to create sphere at position: $e');
      _statusController.add('Failed to create sphere: $e');
      return null;
    }
  }

  /// Create a colorful sphere with custom properties
  Future<String?> createCustomSphere({
    required vector.Vector3 worldPosition,
    Color color = Colors.blue,
    double radius = 0.1,
    double metallic = 0.2,
    double roughness = 0.3,
  }) async {
    if (!_isInitialized || _arCoreController == null) return null;

    try {
      _sphereCounter++;
      final sphereId = 'custom_sphere_$_sphereCounter';

      // Create custom material
      final material = ArCoreMaterial(
        color: color,
        metallic: metallic,
        roughness: roughness,
      );

      // Create custom sphere
      final sphere = ArCoreSphere(radius: radius, materials: [material]);

      // Create node
      final node = ArCoreNode(
        name: sphereId,
        shape: sphere,
        position: worldPosition,
        rotation: vector.Vector4(0, 0, 0, 1),
      );

      // Add to AR scene
      await _arCoreController!.addArCoreNode(node);

      // Store reference
      _sphereNodes[sphereId] = node;

      _spheresController.add(sphereIds);
      _statusController.add(
        'Custom sphere created with color: ${color.toString()}',
      );

      return sphereId;
    } catch (e) {
      debugPrint('Failed to create custom sphere: $e');
      _statusController.add('Failed to create custom sphere: $e');
      return null;
    }
  }

  /// Remove a specific sphere
  Future<bool> removeSphere(String sphereId) async {
    if (!_sphereNodes.containsKey(sphereId) || _arCoreController == null) {
      return false;
    }

    try {
      // Remove node from scene
      await _arCoreController!.removeNode(nodeName: sphereId);

      _sphereNodes.remove(sphereId);

      _spheresController.add(sphereIds);
      _statusController.add('Sphere removed: $sphereId');

      return true;
    } catch (e) {
      debugPrint('Failed to remove sphere: $e');
      _statusController.add('Failed to remove sphere: $e');
      return false;
    }
  }

  /// Remove all spheres
  Future<void> clearAllSpheres() async {
    if (_arCoreController == null) return;

    try {
      // Remove all sphere nodes
      for (final sphereId in _sphereNodes.keys) {
        await _arCoreController!.removeNode(nodeName: sphereId);
      }

      // Clear all references
      _sphereNodes.clear();

      _spheresController.add(sphereIds);
      _statusController.add('All spheres cleared');
    } catch (e) {
      debugPrint('Failed to clear spheres: $e');
      _statusController.add('Failed to clear spheres: $e');
    }
  }

  /// Get sphere count
  int getSphereCount() => _sphereNodes.length;

  /// Check if a sphere exists
  bool sphereExists(String sphereId) => _sphereNodes.containsKey(sphereId);

  /// Dispose of the service
  void dispose() {
    _spheresController.close();
    _statusController.close();
    _sphereNodes.clear();
    _isInitialized = false;
  }
}
