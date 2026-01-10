import '../services/firestore_service.dart';

class GraffitiRepository {
  final FirestoreService _firestoreService;

  GraffitiRepository(this._firestoreService);

  Stream<List<Map<String, dynamic>>> watchNearbyGraffiti() {
    return _firestoreService
        .streamCollectionWhere('graffiti', 'visibility', 'public')
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>},
              )
              .toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> watchTrendingGraffiti() {
    return _firestoreService
        .queryCollection('graffiti')
        .where('visibility', isEqualTo: 'public')
        .orderBy('stats.likes', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>},
              )
              .toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> searchGraffiti(String searchTerm) {
    if (searchTerm.trim().isEmpty) {
      return watchNearbyGraffiti();
    }

    return _firestoreService
        .searchGraffiti(searchTerm.trim())
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>},
              )
              .where((graffiti) {
                // Filter locally to avoid complex Firebase queries
                final title = (graffiti['title'] ?? '')
                    .toString()
                    .toLowerCase();
                final artist = (graffiti['artist'] ?? '')
                    .toString()
                    .toLowerCase();
                final location = (graffiti['location'] ?? '')
                    .toString()
                    .toLowerCase();
                final searchLower = searchTerm.toLowerCase();

                return title.contains(searchLower) ||
                    artist.contains(searchLower) ||
                    location.contains(searchLower);
              })
              .take(20)
              .toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> searchGraffitiByTags(List<String> tags) {
    if (tags.isEmpty) {
      return watchNearbyGraffiti();
    }

    return _firestoreService
        .searchGraffitiByTags(tags)
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>},
              )
              .toList(),
        );
  }
}
