import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/debouncer.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _searchDebouncer = Debouncer(milliseconds: 500);

  final List<Community> _allCommunities = DummyCommunities.getCommunities();
  final List<CommunityPost> _posts = DummyCommunities.getPosts();

  List<Community> _searchResults = [];
  String _selectedFilter = 'All';
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    setState(() {
      _searchQuery = query;
    });

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    _searchDebouncer.run(() {
      _performFirebaseSearch(query);
    });
  }

  void _performFirebaseSearch(String query) async {
    try {
      // Simplified Firebase search query without orderBy to avoid index requirement
      final querySnapshot = await FirebaseFirestore.instance
          .collection('communities')
          .where('visibility', isEqualTo: 'public')
          .limit(50) // Get more results to filter locally
          .get();

      // Filter results locally to avoid complex Firebase queries
      final results = querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            return Community(
              id: doc.id,
              name: data['name'] ?? '',
              description: data['description'] ?? '',
              imageUrl: data['photoUrl'] ?? '',
              memberCount: data['stats']?['memberCount'] ?? 0,
              isJoined: false, // TODO: Check user membership
              tags: List<String>.from(data['tags'] ?? []),
            );
          })
          .where((community) {
            final name = community.name.toLowerCase();
            final description = community.description.toLowerCase();
            final tags = community.tags.join(' ').toLowerCase();
            final searchLower = query.toLowerCase();

            return name.contains(searchLower) ||
                description.contains(searchLower) ||
                tags.contains(searchLower);
          })
          .take(20) // Limit final results
          .toList();

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      // Fallback to local search for demo
      await Future.delayed(const Duration(milliseconds: 300));

      final mockResults = _allCommunities.where((community) {
        final name = community.name.toLowerCase();
        final description = community.description.toLowerCase();
        final tags = community.tags.join(' ').toLowerCase();
        final searchLower = query.toLowerCase();

        return name.contains(searchLower) ||
            description.contains(searchLower) ||
            tags.contains(searchLower);
      }).toList();

      if (mounted) {
        setState(() {
          _searchResults = mockResults;
          _isSearching = false;
        });
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _searchResults = [];
      _isSearching = false;
    });
  }

  void _toggleJoinCommunity(String communityId) {
    setState(() {
      final index = _allCommunities.indexWhere((c) => c.id == communityId);
      if (index != -1) {
        final community = _allCommunities[index];
        _allCommunities[index] = Community(
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

        // Update search results as well
        final searchIndex = _searchResults.indexWhere(
          (c) => c.id == communityId,
        );
        if (searchIndex != -1) {
          _searchResults[searchIndex] = _allCommunities[index];
        }
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
              _buildSearchBar(),
              _buildTabBar(),
              Expanded(
                child: _searchQuery.isNotEmpty
                    ? _buildSearchResults()
                    : TabBarView(
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
          const Text(
            'communities',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
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

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search communities by name, description, tags...',
          hintStyle: const TextStyle(color: AppTheme.secondaryText),
          prefixIcon: const Icon(Icons.search, color: AppTheme.secondaryText),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.clear, color: AppTheme.secondaryText),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accentOrange),
      );
    }

    if (_searchQuery.isEmpty) {
      return const Center(
        child: Text(
          'Start typing to search communities...',
          style: TextStyle(color: AppTheme.secondaryText),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: AppTheme.secondaryText),
            SizedBox(height: 16),
            Text(
              'No communities found',
              style: TextStyle(color: AppTheme.secondaryText, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Try different keywords',
              style: TextStyle(color: AppTheme.mutedText, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return CommunityCard(
          community: _searchResults[index],
          onJoinToggle: () => _toggleJoinCommunity(_searchResults[index].id),
        );
      },
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
      ..._allCommunities.where((c) => c.isJoined).map((c) => c.name),
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
      itemCount: _allCommunities.length,
      itemBuilder: (context, index) {
        return CommunityCard(
          community: _allCommunities[index],
          onJoinToggle: () => _toggleJoinCommunity(_allCommunities[index].id),
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
