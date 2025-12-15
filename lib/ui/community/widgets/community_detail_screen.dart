import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:griffiniti/core/theme/app_theme.dart';
import '../../../domain/models/community.dart';
import 'edit_community_screen.dart';

class CommunityDetailScreen extends StatelessWidget {
  final Community community;

  const CommunityDetailScreen({super.key, required this.community});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            actions: [
              if (_isCreator())
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editCommunity(context),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: community.bannerUrl.isNotEmpty
                  ? Image.network(community.bannerUrl, fit: BoxFit.cover)
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.deepOrange, Colors.black87],
                        ),
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundImage: community.photoUrl.isNotEmpty
                            ? NetworkImage(community.photoUrl)
                            : null,
                        child: community.photoUrl.isEmpty
                            ? Text(
                                community.name[0].toUpperCase(),
                                style: const TextStyle(fontSize: 24),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              community.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '@${community.handle}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Join/Leave community
                        },
                        child: const Text('Join'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    community.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatCard(
                        'Members',
                        community.stats.memberCount.toString(),
                        Icons.people,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        'Posts',
                        community.stats.postCount.toString(),
                        Icons.post_add,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        'Graffiti',
                        community.stats.graffinitiCount.toString(),
                        Icons.brush,
                      ),
                    ],
                  ),
                  if (community.tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    // const Text(
                    //   'Tags',
                    //   style: TextStyle(
                    //     fontSize: 18,
                    //     fontWeight: FontWeight.bold,
                    //   ),
                    // ),
                    // const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: community.tags.map((tag) {
                        return Chip(
                          label: Text("# $tag"),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  if (community.rules.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Community Rules',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...community.rules.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.key + 1}. ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(child: Text(entry.value)),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            spacing: 6,
            children: [
              Icon(icon, size: 24),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isCreator() {
    return true;
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser != null && currentUser.uid == community.createdBy;
  }

  void _editCommunity(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EditCommunityScreen(community: community),
      ),
    );

    if (result == true) {
      // Community was updated, you might want to refresh the data
      // or show a success message
    }
  }
}
