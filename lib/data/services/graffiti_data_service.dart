import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';

class GraffitiDataService {
  static final GraffitiDataService _instance = GraffitiDataService._internal();
  factory GraffitiDataService() => _instance;
  GraffitiDataService._internal();

  // Unified graffiti data for both discover page and map
  static const List<Map<String, dynamic>> _graffitiData = [
    {
      'id': '1',
      'title': 'Urban Flow',
      'artist': '@streetartist',
      'location': LatLng(24.8615, 67.0099), // Karachi - Saddar
      'address': 'Saddar Town, Karachi',
      'likes': 234,
      'time': '2h ago',
      'color': AppTheme.accentOrange,
      'description':
          'Amazing street art with vibrant colors in the heart of Karachi',
      'tags': ['urban', 'street', 'flow', 'karachi'],
      'imageUrl':
          'https://plus.unsplash.com/premium_vector-1726422417849-0eabe3d12fad?w=352&dpr=2&h=367&auto=format&fit=crop&q=60&ixlib=rb-4.1.0',
    },
    {
      'id': '2',
      'title': 'City Pulse',
      'artist': '@graffitiking',
      'location': LatLng(31.5204, 74.3587), // Lahore - Old City
      'address': 'Anarkali Bazaar, Lahore',
      'likes': 189,
      'time': '4h ago',
      'color': AppTheme.accentBlue,
      'description': 'Neon-inspired digital art piece in historic Lahore',
      'tags': ['city', 'pulse', 'neon', 'lahore'],
      'imageUrl':
          'https://plus.unsplash.com/premium_photo-1687598084613-79e5c30e1361?w=1000&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTd8fGdyYWZmaXRpJTIwM2R8ZW58MHx8MHx8fDA%3D',
    },
    {
      'id': '3',
      'title': 'Street Canvas',
      'artist': '@urbanartist',
      'location': LatLng(33.6844, 73.0479), // Islamabad - F-7
      'address': 'F-7 Markaz, Islamabad',
      'likes': 456,
      'time': '6h ago',
      'color': AppTheme.accentGreen,
      'description': 'Large mural covering entire wall in the capital city',
      'tags': ['street', 'canvas', 'art', 'islamabad'],
      'imageUrl':
          'https://images.unsplash.com/photo-1690873260897-b689474bb700?w=1000&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8N3x8Z3JhZmZpdGklMjAzZHxlbnwwfHwwfHx8MA%3D%3D',
    },
    {
      'id': '4',
      'title': 'Neon Dreams',
      'artist': '@neonmaster',
      'location': LatLng(24.9056, 67.0822), // Karachi - Gulshan
      'address': 'Gulshan-e-Iqbal, Karachi',
      'likes': 321,
      'time': '8h ago',
      'color': AppTheme.accentPurple,
      'description': 'Futuristic cyberpunk-style artwork in modern Karachi',
      'tags': ['neon', 'dreams', 'tech', 'karachi'],
      'imageUrl':
          'https://images.unsplash.com/photo-1645943020355-305df166473d?w=1000&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Nnx8Z3JhZmZpdGklMjAzZHxlbnwwfHwwfHx8MA%3D%3D',
    },
    {
      'id': '5',
      'title': 'Heritage Art',
      'artist': '@culturalartist',
      'location': LatLng(25.3960, 68.3578), // Hyderabad
      'address': 'Qasimabad, Hyderabad',
      'likes': 178,
      'time': '1d ago',
      'color': AppTheme.accentRed,
      'description': 'Traditional Pakistani motifs in contemporary street art',
      'tags': ['heritage', 'culture', 'traditional', 'hyderabad'],
      'imageUrl':
          'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
    },
    {
      'id': '6',
      'title': 'Digital Fusion',
      'artist': '@techartist',
      'location': LatLng(24.8700, 67.0300), // Karachi - Clifton
      'address': 'Clifton Block 1, Karachi',
      'likes': 298,
      'time': '12h ago',
      'color': AppTheme.accentBlue,
      'description': 'Modern abstract art meets traditional calligraphy',
      'tags': ['digital', 'fusion', 'modern', 'karachi'],
      'imageUrl':
          'https://images.unsplash.com/photo-1610753718855-6b2dadf79d27?w=1000&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8Z3JhZmZpdGklMjAzZHxlbnwwfHwwfHx8MA%3D%3D',
    },
  ];

  /// Get all graffiti data
  List<Map<String, dynamic>> getAllGraffiti() {
    return List.from(_graffitiData);
  }

  /// Get graffiti data formatted for discover page (without location coordinates)
  List<Map<String, dynamic>> getDiscoverGraffiti() {
    return _graffitiData.map((graffiti) {
      final data = Map<String, dynamic>.from(graffiti);
      // Convert location to distance string for discover page
      data['distance'] = _calculateDistanceFromKarachi(graffiti['location']);
      data.remove('location'); // Remove LatLng for discover page
      return data;
    }).toList();
  }

