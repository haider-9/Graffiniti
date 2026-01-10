# Map Implementation Guide

This document describes the OpenStreetMap integration using Flutter Map for the graffiti discovery feature.

## Features Added

### 1. Map Page
- **File**: `lib/pages/map_page.dart`
- **Features**:
  - Interactive OpenStreetMap using Flutter Map
  - Real-time location tracking with user permission handling
  - Graffiti markers with custom styling
  - Sliding graffiti list overlay
  - Detailed graffiti information modal
  - Distance calculations from current location
  - Smooth animations and transitions

### 2. Location Service
- **File**: `lib/core/services/location_service.dart`
- **Features**:
  - Location permission management
  - Current location retrieval with error handling
  - Distance calculations between coordinates
  - Distance formatting for display
  - Location settings access

### 3. Permission Dialog
- **File**: `lib/core/widgets/location_permission_dialog.dart`
- **Features**:
  - User-friendly permission request dialog
  - Explains why location access is needed
  - Handles permission grant/deny scenarios
  - Consistent with app theme

### 4. Dependencies Added
- **flutter_map**: ^7.0.2 - Interactive map widget
- **latlong2**: ^0.9.1 - Latitude/longitude calculations

## How It Works

### Map Navigation Flow
1. User taps map icon in discover page header
2. Map page opens with loading indicator
3. Location permission is requested if not granted
4. Map centers on user's current location
5. Graffiti markers are displayed on the map
6. User can interact with markers and view details

### Location Permission Flow
1. Check if location services are enabled
2. Check current permission status
3. Request permission if needed
4. Show permission dialog with explanation
5. Handle permission grant/deny responses
6. Fallback to default location if denied

### Map Features
- **Interactive Map**: Pan, zoom, and explore
- **Custom Markers**: Color-coded graffiti markers
- **Current Location**: Blue marker showing user position
- **Distance Calculation**: Real-time distance from user location
- **Graffiti List**: Sliding overlay with nearby graffiti
- **Responsive Detail Modal**: DraggableScrollableSheet for graffiti details
- **Overflow Prevention**: No content overflow issues on small screens

## Pakistan Locations

The map is configured with locations across major Pakistani cities:

### Default Location
- **Karachi, Pakistan**: LatLng(24.8607, 67.0011)

### Graffiti Locations
1. **Karachi - Saddar Town**: LatLng(24.8615, 67.0099)
2. **Lahore - Anarkali Bazaar**: LatLng(31.5204, 74.3587)
3. **Islamabad - F-7 Markaz**: LatLng(33.6844, 73.0479)
4. **Karachi - Gulshan-e-Iqbal**: LatLng(24.9056, 67.0822)
5. **Hyderabad - Qasimabad**: LatLng(25.3960, 68.3578)

### Cultural Context
- Locations include traditional Pakistani areas like Anarkali Bazaar in Lahore
- Descriptions reference Pakistani cultural elements and modern urban areas
- Distance calculations are accurate for Pakistan geography

### Map Configuration
```dart
FlutterMap(
  mapController: _mapController,
  options: MapOptions(
    initialCenter: _currentLocation,
    initialZoom: 13.0,
    minZoom: 3.0,
    maxZoom: 18.0,
  ),
  children: [
    // OpenStreetMap tiles
    TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.example.griffiniti',
      maxZoom: 18,
    ),
    // Markers for graffiti and current location
    MarkerLayer(markers: [...]),
  ],
)
```

### Location Service Usage
```dart
// Get current location
final location = await LocationService.getCurrentLocation();

// Calculate distance
final distance = LocationService.calculateDistance(point1, point2);

// Format distance for display
final formattedDistance = LocationService.formatDistance(distance);

// Check permissions
final hasPermission = await LocationService.hasLocationPermission();
```

### Responsive Detail Modal
```dart
showModalBottomSheet(
  context: context,
  backgroundColor: Colors.transparent,
  isScrollControlled: true,
  builder: (context) => DraggableScrollableSheet(
    initialChildSize: 0.6,
    minChildSize: 0.4,
    maxChildSize: 0.9,
    builder: (context, scrollController) => Container(
      // Responsive content with scroll controller
      child: SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          // Content that adapts to keyboard and screen size
        ),
      ),
    ),
  ),
)
```

