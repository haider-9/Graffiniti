class CommunityMember {
  final String userId;
  final String displayName;
  final String profileImageUrl;
  final String role; // 'owner', 'admin', 'moderator', 'member'
  final DateTime joinedAt;
  final bool isActive;

  CommunityMember({
    required this.userId,
    required this.displayName,
    required this.profileImageUrl,
    required this.role,
    required this.joinedAt,
    required this.isActive,
  });

  factory CommunityMember.fromMap(Map<String, dynamic> map) {
    return CommunityMember(
      userId: map['userId'] ?? '',
      displayName: map['displayName'] ?? 'Unknown User',
      profileImageUrl: map['profileImageUrl'] ?? '',
      role: map['role'] ?? 'member',
      joinedAt: map['joinedAt']?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
      'role': role,
      'joinedAt': joinedAt,
      'isActive': isActive,
    };
  }

  String get roleDisplayName {
    switch (role) {
      case 'owner':
        return 'Owner';
      case 'admin':
        return 'Admin';
      case 'moderator':
        return 'Moderator';
      case 'member':
      default:
        return 'Member';
    }
  }

  bool get canManageMembers {
    return role == 'owner' || role == 'admin';
  }

  bool get canModerate {
    return role == 'owner' || role == 'admin' || role == 'moderator';
  }
}
