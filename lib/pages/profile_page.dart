import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/account_upgrade_dialog.dart';
import '../core/widgets/logout_dialog.dart';
import '../core/services/auth_service.dart';
import '../core/services/user_service.dart';
import '../core/services/share_service.dart';
import 'settings_page.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _tabIndex = 0;
  final List<String> _tabs = ['My Art', 'Saved', 'Liked'];
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  User? _currentUser;
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.currentUser;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final userData = await _userService.getUserData(user.uid);
        if (mounted) {
          setState(() {
            _userData = userData ?? {};
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.secondaryBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white),
              title: const Text(
                'Settings',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_outlined, color: Colors.red),
              title: const Text(
                'Report Issue',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                // Report functionality
              },
            ),
            const Divider(color: Colors.white12),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => const LogoutDialog(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentOrange),
            )
          : CustomScrollView(
              slivers: [_buildProfileHeader(), _buildProfileContent()],
            ),
    );
  }

  Widget _buildProfileHeader() {
    final user = _currentUser;
    final displayName = _userData['displayName'] ?? user?.displayName ?? 'User';
    final profileImageUrl = _userData['profileImageUrl'] ?? user?.photoURL;
    final bannerImageUrl = _userData['bannerImageUrl'];
    final bio = _userData['bio'] ?? 'Click here to fill in the profile';
    final userId = user?.uid != null
        ? user!.uid.substring(0, 10)
        : '0000000000';

    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryBlack,
      elevation: 0,
      actions: [
        GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EditProfilePage()),
            );
            // Refresh profile data if edit was successful
            if (result == true) {
              _loadUserData();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Text(
              'Edit Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),
        GestureDetector(
          onTap: () async {
            await ShareService.shareProfile(
              displayName: displayName,
              userId: userId,
              bio: bio != 'Click here to fill in the profile' ? bio : null,
              profileImageUrl: profileImageUrl,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.share_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () {
            _showProfileMenu();
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Banner background
            Container(
              decoration: BoxDecoration(
                gradient: bannerImageUrl != null
                    ? null
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF4A6B7C),
                          Color(0xFF5A7B8C),
                          Color(0xFF6A8B9C),
                        ],
                      ),
              ),
              child: bannerImageUrl != null
                  ? Image.network(
                      bannerImageUrl,
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
                  : null,
            ),
            // Dark gradient overlay for better readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
            // Profile content
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Profile picture
                      GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfilePage(),
                            ),
                          );
                          // Refresh profile data if edit was successful
                          if (result == true) {
                            _loadUserData();
                          }
                        },
                        child: Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                color: Colors.white,
                              ),
                              child: ClipOval(
                                child: profileImageUrl != null
                                    ? Image.network(
                                        profileImageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  color: AppTheme.accentBlue,
                                                  child: const Icon(
                                                    Icons.person,
                                                    color: Colors.white,
                                                    size: 40,
                                                  ),
                                                ),
                                      )
                                    : Container(
                                        color: AppTheme.accentBlue,
                                        child: const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 40,
                                        ),
                                      ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: AppTheme.accentOrange,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // User info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
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
                            if (_authService.isAnonymous) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentOrange.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.accentOrange,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'Guest Account',
                                  style: TextStyle(
                                    color: AppTheme.accentOrange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              'Artist ID: $userId 🎨',
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
                    bio,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    return SliverToBoxAdapter(
      child: Container(
        color: AppTheme.primaryBlack,
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Stats row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildStatColumn('0', 'Following'),
                  const SizedBox(width: 40),
                  _buildStatColumn('0', 'Followers'),
                  const SizedBox(width: 40),
                  _buildStatColumn('0', 'Likes&Views'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Action buttons
            if (_authService.isAnonymous)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => const AccountUpgradeDialog(),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upgrade, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Upgrade Account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 30),
            // Content tabs
            _buildContentTabs(),
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

  Widget _buildContentTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Tab bar
          Row(
            children: _tabs.asMap().entries.map((entry) {
              final index = entry.key;
              final tab = entry.value;
              final isSelected = _tabIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tabIndex = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected
                              ? AppTheme.accentOrange
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      tab,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.6),
                        fontSize: 16,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          // Tab content
          SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _tabIndex == 0
                        ? Icons.view_in_ar_outlined
                        : _tabIndex == 1
                        ? Icons.bookmark_outline
                        : Icons.favorite_outline,
                    color: Colors.white.withValues(alpha: 0.4),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _tabIndex == 0
                        ? 'No AR graffiti created yet\nStart creating in AR Studio!'
                        : 'No ${_tabs[_tabIndex].toLowerCase()} items yet',
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
}
