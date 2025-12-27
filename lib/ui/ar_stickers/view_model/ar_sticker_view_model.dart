import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import '../../../models/ar_sticker.dart';
import '../../../core/services/ar_service.dart';

enum ARMode { viewing, placing, editing }

class ARStickerViewModel extends ChangeNotifier {
  final ARService _arService = ARService();

  ARMode _currentMode = ARMode.viewing;
  ARSticker? _selectedSticker;
  ARStickerTemplate? _selectedTemplate;
  String? _editingStickerId;
  bool _isPlacementMode = false;
  bool _showPlanes = true;

  // Interaction state
  bool _isDragging = false;
  bool _isScaling = false;
  bool _isRotating = false;

  // Gesture tracking
  double _initialScale = 1.0;
  double _currentScale = 1.0;
  double _initialRotation = 0.0;
  double _currentRotation = 0.0;

  // Getters
  ARMode get currentMode => _currentMode;
  ARSticker? get selectedSticker => _selectedSticker;
  ARStickerTemplate? get selectedTemplate => _selectedTemplate;
  String? get editingStickerId => _editingStickerId;
  bool get isPlacementMode => _isPlacementMode;
  bool get showPlanes => _showPlanes;
  bool get isDragging => _isDragging;
  bool get isScaling => _isScaling;
  bool get isRotating => _isRotating;

  List<ARSticker> get stickers => _arService.stickers;
  Stream<List<ARSticker>> get stickersStream => _arService.stickersStream;
  Stream<bool> get trackingStateStream => _arService.trackingStateStream;

  // Mode management
  void setMode(ARMode mode) {
    if (_currentMode != mode) {
      _currentMode = mode;

      // Reset states when changing modes
      if (mode != ARMode.editing) {
        _editingStickerId = null;
        _selectedSticker = null;
      }
      if (mode != ARMode.placing) {
        _isPlacementMode = false;
        _selectedTemplate = null;
      }

      notifyListeners();
    }
  }

  void enterPlacementMode(ARStickerTemplate template) {
    _selectedTemplate = template;
    _isPlacementMode = true;
    _currentMode = ARMode.placing;
    notifyListeners();
  }

  void exitPlacementMode() {
    _isPlacementMode = false;
    _selectedTemplate = null;
    _currentMode = ARMode.viewing;
    notifyListeners();
  }

  void enterEditMode(String stickerId) {
    final sticker = stickers.firstWhere(
      (s) => s.id == stickerId,
      orElse: () => throw Exception('Sticker not found'),
    );

    _editingStickerId = stickerId;
    _selectedSticker = sticker;
    _currentMode = ARMode.editing;
    notifyListeners();
  }

  void exitEditMode() {
    if (_editingStickerId != null && _selectedSticker != null) {
      // Lock the sticker in place
      final updatedSticker = _selectedSticker!.copyWith(
        state: StickerState.locked,
      );
      _arService.updateStickerTransform(
        _editingStickerId!,
        updatedSticker.position,
        updatedSticker.rotation,
        updatedSticker.scale,
      );
    }

    _editingStickerId = null;
    _selectedSticker = null;
    _currentMode = ARMode.viewing;
    notifyListeners();
  }

  // Sticker placement
  Future<bool> placeStickerAtScreenPosition(Offset screenPosition) async {
    if (!_isPlacementMode || _selectedTemplate == null) return false;

    // Perform hit test to get world position
    final worldPosition = _arService.hitTestPlane(screenPosition);
    if (worldPosition == null) return false;

    // Create sticker from template
    final sticker = ARSticker(
      id: _generateStickerId(),
      type: _selectedTemplate!.type,
      content: _selectedTemplate!.content,
      position: worldPosition,
      properties: Map.from(_selectedTemplate!.defaultProperties),
      state: StickerState.placing,
    );

    // Add to AR scene
    final stickerId = await _arService.addSticker(sticker, worldPosition);
    if (stickerId != null) {
      exitPlacementMode();
      return true;
    }

    return false;
  }

  // Gesture handling
  void onTapDown(TapDownDetails details) {
    // Store tap position if needed for future use
  }

  void onTap(TapUpDetails details) {
    if (_isPlacementMode) {
      // Place sticker
      placeStickerAtScreenPosition(details.localPosition);
    } else if (_currentMode == ARMode.viewing) {
      // Try to select a sticker for editing
      _trySelectStickerAtPosition(details.localPosition);
    }
  }

