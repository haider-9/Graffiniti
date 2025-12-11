import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get user document stream for real-time updates
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  // Get user data once (with offline support)
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      // Try cache first for faster loading
      DocumentSnapshot cachedDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get(const GetOptions(source: Source.cache));
      
      if (cachedDoc.exists) {
        // Return cached data immediately, then fetch fresh data in background
        _firestore
            .collection('users')
            .doc(userId)
            .get(const GetOptions(source: Source.server))
            .catchError((_) {}); // Ignore errors for background fetch
        
        return cachedDoc.data() as Map<String, dynamic>?;
      }
    } catch (_) {
      // Cache miss, continue to server fetch
    }

    // If no cache, fetch from server
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get(const GetOptions(source: Source.server));
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      throw Exception('Failed to get user data: ${e.toString()}');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? displayName,
    String? bio,
    String? location,
    String? website,
    String? profileImageUrl,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (displayName != null) updateData['displayName'] = displayName;
      if (bio != null) updateData['bio'] = bio;
      if (location != null) updateData['location'] = location;
      if (website != null) updateData['website'] = website;
      if (profileImageUrl != null) {
        updateData['profileImageUrl'] = profileImageUrl;
      }

      // Use set with merge to create document if it doesn't exist
      await _firestore.collection('users').doc(userId).set(
        updateData,
        SetOptions(merge: true),
      );

      // Update Firebase Auth display name if provided
      if (displayName != null && _auth.currentUser != null) {
        await _auth.currentUser!.updateDisplayName(displayName);
      }
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  // Update user stats
  Future<void> updateUserStats({
    required String userId,
    int? graffitiCount,
    int? followersCount,
    int? followingCount,
  }) async {
    try {
      Map<String, dynamic> updateData = {};

      if (graffitiCount != null) updateData['graffitiCount'] = graffitiCount;
      if (followersCount != null) updateData['followersCount'] = followersCount;
      if (followingCount != null) updateData['followingCount'] = followingCount;

      if (updateData.isNotEmpty) {
        await _firestore.collection('users').doc(userId).update(updateData);
      }
    } catch (e) {
      throw Exception('Failed to update stats: ${e.toString()}');
    }
  }

  // Get user's graffiti posts
  Stream<QuerySnapshot<Map<String, dynamic>>> getUserGraffiti(String userId) {
    return _firestore
        .collection('graffiti')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Create initial user document with default values
  Future<void> createUserDocument(
    String userId,
    String email,
    String displayName,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'uid': userId,
        'email': email,
        'displayName': displayName,
        'bio': '',
        'location': '',
        'website': '',
        'profileImageUrl': '',
        'graffitiCount': 0,
        'followersCount': 0,
        'followingCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to create user document: ${e.toString()}');
    }
  }

  // Follow/Unfollow user
  Future<void> toggleFollow(String targetUserId) async {
    if (currentUserId == null) return;

    try {
      DocumentReference followRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId);

      DocumentReference followerRef = _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId);

      DocumentSnapshot followDoc = await followRef.get();

      if (followDoc.exists) {
        // Unfollow
        await followRef.delete();
        await followerRef.delete();

        // Update counts
        await _firestore.collection('users').doc(currentUserId).update({
          'followingCount': FieldValue.increment(-1),
        });
        await _firestore.collection('users').doc(targetUserId).update({
          'followersCount': FieldValue.increment(-1),
        });
      } else {
        // Follow
        await followRef.set({'createdAt': FieldValue.serverTimestamp()});
        await followerRef.set({'createdAt': FieldValue.serverTimestamp()});

        // Update counts
        await _firestore.collection('users').doc(currentUserId).update({
          'followingCount': FieldValue.increment(1),
        });
        await _firestore.collection('users').doc(targetUserId).update({
          'followersCount': FieldValue.increment(1),
        });
      }
    } catch (e) {
      throw Exception('Failed to toggle follow: ${e.toString()}');
    }
  }

  // Check if current user is following target user
  Stream<bool> isFollowing(String targetUserId) {
    if (currentUserId == null) return Stream.value(false);

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  // Upload profile image to Firebase Storage
  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      // Create a reference to the profile images folder
      Reference ref = _storage
          .ref()
          .child('profile_images')
          .child('$userId.jpg');

      // Upload the file
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      // Get the download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  // Delete profile image from Firebase Storage
  Future<void> deleteProfileImage(String userId) async {
    try {
      Reference ref = _storage
          .ref()
          .child('profile_images')
          .child('$userId.jpg');

      await ref.delete();
    } catch (e) {
      // Image might not exist, which is fine
      print('Error deleting profile image: $e');
    }
  }

  // Update profile image
  Future<String?> updateProfileImage(String userId, File? imageFile) async {
    try {
      String? imageUrl;

      if (imageFile != null) {
        // Upload new image
        imageUrl = await uploadProfileImage(userId, imageFile);
      } else {
        // Remove image
        await deleteProfileImage(userId);
        imageUrl = '';
      }

      // Update user document with just the image URL
      await _firestore.collection('users').doc(userId).update({
        'profileImageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return imageUrl;
    } catch (e) {
      throw Exception('Failed to update profile image: ${e.toString()}');
    }
  }
}
