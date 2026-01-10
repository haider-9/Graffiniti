import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_model/community_view_model.dart';
import 'community_card.dart';
import 'community_detail_screen.dart';
import 'create_community_screen.dart';
import '../../../core/theme/app_theme.dart';

class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityViewModel>().loadCommunities();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<CommunityViewModel>().clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlack,
        title: const Text('Communities', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateCommunityScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: Consumer<CommunityViewModel>(
                builder: (context, viewModel, child) {
                  // Show search results if searching
                  if (viewModel.hasSearchQuery) {
                    return _buildSearchResults(viewModel);
                  }

                  // Show regular communities list
                  if (viewModel.loading && viewModel.communities.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.accentOrange,
                      ),
                    );
                  }

                  if (viewModel.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: AppTheme.accentRed,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${viewModel.error}',
                            style: const TextStyle(color: AppTheme.accentRed),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => viewModel.loadCommunities(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (viewModel.communities.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.groups_outlined,
                            size: 48,
                            color: AppTheme.secondaryText,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No communities found',
                            style: TextStyle(
                              color: AppTheme.secondaryText,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => viewModel.loadCommunities(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: viewModel.communities.length,
                      itemBuilder: (context, index) {
                        final community = viewModel.communities[index];
                        return CommunityCard(
                          community: community,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CommunityDetailScreen(community: community),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Consumer<CommunityViewModel>(
        builder: (context, viewModel, child) {
          return TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            onChanged: (query) {
              viewModel.searchCommunities(query);
            },
            decoration: InputDecoration(
              hintText: 'Search communities...',
              hintStyle: const TextStyle(color: AppTheme.secondaryText),
              prefixIcon: const Icon(
                Icons.search,
                color: AppTheme.secondaryText,
              ),
              suffixIcon: viewModel.hasSearchQuery
                  ? IconButton(
                      onPressed: _clearSearch,
                      icon: const Icon(
                        Icons.clear,
                        color: AppTheme.secondaryText,
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchResults(CommunityViewModel viewModel) {
    if (viewModel.searching) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accentOrange),
      );
    }

    if (!viewModel.hasSearchQuery) {
      return const Center(
        child: Text(
          'Start typing to search communities...',
          style: TextStyle(color: AppTheme.secondaryText),
        ),
      );
    }

    if (viewModel.searchResults.isEmpty) {
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
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.searchResults.length,
      itemBuilder: (context, index) {
        final community = viewModel.searchResults[index];
        return CommunityCard(
          community: community,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    CommunityDetailScreen(community: community),
              ),
            );
          },
        );
      },
    );
  }
}
