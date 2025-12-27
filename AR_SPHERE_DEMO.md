# AR Sphere Demo - World-Locked Objects

This demo shows how to properly implement world-locked AR objects using ARCore that don't drift when the camera moves.

## Key Concepts

### ✅ The Right Way: Using Hit Test Results
- Tap on detected surfaces (planes)
- Use `hit.pose.translation` for world position
- Objects stay locked to real-world locations
- No camera drift

### ❌ The Wrong Way: Camera-Relative Positioning
- Placing objects relative to camera position
- Objects move when camera moves
- Causes drift and poor user experience

## How to Use

1. **Launch the Demo**
   - Open the camera page
   - Tap the AR demo button (purple icon with AR symbol)
   - Choose "World-Locked Spheres"

2. **Place Spheres**
   - Move your device to detect surfaces (floors, tables, walls)
   - Tap on detected planes to place blue spheres
   - Spheres will stay locked to that real-world location

3. **Test World-Locking**
   - Walk around the sphere
   - Move the camera in different directions
   - The sphere should stay exactly where you placed it

## Code Architecture

### ARSphereService
- Handles plane tap detection
- Creates spheres at world positions
- Manages sphere lifecycle

### Key Methods
```dart
// Handle plane taps for world-locked placement
_arCoreController!.onPlaneTap = _handlePlaneTap;

// Create sphere at hit test position (world-stable)
final sphereId = await _createSphereAtPosition(hit.pose.translation);

// Add to AR scene
await _arCoreController!.addArCoreNode(node);
```

## Mental Model

Think of it this way:
- **Camera moves** ❌ 
- **World position stays** ✅ 
- **Sphere attached to world** ✅ 

The key is using ARCore's hit test results, which provide world-stable positions that ARCore continuously tracks and updates.

## Features Demonstrated

- ✅ Plane detection and hit testing
- ✅ World-locked object placement
- ✅ Multiple sphere creation
- ✅ Custom materials and colors
- ✅ Real-time status updates
- ✅ Sphere management (add/remove/clear)

## Technical Notes

While the original concept mentioned ARCore Anchors, the `arcore_flutter_plugin` doesn't expose the full anchor API. However, using hit test results from plane detection achieves the same world-locking effect because:

1. Hit test results provide world-stable positions
2. ARCore continuously tracks these positions
3. Objects placed at these positions remain world-locked
4. No manual anchor management needed

This approach is simpler and works reliably for most AR use cases.

## Next Steps

For production apps, consider:
- Persistent anchors (save/restore sphere positions)
- Cloud anchors (share spheres between devices)
- Geospatial anchors (GPS-based positioning)
- Advanced materials and animations
- Physics interactions

The foundation demonstrated here scales to these advanced features.