import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/glassmorphic_container.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;

  final List<String> _tabs = ['Nearby', 'Trending', 'Following'];

  final List<Map<String, dynamic>> _nearbyGraffiti = [
    {
      'id': '1',
      'title': 'Urban Flow',
      'artist': '@streetartist',
      'location': 'Downtown Plaza',
      'distance': '50m',
      'likes': 234,
      'time': '2h ago',
      'color': AppTheme.accentOrange,
    },
    {
      'id': '2',
      'title': 'City Pulse',
      'artist': '@graffitiking',
      'location': 'Main Street',
      'distance': '120m',
      'likes': 189,
      'time': '4h ago',
      'color': AppTheme.accentBlue,
    },
    {
      'id': '3',
      'title': 'Street Canvas',
      'artist': '@urbanartist',
      'location': 'Art District',
      'distance': '200m',
      'likes': 456,
      'time': '6h ago',
      'color': AppTheme.accentGreen,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
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
                style: TextStyle(color: AppTheme.secondaryText, fontSize: 16),
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  // Search functionality
                },
                child: GlassmorphicContainer(
                  width: 44,
                  height: 44,
                  borderRadius: BorderRadius.circular(22),
                  child: const Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  // Map view
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
                  child: const Icon(Icons.map, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
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
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.secondaryText,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
    return const Center(
      child: Text(
        'Trending graffiti coming soon',
        style: TextStyle(color: AppTheme.secondaryText),
      ),
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
        final slideAnimation =
            Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  (index * 0.1).clamp(0.0, 0.7),
                  ((index * 0.1) + 0.3).clamp(0.3, 1.0),
                  curve: Curves.easeOutCubic,
                ),
              ),
            );

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
                // Graffiti preview
                Container(
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
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
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
                ),

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
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: AppTheme.secondaryText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            graffiti['location'],
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
                              Icon(
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
