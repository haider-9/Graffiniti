import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/glassmorphic_container.dart';
import '../core/widgets/gradient_button.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _tabIndex = 0;
  final List<String> _tabs = ['Graffiti', 'Saved', 'Liked'];

  final List<Map<String, dynamic>> _userGraffiti = [
    {
      'title': 'Urban Flow',
      'location': 'Downtown',
      'likes': 234,
      'color': AppTheme.accentOrange,
      'time': '2d ago',
    },
    {
      'title': 'City Lights',
      'location': 'Art District',
      'likes': 189,
      'color': AppTheme.accentBlue,
      'time': '5d ago',
    },
    {
      'title': 'Street Canvas',
      'location': 'Gallery District',
      'likes': 456,
      'color': AppTheme.accentGreen,
      'time': '1w ago',
    },
    {
      'title': 'Wall Stories',
      'location': 'Main Street',
      'likes': 321,
      'color': AppTheme.accentPurple,
      'time': '2w ago',
    },
  ];



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildProfileInfo()),
              SliverToBoxAdapter(child: _buildStats()),
              SliverToBoxAdapter(child: _buildActionButtons()),
              SliverToBoxAdapter(child: _buildTabBar()),
              _buildContent(),
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
          const Text(
            'Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  // Settings
                },
                child: GlassmorphicContainer(
                  width: 44,
                  height: 44,
                  borderRadius: BorderRadius.circular(22),
                  child: const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  // Menu
                },
                child: GlassmorphicContainer(
                  width: 44,
                  height: 44,
                  borderRadius: BorderRadius.circular(22),
                  child: const Icon(Icons.menu, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentOrange.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.secondaryBlack,
                ),
                child: const CircleAvatar(
                  radius: 47,
                  backgroundColor: Colors.transparent,
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primaryBlack,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.verified,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Alex Rivera',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '@alexrivera_art',
          style: TextStyle(color: AppTheme.secondaryText, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'AR Artist',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStat('42', 'Graffiti'),
          _buildStat('1.2K', 'Followers'),
          _buildStat('234', 'Following'),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: AppTheme.secondaryText, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: GradientButton(
              text: 'Edit Profile',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfilePage(),
                  ),
                );
              },
              icon: Icons.edit,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.accentGray,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white24),
            ),
            child: const Icon(Icons.share, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.accentGray,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _tabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppTheme.primaryGradient : null,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  _tabs[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.secondaryText,
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildContent() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final graffiti = _userGraffiti[index];
            return _buildGraffitiItem(graffiti, index);
          },
          childCount: _userGraffiti.length,
        ),
      ),
    );
  }

  Widget _buildGraffitiItem(Map<String, dynamic> graffiti, int index) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: graffiti['color'].withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Graffiti preview
          Expanded(
            child: Container(
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
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.view_in_ar,
                      size: 32,
                      color: graffiti['color'],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      graffiti['title'],
                      style: TextStyle(
                        color: graffiti['color'],
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Graffiti info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppTheme.secondaryText,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        graffiti['location'],
                        style: const TextStyle(
                          color: AppTheme.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          size: 14,
                          color: AppTheme.accentRed,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${graffiti['likes']}',
                          style: const TextStyle(
                            color: AppTheme.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      graffiti['time'],
                      style: const TextStyle(
                        color: AppTheme.mutedText,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
