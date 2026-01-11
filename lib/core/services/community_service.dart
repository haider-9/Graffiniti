import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/community_member.dart';
import 'auth_service.dart';
import 'cloudinary_service.dart';

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  /// Join a community
  Future<bool> joinCommunity(String communityId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Check if user is anonymous
      if (_authService.isAnonymous) {
        throw Exception(
          'Anonymous users cannot join communities. Please upgrade your account.',
        );
      }

      final batch = _firestore.batch();

      // Add user to community members
      final memberRef = _firestore
          .collection('communities')
          .doc(communityId)
          .collection('members')
          .doc(userId);

      batch.set(memberRef, {
        'userId': userId,
        'joinedAt': FieldValue.serverTimestamp(),
        'role': 'member',
        'isActive': true,
      });

      // Update community member count
      final communityRef = _firestore
          .collection('communities')
          .doc(communityId);
      batch.update(communityRef, {
        'stats.memberCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add community to user's joined communities
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'joinedCommunities': FieldValue.arrayUnion([communityId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return true;
    } catch (e) {
      throw Exception('Failed to join community: ${e.toString()}');
    }
  }

  /// Leave a community
  Future<bool> leaveCommunity(String communityId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Check if user is anonymous
      if (_authService.isAnonymous) {
        throw Exception('Anonymous users cannot leave communities.');
      }

      final batch = _firestore.batch();

      // Remove user from community members
      final memberRef = _firestore
          .collection('communities')
          .doc(communityId)
          .collection('members')
          .doc(userId);

      batch.delete(memberRef);

      // Update community member count
      final communityRef = _firestore
          .collection('communities')
          .doc(communityId);
      batch.update(communityRef, {
        'stats.memberCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Remove community from user's joined communities
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'joinedCommunities': FieldValue.arrayRemove([communityId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return true;
    } catch (e) {
      throw Exception('Failed to leave community: ${e.toString()}');
    }
  }

  /// Check if user is a member of a community
  Future<bool> isMember(String communityId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final memberDoc = await _firestore
          .collection('communities')
          .doc(communityId)
          .collection('members')
          .doc(userId)
          .get();

      return memberDoc.exists && (memberDoc.data()?['isActive'] ?? false);
    } catch (e) {
      return false;
    }
  }

  /// Get community members
  Future<List<CommunityMember>> getCommunityMembers(
    String communityId, {
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('communities')
          .doc(communityId)
          .collection('members')
          .where('isActive', isEqualTo: true)
          .orderBy('joinedAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      final members = <CommunityMember>[];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final userId = data['userId'] as String;

        // Get user data
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final userData = userDoc.data();

        if (userData != null) {
          members.add(
            CommunityMember(
              userId: userId,
              displayName: userData['displayName'] ?? 'Unknown User',
              profileImageUrl: userData['profileImageUrl'] ?? '',
              role: data['role'] ?? 'member',
              joinedAt:
                  (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              isActive: data['isActive'] ?? true,
            ),
          );
        }
      }

      return members;
    } catch (e) {
      throw Exception('Failed to get community members: ${e.toString()}');
    }
  }

  /// Get member count for a community
  Future<int> getMemberCount(String communityId) async {
    try {
      final communityDoc = await _firestore
          .collection('communities')
          .doc(communityId)
          .get();

      final data = communityDoc.data();
      return data?['stats']?['memberCount'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Stream community members
  Stream<List<CommunityMember>> streamCommunityMembers(
    String communityId, {
    int limit = 50,
  }) {
    return _firestore
        .collection('communities')
        .doc(communityId)
        .collection('members')
        .where('isActive', isEqualTo: true)
        .orderBy('joinedAt', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap((snapshot) async {
          final members = <CommunityMember>[];

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final userId = data['userId'] as String;

            try {
              // Get user data
              final userDoc = await _firestore
                  .collection('users')
                  .doc(userId)
                  .get();
              final userData = userDoc.data();

              if (userData != null) {
                members.add(
                  CommunityMember(
                    userId: userId,
                    displayName: userData['displayName'] ?? 'Unknown User',
                    profileImageUrl: userData['profileImageUrl'] ?? '',
                    role: data['role'] ?? 'member',
                    joinedAt:
                        (data['joinedAt'] as Timestamp?)?.toDate() ??
                        DateTime.now(),
                    isActive: data['isActive'] ?? true,
                  ),
                );
              }
            } catch (e) {
              // Skip this member if we can't get their data
              continue;
            }
          }

          return members;
        });
  }

  /// Get user's joined communities
  Future<List<String>> getUserJoinedCommunities() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();

      return List<String>.from(userData?['joinedCommunities'] ?? []);
    } catch (e) {
      return [];
    }
  }

  /// Update member role (admin only)
  Future<bool> updateMemberRole(
    String communityId,
    String memberId,
    String newRole,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Check if current user is admin
      final currentUserMember = await _firestore
          .collection('communities')
          .doc(communityId)
          .collection('members')
          .doc(userId)
          .get();

      final currentUserRole = currentUserMember.data()?['role'] ?? 'member';
      if (currentUserRole != 'admin' && currentUserRole != 'owner') {
        throw Exception('Insufficient permissions');
      }

      // Update member role
      await _firestore
          .collection('communities')
          .doc(communityId)
          .collection('members')
          .doc(memberId)
          .update({'role': newRole, 'updatedAt': FieldValue.serverTimestamp()});

      return true;
    } catch (e) {
      throw Exception('Failed to update member role: ${e.toString()}');
    }
  }

  /// Remove member from community (admin only)
  Future<bool> removeMember(String communityId, String memberId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Check if current user is admin
      final currentUserMember = await _firestore
          .collection('communities')
          .doc(communityId)
          .collection('members')
          .doc(userId)
          .get();

      final currentUserRole = currentUserMember.data()?['role'] ?? 'member';
      if (currentUserRole != 'admin' && currentUserRole != 'owner') {
        throw Exception('Insufficient permissions');
      }

      final batch = _firestore.batch();

      // Remove member
      final memberRef = _firestore
          .collection('communities')
          .doc(communityId)
          .collection('members')
          .doc(memberId);

      batch.delete(memberRef);

      // Update community member count
      final communityRef = _firestore
          .collection('communities')
          .doc(communityId);
      batch.update(communityRef, {
        'stats.memberCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Remove community from user's joined communities
      final userRef = _firestore.collection('users').doc(memberId);
      batch.update(userRef, {
        'joinedCommunities': FieldValue.arrayRemove([communityId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return true;
    } catch (e) {
      throw Exception('Failed to remove member: ${e.toString()}');
    }
  }

  /// Upload community profile image
  Future<String> uploadCommunityProfileImage(
    String communityId,
    File imageFile,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Check if user is anonymous
      if (_authService.isAnonymous) {
        throw Exception('Anonymous users cannot upload images.');
      }

      return await _cloudinaryService.uploadCommunityProfileImage(
        communityId,
        imageFile,
      );
    } catch (e) {
      throw Exception(
        'Failed to upload community profile image: ${e.toString()}',
      );
    }
  }

  /// Upload community banner image
  Future<String> uploadCommunityBannerImage(
    String communityId,
    File imageFile,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Check if user is anonymous
      if (_authService.isAnonymous) {
        throw Exception('Anonymous users cannot upload images.');
      }

      return await _cloudinaryService.uploadCommunityBannerImage(
        communityId,
        imageFile,
      );
    } catch (e) {
      throw Exception(
        'Failed to upload community banner image: ${e.toString()}',
      );
    }
  }

  /// Update community profile image
  Future<String> updateCommunityProfileImage(
    String communityId,
    File imageFile,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Check if user has permission to edit community
      final memberDoc = await _firestore
          .collection('communities')
          .doc(communityId)
          .collection('members')
          .doc(userId)
          .get();

      final memberRole = memberDoc.data()?['role'] ?? 'member';
      if (memberRole != 'admin' && memberRole != 'owner') {
        throw Exception('Insufficient permissions to update community images');
      }

      // Upload new image
      final imageUrl = await uploadCommunityProfileImage(
        communityId,
        imageFile,
      );

      // Update community document
      await _firestore.collection('communities').doc(communityId).update({
        'photoUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return imageUrl;
    } catch (e) {
      throw Exception(
        'Failed to update community profile image: ${e.toString()}',
      );
    }
  }

  /// Update community banner image
  Future<String> updateCommunityBannerImage(
    String communityId,
    File imageFile,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Check if user has permission to edit community
      final memberDoc = await _firestore
          .collection('communities')
          .doc(communityId)
          .collection('members')
          .doc(userId)
          .get();

      final memberRole = memberDoc.data()?['role'] ?? 'member';
      if (memberRole != 'admin' && memberRole != 'owner') {
        throw Exception('Insufficient permissions to update community images');
      }

      // Upload new image
      final imageUrl = await uploadCommunityBannerImage(communityId, imageFile);

      // Update community document
      await _firestore.collection('communities').doc(communityId).update({
        'bannerUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return imageUrl;
    } catch (e) {
      throw Exception(
        'Failed to update community banner image: ${e.toString()}',
      );
    }
  }
}
