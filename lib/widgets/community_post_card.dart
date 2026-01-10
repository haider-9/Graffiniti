import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/community_post.dart';
import '../core/services/share_service.dart';

class CommunityPostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onComment;

  const CommunityPostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onSave,
    required this.onComment,
  });

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildImage(context),
          _buildActions(),
          _buildCaption(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
            ),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.secondaryBlack,
              ),
              child: ClipOval(
                child: Image.network(
                  post.authorAvatar,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24,
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Author info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.authorName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        post.communityName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• ${_formatTimeAgo(post.createdAt)}',
                      style: const TextStyle(
                        color: AppTheme.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // More button
          IconButton(
            icon: const Icon(
              Icons.more_horiz,
              color: AppTheme.secondaryText,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    return GestureDetector(
      onDoubleTap: onLike,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(
          maxHeight: 400,
        ),
        child: Image.network(
          post.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 300,
              color: AppTheme.accentGray,
              child: const Icon(
                Icons.image_outlined,
                size: 50,
                color: AppTheme.secondaryText,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildActionButton(
            icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
            label: _formatCount(post.likes),
            color: post.isLiked ? AppTheme.accentRed : Colors.white,
            onTap: onLike,
          ),
          const SizedBox(width: 20),
          _buildActionButton(
            icon: Icons.chat_bubble_outline,
            label: _formatCount(post.comments),
            color: Colors.white,
            onTap: onComment,
          ),
          const SizedBox(width: 20),
          _buildActionButton(
            icon: Icons.share_outlined,
            label: 'Share',
            color: Colors.white,
            onTap: () async {
              await ShareService.shareGraffiti(
                title: post.caption.isNotEmpty ? post.caption : 'Community Post',
                artistName: post.username,
                location: null,
                graffitiId: post.id,
              );
            },
          ),
          const Spacer(),
          GestureDetector(
            onTap: onSave,
            child: Icon(
              post.isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: post.isSaved ? AppTheme.accentOrange : Colors.white,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaption() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.4,
          ),
          children: [
            TextSpan(
              text: '${post.authorName} ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: post.caption),
          ],
        ),
      ),
    );
  }
}
