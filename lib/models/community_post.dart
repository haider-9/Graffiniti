class CommunityPost {
  final String id;
  final String communityId;
  final String communityName;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String imageUrl;
  final String caption;
  final int likes;
  final int comments;
  final bool isLiked;
  final bool isSaved;
  final DateTime createdAt;

  CommunityPost({
    required this.id,
    required this.communityId,
    required this.communityName,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.imageUrl,
    required this.caption,
    required this.likes,
    required this.comments,
    required this.isLiked,
    required this.isSaved,
    required this.createdAt,
  });
}
