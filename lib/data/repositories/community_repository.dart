import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/community.dart';
import '../services/firestore_service.dart';
import '../models/community_api_model.dart';

class CommunityRepository {
  final FirestoreService _firestoreService;

  CommunityRepository(this._firestoreService);

  Future<Community> getCommunity(String id) async {
    final doc = await _firestoreService.getDocument('communities', id);
    if (!doc.exists) {
      throw Exception('Community not found');
    }
    final apiModel = CommunityApiModel.fromFirestore(doc);
    return apiModel.toDomain();
  }

  Stream<List<Community>> watchCommunities() {
    return _firestoreService
        .streamCollection('crews')
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CommunityApiModel.fromFirestore(doc).toDomain())
              .toList(),
        );
  }

  Stream<List<Community>> watchPublicCommunities() {
    return _firestoreService
        .streamCollectionWhere('communities', 'visibility', 'public')
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CommunityApiModel.fromFirestore(doc).toDomain())
              .toList(),
        );
  }

  Future<Community> createCommunity({
    required String name,
    required String handle,
    required String description,
    required String createdBy,
    String? photoUrl,
    String? bannerUrl,
    List<String>? rules,
    List<String>? tags,
    CommunityVisibility visibility = CommunityVisibility.public,
  }) async {
    // Validate required fields
    if (name.trim().isEmpty) {
      throw Exception('Community name is required');
    }
    if (handle.trim().isEmpty) {
      throw Exception('Handle is required');
    }
    if (description.trim().isEmpty) {
      throw Exception('Description is required');
    }

    // Check if handle already exists
    try {
      final existingCommunity = await FirebaseFirestore.instance
          .collection('communities')
          .where('handle', isEqualTo: handle.trim())
          .limit(1)
          .get();

      if (existingCommunity.docs.isNotEmpty) {
        throw Exception('HANDLE_EXISTS');
      }
    } catch (e) {
      if (e.toString().contains('HANDLE_EXISTS')) {
        rethrow;
      }
      // Continue with creation if it's just a query error
    }

    final now = Timestamp.now();
    final data = {
      'name': name.trim(),
      'photoUrl': photoUrl?.trim() ?? '',
      'handle': handle.trim(),
      'description': description.trim(),
      'createdBy': createdBy,
      'bannerUrl': bannerUrl?.trim() ?? '',
      'createdAt': now,
      'updatedAt': now,
      'rules': rules ?? [],
      'tags': tags ?? [],
      'stats': {'graffinitiCount': 0, 'memberCount': 1, 'postCount': 0},
      'visibility': visibility == CommunityVisibility.private
          ? 'private'
          : 'public',
    };

    try {
      final docRef = await _firestoreService.addDocument('communities', data);
      final doc = await _firestoreService.getDocument('communities', docRef.id);
      return CommunityApiModel.fromFirestore(doc).toDomain();
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        throw Exception('You don\'t have permission to create communities');
      } else if (e.toString().contains('quota-exceeded')) {
        throw Exception(
          'Service temporarily unavailable. Please try again later',
        );
      } else {
        throw Exception('Failed to create community: ${e.toString()}');
      }
    }
  }

  Future<void> updateCommunity(String id, Map<String, dynamic> updates) async {
    updates['updatedAt'] = Timestamp.now();
    await _firestoreService.updateDocument('communities', id, updates);
  }

  Future<void> deleteCommunity(String id) async {
    await _firestoreService.deleteDocument('communities', id);
  }

  Future<void> joinCommunity(String communityId, String userId) async {
    // This would typically involve a subcollection or separate members collection
    // For now, we'll just increment the member count
    await _firestoreService.updateDocument('communities', communityId, {
      'stats.memberCount': FieldValue.increment(1),
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> leaveCommunity(String communityId, String userId) async {
    await _firestoreService.updateDocument('communities', communityId, {
      'stats.memberCount': FieldValue.increment(-1),
      'updatedAt': Timestamp.now(),
    });
  }
}