  /// Get graffiti data formatted for map page (with location coordinates)
  List<Map<String, dynamic>> getMapGraffiti(LatLng currentLocation) {
    return _graffitiData.map((graffiti) {
      final data = Map<String, dynamic>.from(graffiti);
      // Calculate real-time distance from current location
      data['distance'] = _calculateDistance(
        currentLocation,
        graffiti['location'],
      );
      return data;
    }).toList();
  }

  /// Get graffiti by ID
  Map<String, dynamic>? getGraffitiById(String id) {
    try {
      return _graffitiData.firstWhere((graffiti) => graffiti['id'] == id);
    } catch (e) {
      return null;
    }
  }

  /// Search graffiti by query
  List<Map<String, dynamic>> searchGraffiti(
    String query, {
    LatLng? currentLocation,
  }) {
    if (query.isEmpty) {
      return currentLocation != null
          ? getMapGraffiti(currentLocation)
          : getDiscoverGraffiti();
    }

    final searchLower = query.toLowerCase();
    final filtered = _graffitiData.where((graffiti) {
      final title = graffiti['title'].toString().toLowerCase();
      final artist = graffiti['artist'].toString().toLowerCase();
      final address = graffiti['address'].toString().toLowerCase();
      final tags = (graffiti['tags'] as List<String>).join(' ').toLowerCase();

      return title.contains(searchLower) ||
          artist.contains(searchLower) ||
          address.contains(searchLower) ||
          tags.contains(searchLower);
    }).toList();

    // Format based on context (map or discover)
    if (currentLocation != null) {
      return filtered.map((graffiti) {
        final data = Map<String, dynamic>.from(graffiti);
        data['distance'] = _calculateDistance(
          currentLocation,
          graffiti['location'],
        );
        return data;
      }).toList();
    } else {
      return filtered.map((graffiti) {
        final data = Map<String, dynamic>.from(graffiti);
        data['distance'] = _calculateDistanceFromKarachi(graffiti['location']);
        data.remove('location');
        return data;
      }).toList();
    }
  }

  /// Calculate distance from current location
  String _calculateDistance(LatLng from, LatLng to) {
    // Simple distance calculation (you can use geolocator for more accuracy)
    const double earthRadius = 6371; // km

    final double lat1Rad = from.latitude * (pi / 180);
    final double lat2Rad = to.latitude * (pi / 180);
    final double deltaLatRad = (to.latitude - from.latitude) * (pi / 180);
    final double deltaLngRad = (to.longitude - from.longitude) * (pi / 180);

    final double a =
        sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLngRad / 2) *
            sin(deltaLngRad / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final double distance = earthRadius * c;

    if (distance < 1) {
      return '${(distance * 1000).round()}m';
    } else {
      return '${distance.toStringAsFixed(1)}km';
    }
  }

  /// Calculate distance from Karachi (default for discover page)
  String _calculateDistanceFromKarachi(LatLng location) {
    const LatLng karachi = LatLng(24.8607, 67.0011);
    return _calculateDistance(karachi, location);
  }

  /// Get trending graffiti (sorted by likes)
  List<Map<String, dynamic>> getTrendingGraffiti({LatLng? currentLocation}) {
    final sorted = List<Map<String, dynamic>>.from(_graffitiData);
    sorted.sort((a, b) => (b['likes'] as int).compareTo(a['likes'] as int));

    if (currentLocation != null) {
      return sorted.map((graffiti) {
        final data = Map<String, dynamic>.from(graffiti);
        data['distance'] = _calculateDistance(
          currentLocation,
          graffiti['location'],
        );
        return data;
      }).toList();
    } else {
      return sorted.map((graffiti) {
        final data = Map<String, dynamic>.from(graffiti);
        data['distance'] = _calculateDistanceFromKarachi(graffiti['location']);
        data.remove('location');
        return data;
      }).toList();
    }
  }

  /// Get nearby graffiti (for map page)
  List<Map<String, dynamic>> getNearbyGraffiti(
    LatLng currentLocation, {
    double radiusKm = 50,
  }) {
    return _graffitiData
        .where((graffiti) {
          final distance = _calculateDistance(
            currentLocation,
            graffiti['location'],
          );
          final distanceKm =
              double.tryParse(distance.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
          return distanceKm <= radiusKm;
        })
        .map((graffiti) {
          final data = Map<String, dynamic>.from(graffiti);
          data['distance'] = _calculateDistance(
            currentLocation,
            graffiti['location'],
          );
          return data;
        })
        .toList();
  }
}
