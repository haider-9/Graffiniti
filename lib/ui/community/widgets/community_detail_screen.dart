import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../domain/models/community.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/community_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/account_upgrade_dialog.dart';
import '../../../core/utils/toast_helper.dart';
import 'edit_community_screen.dart';

class CommunityDetailScreen extends StatefulWidget {
  final Community community;

  const CommunityDetailScreen({super.key, required this.community});

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  final CommunityService _communityService = CommunityService();
  final AuthService _authService = AuthService();
  bool _isJoined = false;
  bool _isJoining = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkMembershipStatus();
  }

  Future<void> _checkMembershipStatus() async {
    try {
      final isJoined = await _communityService.isMember(widget.community.id);
      if (mounted) {
        setState(() {
          _isJoined = isJoined;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleJoinCommunity() async {
    // Check if user is anonymous
    if (_authService.isAnonymous) {
      _showUpgradeAccountDialog();
      return;
    }

    if (_isJoining) return;

    setState(() {
      _isJoining = true;
    });

    try {
      if (_isJoined) {
        await _communityService.leaveCommunity(widget.community.id);
        setState(() {
          _isJoined = false;
        });
        if (mounted) {
          ToastHelper.success(context, 'Left community successfully');
        }
      } else {
        await _communityService.joinCommunity(widget.community.id);
        setState(() {
          _isJoined = true;
        });
        if (mounted) {
          ToastHelper.success(context, 'Joined community successfully');
        }
      }
    } catch (e) {
      if (mounted) {
        final action = _isJoined ? 'leave' : 'join';
        ToastHelper.error(context, 'Failed to $action community');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  void _showUpgradeAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => const AccountUpgradeDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: CustomScrollView(
          slivers: [_buildSliverAppBar(), _buildCommunityContent()],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryBlack,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
          ),
          color: AppTheme.secondaryBlack,
          onSelected: (value) {
            switch (value) {
              case 'members':
                _showMembersDialog();
                break;
              case 'rules':
                _showRulesDialog();
                break;
              case 'settings':
                _editCommunity(context);
                break;
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'members',
              child: Row(
                children: [
                  Icon(Icons.people, size: 20, color: Colors.white),
                  SizedBox(width: 12),
                  Text('View Members', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            if (widget.community.rules.isNotEmpty)
              const PopupMenuItem<String>(
                value: 'rules',
                child: Row(
                  children: [
                    Icon(Icons.rule, size: 20, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Show Rules', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            if (_isCreator())
              const PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Settings', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
          ],
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Banner/Cover Image
            _buildCoverImage(),
            // Dark gradient overlay for better visual hierarchy
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.1),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  stops: const [0.0, 0.2, 0.6, 1.0],
                ),
              ),
            ),
            // Community info positioned at the bottom like profile page
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _buildCommunityInfo(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage() {
    if (widget.community.bannerUrl.isNotEmpty) {
      return Image.network(
        widget.community.bannerUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildDefaultCover(),
      );
    }
    return _buildDefaultCover();
  }

  Widget _buildDefaultCover() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A6B7C), Color(0xFF5A7B8C), Color(0xFF6A8B9C)],
        ),
      ),
    );
  }

  Widget _buildCommunityInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Community profile picture
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: widget.community.photoUrl.isNotEmpty
                    ? Image.network(
                        widget.community.photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildDefaultProfileImage(),
                      )
                    : _buildDefaultProfileImage(),
              ),
            ),
            const SizedBox(width: 16),
            // Community info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.community.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${widget.community.handle}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      shadows: const [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 2,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          widget.community.description,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.95),
            fontSize: 16,
            shadows: const [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 2,
                color: Colors.black54,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultProfileImage() {
    return Container(
      color: AppTheme.accentBlue,
      child: Center(
        child: Text(
          widget.community.name.isNotEmpty
              ? widget.community.name[0].toUpperCase()
              : 'C',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityContent() {
    return SliverToBoxAdapter(
      child: Container(
        color: AppTheme.primaryBlack,
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Stats row like profile page
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildStatColumn(
                    widget.community.stats.memberCount.toString(),
                    'Members',
                  ),
                  const SizedBox(width: 40),
                  _buildStatColumn(
                    widget.community.stats.postCount.toString(),
                    'Posts',
                  ),
                  const SizedBox(width: 40),
                  _buildStatColumn(
                    widget.community.stats.graffinitiCount.toString(),
                    'Graffiti',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Join button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildJoinButton(),
            ),
            const SizedBox(height: 20),
            // Tags if available
            if (widget.community.tags.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildTags(),
              ),
              const SizedBox(height: 20),
            ],
            // Content tabs like profile page
            _buildPostsContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildJoinButton() {
    if (_isLoading || _isJoining) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.accentGray,
          borderRadius: BorderRadius.circular(25),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleJoinCommunity,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: _isJoined ? null : AppTheme.primaryGradient,
          color: _isJoined ? AppTheme.accentGray : null,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: _isJoined
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.transparent,
          ),
          boxShadow: _isJoined
              ? null
              : [
                  BoxShadow(
                    color: AppTheme.accentOrange.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isJoined ? Icons.check : Icons.add,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              _isJoined ? 'Joined' : 'Join Community',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTags() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: widget.community.tags.map((tag) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accentGray,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Text(
              '#$tag',
              style: const TextStyle(
                color: AppTheme.secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPostsContent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Posts',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Posts content
          SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.article_outlined,
                    color: Colors.white.withValues(alpha: 0.4),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No posts yet\nBe the first to share something!',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isCreator() {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser != null && currentUser.uid == widget.community.createdBy;
  }

  void _showMembersDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.secondaryBlack,
          title: Row(
            children: [
              Icon(Icons.people, color: AppTheme.accentOrange, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Community Members',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    color: Colors.white.withValues(alpha: 0.4),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${widget.community.stats.memberCount} members',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Member list coming soon!',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(color: AppTheme.accentOrange),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  void _showRulesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.secondaryBlack,
          title: Row(
            children: [
              Icon(Icons.rule, color: AppTheme.accentOrange, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Community Rules',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.community.rules.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.accentOrange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppTheme.accentOrange,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.community.rules[index],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(color: AppTheme.accentOrange),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  void _editCommunity(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EditCommunityScreen(community: widget.community),
      ),
    );

    if (result == true) {
      // Community was updated, you might want to refresh the data
      // or show a success message
    }
  }
}
