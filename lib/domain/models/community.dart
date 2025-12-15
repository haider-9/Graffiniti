class Community {
  final String id;
  final String name;
  final String photoUrl;
  final String handle;
  final String description;
  final String createdBy;
  final String bannerUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> rules;
  final List<String> tags;
  final CommunityStats stats;
  final CommunityVisibility visibility;

  Community({
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
}

class CommunityStats {
  final int graffinitiCount;
  final int memberCount;
  final int postCount;

  CommunityStats({
    required this.graffinitiCount,
    required this.memberCount,
    required this.postCount,
  });
}

enum CommunityVisibility { public, private }
