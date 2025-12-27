# AR Sticker System Documentation

## Overview

The AR Sticker System provides a comprehensive augmented reality experience that allows users to place interactive stickers anchored to real-world objects and surfaces. The system uses ARCore for Android to deliver high-fidelity, stable, and immersive AR experiences.

## Key Features

### 🎯 Real-World Anchoring
- **Persistent Anchoring**: Stickers are anchored using ARAnchors tied to detected surfaces or feature points
- **World-Locked Positioning**: Stickers maintain correct position, scale, and orientation as users move around
- **SLAM-Based Tracking**: Continuous tracking maintains stability across camera movements
- **Surface Detection**: Real-time plane detection for horizontal and vertical surfaces

### 🎨 Sticker Types
- **Emojis**: Pre-defined emoji stickers with customizable size
- **Text**: Custom text with color selection and font sizing
- **Shapes**: Geometric shapes (circles, squares, triangles, arrows)
- **Images**: Support for custom image stickers (extensible)

### 🎮 Interactive Controls
- **Placement Mode**: Tap-to-place stickers on detected surfaces
- **Edit Mode**: Drag, scale, and rotate placed stickers
- **Gesture Support**: Pinch-to-scale, rotation gestures, drag-to-move
- **Lock System**: Stickers become locked after editing to prevent accidental changes

### 🔧 Advanced Features
- **Depth-Aware Occlusion**: Stickers appear behind real objects when appropriate
- **Lighting Estimation**: Matches sticker brightness with physical environment
- **Re-localization**: Smooth recovery when tracking is briefly lost
- **Session Persistence**: Export/import sticker sessions for later use

## Architecture

### Core Components

#### 1. ARService (`lib/core/services/ar_service.dart`)
- Manages ARCore integration and AR session lifecycle
- Handles plane detection and feature point tracking
- Manages AR anchors and world-locked positioning
- Provides streams for tracking state and detected planes

#### 2. ARStickerManager (`lib/core/managers/ar_sticker_manager.dart`)
- Manages AR interaction modes (viewing, placing, editing)
- Handles gesture recognition and sticker manipulation
- Coordinates between UI state and AR service
- Manages sticker lifecycle and persistence

#### 3. ARSticker Model (`lib/models/ar_sticker.dart`)
- Defines sticker data structure and properties
- Supports serialization for persistence
- Includes predefined sticker templates
- Manages sticker state (placing, editing, locked)

#### 4. UI Components
- **ARStickerPanel**: Sticker selection and customization interface
- **ARControlsOverlay**: Top-level controls and settings
- **ARGraffitiPage**: Main AR camera view and interaction surface

### Data Flow

```
User Interaction → ARStickerManager → ARService → ARCore
                ↓                    ↓           ↓
            UI Updates ←─────── State Changes ←─ AR Events
```

## Usage Guide

### Basic Workflow

1. **Initialize AR**: App checks ARCore availability and initializes camera
2. **Surface Detection**: Move device to detect horizontal/vertical planes
3. **Sticker Selection**: Choose from emojis, shapes, or create custom text
4. **Placement**: Tap on detected surface to place sticker
5. **Editing**: Tap placed sticker to enter edit mode
6. **Manipulation**: Use gestures to move, scale, rotate
7. **Lock**: Tap "Done" to lock sticker in world position

### Gesture Controls

#### Placement Mode
- **Tap**: Place selected sticker on detected surface
- **Move Device**: Detect new surfaces and planes

#### Edit Mode
- **Drag**: Move sticker along surface plane
- **Pinch**: Scale sticker up/down (0.1x to 5.0x range)
- **Rotate**: Two-finger rotation gesture
- **Tap Outside**: Exit edit mode and lock sticker

### Settings and Options

#### Plane Visibility
- Toggle detection plane visualization
- Helps users understand where stickers can be placed

#### Session Management
- **Export**: Save current sticker configuration
- **Import**: Load previously saved sticker sessions
- **Clear All**: Remove all placed stickers

## Technical Implementation

### ARCore Integration

```dart
// Initialize ARCore session
final controller = ArCoreController();
await ARService().initialize(controller);

// Configure session for plane detection
await controller.enablePlaneRenderer(true);
await controller.enableUpdateListener(true);
```

