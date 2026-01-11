import 'package:flutter/material.dart';
import '../../../domain/models/community.dart';
import '../../../core/theme/app_theme.dart';

class CommunityCard extends StatelessWidget {
  final Community community;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;
  final bool isJoined;
  final bool isJoining;

  const CommunityCard({
    super.key,
    required this.community,
    this.onTap,
    this.onJoin,
    this.isJoined = false,
    this.isJoining = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.secondaryBlack,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Community Image on the left
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.accentGray,
                  image: community.photoUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(community.photoUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: community.photoUrl.isEmpty
                    ? Center(
                        child: Text(
                          community.name.isNotEmpty
                              ? community.name[0].toUpperCase()
                              : 'C',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : Stack(
                        children: [
                          // Member count overlay
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.people,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${community.stats.memberCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            // Content on the right
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Community name and description
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          community.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          community.description,
                          style: const TextStyle(
                            color: AppTheme.secondaryText,
                            fontSize: 13,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Tags and Join button row
                    Row(
                      children: [
                        // Tags
                        Expanded(
                          child: community.tags.isNotEmpty
                              ? Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: community.tags.take(2).map((tag) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentGray,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.1,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        '#$tag',
                                        style: const TextStyle(
                                          color: AppTheme.secondaryText,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                )
                              : const SizedBox.shrink(),
                        ),

                        const SizedBox(width: 8),

                        // Join button
                        if (onJoin != null)
                          GestureDetector(
                            onTap: () {
                              if (onJoin != null) {
                                onJoin!();
                              }
                            },
                            child: _buildJoinButton(),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinButton() {
    if (isJoining) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.accentGray,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: isJoined ? null : AppTheme.primaryGradient,
        color: isJoined ? AppTheme.accentGray : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isJoined
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.transparent,
        ),
        boxShadow: isJoined
            ? null
            : [
                BoxShadow(
                  color: AppTheme.accentOrange.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Text(
        isJoined ? 'Joined' : 'Join',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          shadows: isJoined
              ? null
              : [
                  const Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 2,
                    color: Colors.black26,
                  ),
                ],
        ),
      ),
    );
  }
}