### Custom Markers
```dart
Marker(
  point: graffiti['location'],
  width: 40,
  height: 40,
  child: Container(
    decoration: BoxDecoration(
      color: graffiti['color'],
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: [
        BoxShadow(
          color: graffiti['color'].withValues(alpha: 0.4),
          blurRadius: 8,
          spreadRadius: 2,
        ),
      ],
    ),
    child: Icon(Icons.palette, color: Colors.white, size: 20),
  ),
)
```

## UI Components

### Map Controls
- **Back Button**: Navigate back to discover page
- **List Toggle**: Show/hide graffiti list overlay
- **Current Location**: Center map on user location
- **Zoom Controls**: Built into Flutter Map

### Graffiti List Overlay
- **Sliding Animation**: Smooth slide up from bottom
- **List Items**: Graffiti cards with details
- **Tap to Center**: Tap item to center map on location
- **Distance Display**: Real-time distance calculations

### Graffiti Detail Modal
- **Full Information**: Title, artist, description, location
- **Action Buttons**: Like and "View in AR"
- **Visual Preview**: Color-coded graffiti representation
- **Distance Badge**: Formatted distance from user

## Data Structure

### Graffiti Location Data
```dart
{
  'id': 'unique_id',
  'title': 'Graffiti Title',
  'artist': '@artist_handle',
  'location': LatLng(latitude, longitude),
  'address': 'Human-readable address',
  'distance': 'Calculated distance string',
  'likes': 123,
  'time': 'Time ago string',
  'color': Color object,
  'description': 'Detailed description',
}
```

## Permissions Required

### Android (android/app/src/main/AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS (ios/Runner/Info.plist)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to show nearby graffiti.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs location access to show nearby graffiti.</string>
```

## Error Handling

### Location Errors
- **Service Disabled**: Falls back to default location
- **Permission Denied**: Shows permission dialog
- **Location Unavailable**: Uses San Francisco as default
- **Network Issues**: Map tiles may not load

### Map Errors
- **Tile Loading**: Graceful degradation if tiles fail
- **Marker Rendering**: Fallback to default markers
- **Animation Issues**: Skip animations if performance is poor

## Performance Considerations

### Map Optimization
- **Tile Caching**: Flutter Map handles tile caching
- **Marker Clustering**: Consider for large datasets
- **Lazy Loading**: Load graffiti data as needed
- **Memory Management**: Dispose controllers properly

### Location Updates
- **Debounced Updates**: Avoid excessive location requests
- **Battery Optimization**: Use appropriate accuracy levels
- **Background Handling**: Pause updates when not visible

## Future Enhancements

1. **Real-time Updates**: Live graffiti location updates
2. **Clustering**: Group nearby markers for better performance
3. **Offline Maps**: Cache map tiles for offline use
4. **Route Planning**: Directions to graffiti locations
5. **Augmented Reality**: AR view overlay on map
6. **User Contributions**: Allow users to add new locations
7. **Filtering**: Filter graffiti by artist, style, or date
8. **Favorites**: Save favorite graffiti locations

## Testing

### Map Functionality
1. **Location Permission**: Test permission flow
2. **Map Interaction**: Pan, zoom, marker taps
3. **Current Location**: Verify location accuracy
4. **Distance Calculation**: Check distance accuracy
5. **Offline Behavior**: Test without internet

### UI Components
1. **Responsive Design**: Test on different screen sizes
2. **Animation Performance**: Smooth transitions
3. **Error States**: Handle permission denials
4. **Loading States**: Show appropriate indicators

### Integration
1. **Navigation**: Discover page to map page
2. **Data Flow**: Graffiti data display
3. **State Management**: Proper state handling
4. **Memory Usage**: No memory leaks

## Troubleshooting

### Common Issues
- **Map not loading**: Check internet connection and tile URL
- **Location not working**: Verify permissions and GPS
- **Markers not showing**: Check coordinate format
- **Performance issues**: Reduce marker count or complexity

### Debug Tips
- Use Flutter Inspector for widget debugging
- Check device logs for location errors
- Verify coordinate accuracy with online tools
- Test on different devices and OS versions