  void onScaleStart(ScaleStartDetails details) {
    if (_currentMode == ARMode.editing && _selectedSticker != null) {
      _initialScale = _selectedSticker!.scale.x;
      _currentScale = _initialScale;

      // Determine if this is a scale or pan gesture
      if (details.pointerCount > 1) {
        _isScaling = true;
      } else {
        _isDragging = true;
      }
      notifyListeners();
    }
  }

  void onScaleUpdate(ScaleUpdateDetails details) {
    if (_selectedSticker != null && _editingStickerId != null) {
      if (details.pointerCount > 1 && details.scale != 1.0) {
        // Multi-finger scale gesture
        _currentScale = _initialScale * details.scale;
        _currentScale = _currentScale.clamp(0.1, 5.0); // Limit scale range

        final newScale = vector.Vector3.all(_currentScale);
        _selectedSticker = _selectedSticker!.copyWith(scale: newScale);
        _arService.updateStickerTransform(
          _editingStickerId!,
          null,
          null,
          newScale,
        );
      } else if (details.pointerCount == 1) {
        // Single finger pan gesture
        final worldDelta = _screenToWorldDelta(details.focalPointDelta);
        final newPosition = _selectedSticker!.position + worldDelta;

        _selectedSticker = _selectedSticker!.copyWith(position: newPosition);
        _arService.updateStickerTransform(
          _editingStickerId!,
          newPosition,
          null,
          null,
        );
      }
      notifyListeners();
    }
  }

  void onScaleEnd(ScaleEndDetails details) {
    _isScaling = false;
    _isDragging = false;
    notifyListeners();
  }

  void onRotationStart(double initialRotation) {
    if (_currentMode == ARMode.editing && _selectedSticker != null) {
      _initialRotation = _selectedSticker!.rotation.y;
      _currentRotation = _initialRotation;
      _isRotating = true;
      notifyListeners();
    }
  }

  void onRotationUpdate(double rotation) {
    if (_isRotating && _selectedSticker != null && _editingStickerId != null) {
      _currentRotation = _initialRotation + rotation;

      final newRotation = vector.Vector3(
        _selectedSticker!.rotation.x,
        _currentRotation,
        _selectedSticker!.rotation.z,
      );

      _selectedSticker = _selectedSticker!.copyWith(rotation: newRotation);
      _arService.updateStickerTransform(
        _editingStickerId!,
        null,
        newRotation,
        null,
      );
      notifyListeners();
    }
  }

  void onRotationEnd() {
    _isRotating = false;
    notifyListeners();
  }

  // Sticker management
  Future<void> deleteSticker(String stickerId) async {
    await _arService.removeSticker(stickerId);

    if (_editingStickerId == stickerId) {
      exitEditMode();
    }
  }

  Future<void> duplicateSticker(String stickerId) async {
    final originalSticker = stickers.firstWhere((s) => s.id == stickerId);

    // Create duplicate with slight offset
    final offset = vector.Vector3(0.1, 0.0, 0.1);
    final duplicateSticker = ARSticker(
      id: _generateStickerId(),
      type: originalSticker.type,
      content: originalSticker.content,
      position: originalSticker.position + offset,
      rotation: originalSticker.rotation,
      scale: originalSticker.scale,
      properties: Map.from(originalSticker.properties),
    );

    await _arService.addSticker(duplicateSticker, duplicateSticker.position);
  }

  Future<void> clearAllStickers() async {
    await _arService.clearAllStickers();
    exitEditMode();
  }

  // Utility methods
  void togglePlaneVisibility() {
    _showPlanes = !_showPlanes;
    notifyListeners();
  }

  void _trySelectStickerAtPosition(Offset screenPosition) {
    // In a real implementation, you would perform hit testing against sticker nodes
    // For now, we'll select the first sticker if any exist
    if (stickers.isNotEmpty) {
      enterEditMode(stickers.first.id);
    }
  }

  vector.Vector3 _screenToWorldDelta(Offset screenDelta) {
    // Simplified conversion - in reality this would use camera projection
    const sensitivity = 0.001;
    return vector.Vector3(
      screenDelta.dx * sensitivity,
      0.0,
      screenDelta.dy * sensitivity,
    );
  }

  String _generateStickerId() {
    return 'sticker_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  // Persistence
  Future<Map<String, dynamic>> exportSession() async {
    final stickerData = await _arService.exportStickers();
    return {
      'stickers': stickerData,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'version': '1.0',
    };
  }

  Future<void> importSession(Map<String, dynamic> sessionData) async {
    final stickerData = List<Map<String, dynamic>>.from(
      sessionData['stickers'] ?? [],
    );
    await _arService.importStickers(stickerData);
  }

  @override
  void dispose() {
    _arService.dispose();
    super.dispose();
  }
}
