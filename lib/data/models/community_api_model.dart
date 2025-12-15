import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/community.dart';

class CommunityApiModel {
  final String id;
  final String name;
  final String photoUrl;
  final String handle;
  final String description;
  final String createdBy;
  final String bannerUrl;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final List<String> rules;
  final List<String> tags;
  final Map<String, dynamic> stats;
  final String visibility;

  CommunityApiModel({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.handle,
    required this.description,
    required this.createdBy,
    required this.bannerUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.rules,
    required this.tags,
    required this.stats,
    required this.visibility,
  });

  factory CommunityApiModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityApiModel(
      id: doc.id,
      name: data['name'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      handle: data['handle'] ?? '',
      description: data['description'] ?? '',
      createdBy: data['createdBy'] ?? '',
      bannerUrl: data['bannerUrl'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
      rules: List<String>.from(data['rules'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      stats: data['stats'] ?? {},
      visibility: data['visibility'] ?? 'public',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'photoUrl': photoUrl,
      'handle': handle,
      'description': description,
      'createdBy': createdBy,
      'bannerUrl': bannerUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'rules': rules,
      'tags': tags,
      'stats': stats,
      'visibility': visibility,
    };
  }

  // Convert to domain model
  Community toDomain() {
    return Community(
      id: id,
      name: name,
      photoUrl: photoUrl,
      handle: handle,
      description: description,
      createdBy: createdBy,
      bannerUrl: bannerUrl,
      createdAt: createdAt.toDate(),
      updatedAt: updatedAt.toDate(),
      rules: rules,
      tags: tags,
      stats: CommunityStats(
        graffinitiCount: stats['graffinitiCount'] ?? 0,
        memberCount: stats['memberCount'] ?? 0,
        postCount: stats['postCount'] ?? 0,
      ),
      visibility: visibility == 'private'
          ? CommunityVisibility.private
          : CommunityVisibility.public,
    );
  }
}
