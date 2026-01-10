import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme/app_theme.dart';
import '../core/services/location_service.dart';
import '../core/widgets/location_permission_dialog.dart';
import '../core/widgets/swipeable_graffiti_panel.dart';
import '../data/services/graffiti_data_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late AnimationController _animationController;
  final GraffitiDataService _graffitiService = GraffitiDataService();

  LatLng _currentLocation = const LatLng(
    24.8607,
    67.0011,
  ); // Default to Karachi, Pakistan
  bool _isLoadingLocation = true;
  bool _showGraffitiList = false;

  // Current zoom level for showing images
  double _currentZoom = 13.0;

  // Get graffiti data from unified service
  List<Map<String, dynamic>> get _graffitiLocations {
    return _graffitiService.getMapGraffiti(_currentLocation);
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    // Check if we have location permission
    final hasPermission = await LocationService.hasLocationPermission();
    if (!hasPermission) {
      setState(() => _isLoadingLocation = false);
      if (mounted) {
        LocationPermissionDialog.show(
          context,
          onPermissionGranted: _getCurrentLocation,
        );
      }
      return;
    }

    final location = await LocationService.getCurrentLocation();

    setState(() {
      _currentLocation = location;
      _isLoadingLocation = false;
    });

    _mapController.move(_currentLocation, 13.0);
  }

  void _toggleGraffitiList() {
    setState(() {
      _showGraffitiList = !_showGraffitiList;
    });

    if (_showGraffitiList) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _centerOnLocation(LatLng location) {
    _mapController.move(location, 16.0);
    setState(() {
      _showGraffitiList = false;
    });
    _animationController.reverse();
  }

  void _centerOnCurrentLocation() {
    if (!_isLoadingLocation) {
      _mapController.move(_currentLocation, 15.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 13.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              onPositionChanged: (MapCamera position, bool hasGesture) {
                setState(() {
                  _currentZoom = position.zoom;
                });
              },
            ),
            children: [
              // OpenStreetMap tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.griffiniti',
                maxZoom: 18,
              ),

              // Graffiti markers
              MarkerLayer(
                markers: _graffitiLocations.map((graffiti) {
                  return Marker(
                    point: graffiti['location'],
                    width: _currentZoom >= 15.0 ? 60 : 40,
                    height: _currentZoom >= 15.0 ? 60 : 40,
                    child: GestureDetector(
                      onTap: () => _showGraffitiDetails(graffiti),
                      child: _buildGraffitiMarker(graffiti),
                    ),
                  );
                }).toList(),
              ),

              // Current location marker
              if (!_isLoadingLocation)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation,
                      width: 30,
                      height: 30,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.accentBlue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Header with dark semi-transparent background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Graffiti Map',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 3,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _toggleGraffitiList,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.pin_drop_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Floating action buttons
          Positioned(
            right: 20,
            bottom: 100,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _centerOnCurrentLocation,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentOrange.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Swipeable graffiti panel
          if (_showGraffitiList)
            SwipeableGraffitiPanel(
              graffitiList: _graffitiLocations,
              onGraffitiTap: _showGraffitiDetails,
              onLocationTap: _centerOnLocation,
              onClose: () {
                setState(() {
                  _showGraffitiList = false;
                });
                _animationController.reverse();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildGraffitiMarker(Map<String, dynamic> graffiti) {
    final color = graffiti['color'] as Color? ?? Colors.grey;
    final showImage = _currentZoom >= 15.0;
    final size = showImage ? 60.0 : 40.0;

    if (showImage) {
      // Show image at higher zoom levels
      final imageUrl = graffiti['imageUrl'];

      if (imageUrl != null && imageUrl.isNotEmpty) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size / 2),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildIconMarker(color, size);
              },
              errorBuilder: (context, error, stackTrace) {
                return _buildIconMarker(color, size);
              },
            ),
          ),
        );
      }
    }

    // Default icon marker
    return _buildIconMarker(color, size);
  }

  Widget _buildIconMarker(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(Icons.palette, color: Colors.white, size: size * 0.5),
    );
  }

  void _showGraffitiDetails(Map<String, dynamic> graffiti) {
    final color = graffiti['color'] as Color? ?? Colors.grey;

    // Reusable fallback preview
    Widget fallbackPreview() {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.3),
              color.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.view_in_ar, size: 48, color: color),
              const SizedBox(height: 8),
              Text(
                graffiti['title'] ?? 'Untitled',
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Image widget with fallback
    Widget graffitiImage() {
      final imageUrl = graffiti['imageUrl'];
      if (imageUrl == null || imageUrl.isEmpty) return fallbackPreview();

      return SizedBox(
        height: 200,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                alignment: Alignment.center,
                color: AppTheme.secondaryBlack,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => fallbackPreview(),
          ),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryText,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Graffiti image / fallback
                  graffitiImage(),

                  const SizedBox(height: 16),

                  // Details
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: color,
                        child: Text(
                          graffiti['artist'] != null &&
                                  graffiti['artist'].length > 1
                              ? graffiti['artist'][1].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              graffiti['artist'] ?? 'Unknown Artist',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              graffiti['time'] ?? '',
                              style: const TextStyle(
                                color: AppTheme.mutedText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          graffiti['distance'] ?? '-',
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppTheme.secondaryText,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          graffiti['address'] ?? 'Unknown location',
                          style: const TextStyle(
                            color: AppTheme.secondaryText,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    graffiti['description'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryBlack,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.favorite_outline,
                                color: AppTheme.secondaryText,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${graffiti['likes'] ?? 0}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.view_in_ar,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'View in AR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
