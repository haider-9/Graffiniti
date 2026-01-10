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
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppTheme.primaryBlack,
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          color: AppTheme.secondaryBlack,
          onSelected: (value) {
            switch (value) {
              case 'rules':
                _showRulesDialog();
                break;
              case 'settings':
                _editCommunity(context);
                break;
            }
          },
          itemBuilder: (BuildContext context) => [
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
            widget.community.bannerUrl.isNotEmpty
                ? Image.network(
                    widget.community.bannerUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF4A6B7C),
                            Color(0xFF5A7B8C),
                            Color(0xFF6A8B9C),
                          ],
                        ),
                      ),
                    ),
                  )
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF4A6B7C),
                          Color(0xFF5A7B8C),
                          Color(0xFF6A8B9C),
                        ],
                      ),
                    ),
                  ),
            // Dark gradient overlay for better text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityContent() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCommunityHeader(),
            const SizedBox(height: 20),
            _buildDescription(),
            const SizedBox(height: 20),
            _buildStats(),
            if (widget.community.tags.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildTags(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityHeader() {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: widget.community.photoUrl.isNotEmpty
                ? Image.network(
                    widget.community.photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppTheme.accentGray,
                      child: Center(
                        child: Text(
                          widget.community.name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: AppTheme.accentGray,
                    child: Center(
                      child: Text(
                        widget.community.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.community.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '@${widget.community.handle}',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.secondaryText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _buildJoinButton(),
      ],
    );
  }

  Widget _buildJoinButton() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.accentGray,
          borderRadius: BorderRadius.circular(25),
        ),
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    if (_isJoining) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.accentGray,
          borderRadius: BorderRadius.circular(25),
        ),
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleJoinCommunity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
        child: Text(
          _isJoined ? 'Joined' : 'Join',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      widget.community.description,
      style: const TextStyle(fontSize: 16, color: Colors.white, height: 1.5),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        _buildStatCard(
          'Members',
          widget.community.stats.memberCount.toString(),
          Icons.people,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Posts',
          widget.community.stats.postCount.toString(),
          Icons.post_add,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Graffiti',
          widget.community.stats.graffinitiCount.toString(),
          Icons.brush,
        ),
      ],
    );
  }

  Widget _buildTags() {
    return Wrap(
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
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.secondaryBlack,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: AppTheme.accentOrange),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isCreator() {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser != null && currentUser.uid == widget.community.createdBy;
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