### Sticker Placement

```dart
// Hit test against detected planes
final worldPosition = ARService().hitTestPlane(screenPosition);

// Create and place sticker
final sticker = ARSticker(
  id: generateId(),
  type: StickerType.emoji,
  content: '😀',
  position: worldPosition,
);

await ARService().addSticker(sticker, worldPosition);
```

### Gesture Handling

```dart
// Scale gesture
void onScaleUpdate(ScaleUpdateDetails details) {
  final newScale = initialScale * details.scale;
  final clampedScale = newScale.clamp(0.1, 5.0);
  
  updateStickerTransform(
    stickerId,
    scale: Vector3.all(clampedScale),
  );
}
```

## Performance Considerations

### Optimization Strategies

1. **Efficient Rendering**: Limit number of simultaneous stickers
2. **LOD System**: Reduce detail for distant stickers
3. **Culling**: Hide stickers outside camera view
4. **Memory Management**: Proper disposal of AR resources

### Resource Management

```dart
@override
void dispose() {
  _arCoreController?.dispose();
  _stickerManager.dispose();
  ARService().dispose();
  super.dispose();
}
```

## Error Handling

### Common Issues and Solutions

#### ARCore Not Available
```dart
final isAvailable = await ArCoreController.checkArCoreAvailability();
if (!isAvailable) {
  // Show error message and fallback UI
  showErrorDialog('ARCore not supported on this device');
}
```

#### Tracking Lost
```dart
StreamBuilder<bool>(
  stream: ARService().trackingStateStream,
  builder: (context, snapshot) {
    final isTracking = snapshot.data ?? false;
    if (!isTracking) {
      return TrackingLostIndicator();
    }
    return Container();
  },
);
```

#### Surface Detection Issues
- Ensure adequate lighting
- Move device slowly for better plane detection
- Target textured surfaces for better tracking
- Avoid reflective or transparent surfaces

## Future Enhancements

### Planned Features

1. **Cloud Anchors**: Share stickers between devices
2. **Occlusion Mapping**: Advanced depth-based occlusion
3. **Physics Integration**: Realistic sticker physics
4. **Animation System**: Animated sticker effects
5. **Collaborative Mode**: Multi-user AR sessions

### Extensibility Points

#### Custom Sticker Types
```dart
class CustomStickerRenderer extends StickerRenderer {
  @override
  ArCoreNode createNode(ARSticker sticker, Vector3 position) {
    // Custom rendering logic
  }
}
```

#### Advanced Interactions
```dart
class StickerInteractionHandler {
  void onStickerTapped(ARSticker sticker) {
    // Custom interaction logic
  }
}
```

## Dependencies

### Required Packages
- `arcore_flutter_plugin: ^0.0.9` - ARCore integration
- `vector_math: ^2.1.4` - 3D math operations
- `provider: ^6.1.5+1` - State management

### Platform Requirements
- **Android**: API level 24+ (Android 7.0)
- **ARCore**: Must be installed and supported
- **OpenGL ES**: Version 2.0+
- **Camera**: Rear-facing camera required

## Testing and Debugging

### Debug Features
- Plane visualization toggle
- Tracking state indicator
- Performance metrics overlay
- Sticker count display

### Testing Checklist
- [ ] ARCore availability check
- [ ] Plane detection on various surfaces
- [ ] Sticker placement accuracy
- [ ] Gesture responsiveness
- [ ] Tracking stability during movement
- [ ] Session persistence
- [ ] Error handling scenarios

## Troubleshooting

### Common Problems

**Stickers appear to float or drift:**
- Check tracking quality
- Ensure good lighting conditions
- Re-initialize AR session if needed

**Poor plane detection:**
- Move device more slowly
- Target textured surfaces
- Ensure adequate lighting
- Clean camera lens

**Performance issues:**
- Limit number of active stickers
- Reduce sticker complexity
- Check device thermal state
- Close other apps using camera

## Conclusion

The AR Sticker System provides a robust foundation for augmented reality experiences in Flutter applications. With proper implementation of ARCore integration, gesture handling, and state management, it delivers a Samsung AR Zone-like experience with stable, world-locked virtual content that feels truly integrated with the physical environment.