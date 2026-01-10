import '../models/community.dart';
import '../models/community_post.dart';

/// Dummy data for communities and posts
/// Used for demonstration purposes
class DummyCommunities {
  /// Get a list of dummy communities
  static List<Community> getCommunities() {
    return [
      Community(
        id: 'community_1',
        name: 'Street Art Masters',
        description:
            'A community for professional street artists and graffiti enthusiasts. Share your latest works and get feedback from the pros.',
        imageUrl:
            'https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=400',
        memberCount: 1247,
        isJoined: true,
        tags: ['street-art', 'graffiti', 'urban', 'professional'],
      ),
      Community(
        id: 'community_2',
        name: 'Urban Canvas',
        description:
            'Transform the city into your canvas. Discover the best spots and share your urban art adventures.',
        imageUrl:
            'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
        memberCount: 892,
        isJoined: false,
        tags: ['urban', 'canvas', 'city', 'art'],
      ),
      Community(
        id: 'community_3',
        name: 'Digital Graffiti',
        description:
            'Explore the future of graffiti with AR and digital art. Create virtual masterpieces that come to life.',
        imageUrl:
            'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=400',
        memberCount: 634,
        isJoined: true,
        tags: ['digital', 'ar', 'virtual', 'future'],
      ),
      Community(
        id: 'community_4',
        name: 'Beginner Bombers',
        description:
            'New to graffiti? Start here! Learn the basics, get tips from experienced artists, and practice your skills.',
        imageUrl:
            'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
        memberCount: 2156,
        isJoined: false,
        tags: ['beginner', 'learning', 'tips', 'practice'],
      ),
      Community(
        id: 'community_5',
        name: 'Legal Walls',
        description:
            'Find and share information about legal graffiti walls and sanctioned art spaces around the world.',
        imageUrl:
            'https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=400',
        memberCount: 445,
        isJoined: true,
        tags: ['legal', 'walls', 'sanctioned', 'worldwide'],
      ),
      Community(
        id: 'community_6',
        name: 'Stencil Society',
        description:
            'Master the art of stencil graffiti. Share templates, techniques, and showcase your precision work.',
        imageUrl:
            'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=400',
        memberCount: 789,
        isJoined: false,
        tags: ['stencil', 'templates', 'precision', 'technique'],
      ),
    ];
  }

  /// Get a list of dummy community posts
  static List<CommunityPost> getPosts() {
    return [
      CommunityPost(
        id: 'post_1',
        communityId: 'community_1',
        communityName: 'Street Art Masters',
        authorId: 'user_1',
        authorName: 'ArtistX',
        authorAvatar:
            'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
        imageUrl:
            'https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=600',
        caption:
            'Just finished this piece on the east side. What do you think about the color combination? 🎨',
        likes: 127,
        comments: 23,
        isLiked: false,
        isSaved: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      CommunityPost(
        id: 'post_2',
        communityId: 'community_3',
        communityName: 'Digital Graffiti',
        authorId: 'user_2',
        authorName: 'DigitalDreamer',
        authorAvatar:
            'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=100',
        imageUrl:
            'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=600',
        caption:
            'AR graffiti experiment - this dragon only appears when you scan the wall! 🐉✨',
        likes: 89,
        comments: 15,
        isLiked: true,
        isSaved: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      CommunityPost(
        id: 'post_3',
        communityId: 'community_1',
        communityName: 'Street Art Masters',
        authorId: 'user_3',
        authorName: 'UrbanLegend',
        authorAvatar:
            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100',
        imageUrl:
            'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=600',
        caption:
            'Collaboration piece with @SprayMaster. Love how our styles complement each other! 🤝',
        likes: 203,
        comments: 41,
        isLiked: true,
        isSaved: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      ),
      CommunityPost(
        id: 'post_4',
        communityId: 'community_5',
        communityName: 'Legal Walls',
        authorId: 'user_4',
        authorName: 'LegalEagle',
        authorAvatar:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
        imageUrl:
            'https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=600',
        caption:
            'Found this amazing legal wall in downtown! Perfect for large pieces. Location in comments 📍',
        likes: 156,
        comments: 67,
        isLiked: false,
        isSaved: false,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      CommunityPost(
        id: 'post_5',
        communityId: 'community_3',
        communityName: 'Digital Graffiti',
        authorId: 'user_5',
        authorName: 'TechArtist',
        authorAvatar:
            'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100',
        imageUrl:
            'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=600',
        caption:
            'Interactive mural that responds to movement. The future of street art is here! 🚀',
        likes: 312,
        comments: 89,
        isLiked: true,
        isSaved: true,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      CommunityPost(
        id: 'post_6',
        communityId: 'community_1',
        communityName: 'Street Art Masters',
        authorId: 'user_6',
        authorName: 'ColorMaster',
        authorAvatar:
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100',
        imageUrl:
            'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=600',
        caption:
            'Experimenting with new spray techniques. This gradient effect took 3 hours! 🌈',
        likes: 178,
        comments: 34,
        isLiked: false,
        isSaved: false,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
  }
}
