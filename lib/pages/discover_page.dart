import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/debouncer.dart';
import '../core/widgets/glassmorphic_container.dart';
import '../data/services/graffiti_data_service.dart';
import 'map_page.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _searchDebouncer = Debouncer(milliseconds: 500);
  final GraffitiDataService _graffitiService = GraffitiDataService();

  final List<String> _tabs = ['Nearby', 'Trending', 'Following'];
  String _searchQuery = '';
  bool _showSearchBar = false;
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _nearbyGraffiti = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationController.forward();
    _searchController.addListener(_onSearchChanged);
    _loadNearbyGraffiti();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _searchController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  void _loadNearbyGraffiti() {
    setState(() {
      _nearbyGraffiti = _graffitiService.getDiscoverGraffiti();
    });
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
      // Use unified service for search
      final results = _graffitiService.searchGraffiti(query);

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      // Fallback to empty results
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  void _toggleSearch() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        _searchController.clear();
        _searchQuery = '';
        _searchResults = [];
        _isSearching = false;
      }
    });
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
              if (_showSearchBar) _buildSearchBar(),
              _buildTabBar(),
              Expanded(
                child: _showSearchBar && _searchQuery.isNotEmpty
                    ? _buildSearchResults()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildNearbyTab(),
                          _buildTrendingTab(),
                          _buildFollowingTab(),
                        ],
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Discover',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Explore AR graffiti around you',
                style: TextStyle(color: AppTheme.secondaryText, fontSize: 12),
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: _toggleSearch,
                child: GlassmorphicContainer(
                  width: 44,
                  height: 44,
                  borderRadius: BorderRadius.circular(22),
                  child: Icon(
                    _showSearchBar ? Icons.close : Icons.search,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MapPage()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentOrange.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.location_pin, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
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
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search graffiti, artists, locations...',
          hintStyle: const TextStyle(color: AppTheme.secondaryText),
          prefixIcon: const Icon(Icons.search, color: AppTheme.secondaryText),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                  },
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
          'Start typing to search...',
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
              'No graffiti found',
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
        final graffiti = _searchResults[index];
        return _buildGraffitiCard(graffiti, index);
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.accentGray,
        borderRadius: BorderRadius.circular(25),
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
        tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
      ),
    );
  }

  Widget _buildNearbyTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _nearbyGraffiti.length,
      itemBuilder: (context, index) {
        final graffiti = _nearbyGraffiti[index];
        return _buildGraffitiCard(graffiti, index);
      },
    );
  }

  Widget _buildTrendingTab() {
    final trendingGraffiti = _graffitiService.getTrendingGraffiti();

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: trendingGraffiti.length,
      itemBuilder: (context, index) {
        final graffiti = trendingGraffiti[index];
        return _buildGraffitiCard(graffiti, index);
      },
    );
  }

  Widget _buildFollowingTab() {
    return const Center(
      child: Text(
        'Following feed coming soon',
        style: TextStyle(color: AppTheme.secondaryText),
      ),
    );
  }

  Widget _buildGraffitiCard(Map<String, dynamic> graffiti, int index) {
  return AnimatedBuilder(
    animation: _animationController,
    builder: (context, child) {
      final slideAnimation = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            (index * 0.1).clamp(0.0, 0.7),
            ((index * 0.1) + 0.3).clamp(0.3, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      );

      // Reusable fallback/placeholder widget
      Widget fallbackPreview() {
        return Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                graffiti['color'].withValues(alpha: 0.3),
                graffiti['color'].withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.view_in_ar,
                  size: 48,
                  color: graffiti['color'],
                ),
                const SizedBox(height: 8),
                Text(
                  graffiti['title'],
                  style: TextStyle(
                    color: graffiti['color'],
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Image widget with fallback and loading
      Widget graffitiImage() {
        final imageUrl = graffiti['imageUrl'];
        if (imageUrl == null || imageUrl.isEmpty) return fallbackPreview();

        return SizedBox(
          height: 200,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  alignment: Alignment.center,
                  color: AppTheme.secondaryBlack,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(graffiti['color']),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return fallbackPreview();
              },
            ),
          ),
        );
      }

      return SlideTransition(
        position: slideAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppTheme.secondaryBlack,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: graffiti['color'].withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              graffitiImage(), // image with fallback

              // Graffiti info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: graffiti['color'],
                          child: Text(
                            graffiti['artist'][1].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                graffiti['artist'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                graffiti['time'],
                                style: const TextStyle(
                                  color: AppTheme.mutedText,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: graffiti['color'].withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            graffiti['distance'],
                            style: TextStyle(
                              color: graffiti['color'],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: AppTheme.secondaryText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          graffiti['address'] ??
                              graffiti['location'] ??
                              'Unknown location',
                          style: const TextStyle(
                            color: AppTheme.secondaryText,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.favorite_outline,
                              size: 20,
                              color: AppTheme.secondaryText,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${graffiti['likes']}',
                              style: const TextStyle(
                                color: AppTheme.secondaryText,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.view_in_ar,
                                size: 16,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'View in AR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}


}
