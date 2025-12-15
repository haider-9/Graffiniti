import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/community.dart';
import '../models/community_post.dart';
import '../data/dummy_communities.dart';
import '../widgets/community_card.dart';
import '../widgets/community_post_card.dart';

class CommunitiesPage extends StatefulWidget {
  const CommunitiesPage({super.key});

  @override
  State<CommunitiesPage> createState() => _CommunitiesPageState();
}

class _CommunitiesPageState extends State<CommunitiesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Community> _communities = DummyCommunities.getCommunities();
  final List<CommunityPost> _posts = DummyCommunities.getPosts();
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleJoinCommunity(String communityId) {
    setState(() {
      final index = _communities.indexWhere((c) => c.id == communityId);
      if (index != -1) {
        final community = _communities[index];
        _communities[index] = Community(
          id: community.id,
          name: community.name,
          description: community.description,
          imageUrl: community.imageUrl,
          memberCount: community.isJoined
              ? community.memberCount - 1
              : community.memberCount + 1,
          isJoined: !community.isJoined,
          tags: community.tags,
        );
      }
    });
  }

  void _toggleLikePost(String postId) {
    setState(() {
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final post = _posts[index];
        _posts[index] = CommunityPost(
          id: post.id,
          communityId: post.communityId,
          communityName: post.communityName,
          authorId: post.authorId,
          authorName: post.authorName,
          authorAvatar: post.authorAvatar,
          imageUrl: post.imageUrl,
          caption: post.caption,
          likes: post.isLiked ? post.likes - 1 : post.likes + 1,
          comments: post.comments,
          isLiked: !post.isLiked,
          isSaved: post.isSaved,
          createdAt: post.createdAt,
        );
      }
    });
  }

  void _toggleSavePost(String postId) {
    setState(() {
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final post = _posts[index];
        _posts[index] = CommunityPost(
          id: post.id,
          communityId: post.communityId,
          communityName: post.communityName,
          authorId: post.authorId,
          authorName: post.authorName,
          authorAvatar: post.authorAvatar,
          imageUrl: post.imageUrl,
          caption: post.caption,
          likes: post.likes,
          comments: post.comments,
          isLiked: post.isLiked,
          isSaved: !post.isSaved,
          createdAt: post.createdAt,
        );
      }
    });
  }

  List<CommunityPost> get _filteredPosts {
    if (_selectedFilter == 'All') return _posts;
    return _posts
        .where((post) => post.communityName == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildFeedTab(), _buildCommunitiesTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(
              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
            ),
            child: const Icon(
              Icons.groups_rounded,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'communities',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          _buildIconButton(Icons.search, () {}),
          const SizedBox(width: 8),
          _buildIconButton(Icons.notifications_outlined, () {}),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.accentGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(25),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        unselectedLabelColor: AppTheme.secondaryText,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        tabs: const [
          Tab(text: 'Feed'),
          Tab(text: 'Discover'),
        ],
      ),
    );
  }

  Widget _buildFeedTab() {
    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: _filteredPosts.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 20),
                  itemCount: _filteredPosts.length,
                  itemBuilder: (context, index) {
                    return CommunityPostCard(
                      post: _filteredPosts[index],
                      onLike: () => _toggleLikePost(_filteredPosts[index].id),
                      onSave: () => _toggleSavePost(_filteredPosts[index].id),
                      onComment: () {},
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      'All',
      ..._communities.where((c) => c.isJoined).map((c) => c.name),
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;

          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected ? AppTheme.primaryGradient : null,
                color: isSelected ? null : AppTheme.secondaryBlack,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.secondaryText,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommunitiesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _communities.length,
      itemBuilder: (context, index) {
        return CommunityCard(
          community: _communities[index],
          onJoinToggle: () => _toggleJoinCommunity(_communities[index].id),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.secondaryBlack,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: const Icon(
              Icons.photo_library_outlined,
              size: 50,
              color: AppTheme.secondaryText,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No posts yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Join communities to see their posts',
            style: TextStyle(color: AppTheme.secondaryText, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
