import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/services/community_service.dart';
import '../core/utils/toast_helper.dart';
import '../models/community.dart';
import '../pages/community_members_page.dart';
import '../pages/community_detail_page.dart';

class CommunityCard extends StatefulWidget {
  final Community community;
  final VoidCallback onJoinToggle;

  const CommunityCard({
    super.key,
    required this.community,
    required this.onJoinToggle,
  });

  @override
  State<CommunityCard> createState() => _CommunityCardState();
}

class _CommunityCardState extends State<CommunityCard> {
  final CommunityService _communityService = CommunityService();
  bool _isJoining = false;

  String _formatMemberCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToDetail(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.secondaryBlack,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(
              children: [
                Image.network(
                  community.imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 160,
                      color: AppTheme.accentGray,
                      child: const Icon(
                        Icons.image_outlined,
                        size: 50,
                        color: AppTheme.secondaryText,
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => _navigateToMembers(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.people,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatMemberCount(widget.community.memberCount),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.community.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.community.description,
                            style: const TextStyle(
                              color: AppTheme.secondaryText,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildJoinButton(),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: widget.community.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGray,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: AppTheme.secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  }

  Widget _buildJoinButton() {
    return GestureDetector(
      onTap: _isJoining ? null : _handleJoinToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: widget.community.isJoined ? null : AppTheme.primaryGradient,
          color: widget.community.isJoined ? AppTheme.accentGray : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.community.isJoined
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.transparent,
          ),
        ),
        child: _isJoining
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                widget.community.isJoined ? 'Joined' : 'Join',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  void _navigateToMembers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityMembersPage(community: widget.community),
      ),
    );
  }

  void _navigateToDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityDetailPage(community: widget.community),
      ),
    );
  }

  Future<void> _handleJoinToggle() async {
    setState(() {
      _isJoining = true;
    });

    try {
      if (widget.community.isJoined) {
        await _communityService.leaveCommunity(widget.community.id);
        if (mounted) {
          ToastHelper.success(context, 'Left ${widget.community.name}');
        }
      } else {
        await _communityService.joinCommunity(widget.community.id);
        if (mounted) {
          ToastHelper.success(context, 'Joined ${widget.community.name}!');
        }
      }

      // Call the parent callback to update the UI
      widget.onJoinToggle();
    } catch (e) {
      if (mounted) {
        ToastHelper.error(
          context,
          widget.community.isJoined
              ? 'Failed to leave community'
              : 'Failed to join community',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }
}
