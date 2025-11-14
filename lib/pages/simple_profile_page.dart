import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/gradient_button.dart';
import '../core/utils/toast_helper.dart';
import '../core/services/auth_service.dart';
import '../core/services/user_service.dart';
import 'settings_page.dart';
import 'edit_profile_page.dart';

class SimpleProfilePage extends StatefulWidget {
  const SimpleProfilePage({super.key});

  @override
  State<SimpleProfilePage> createState() => _SimpleProfilePageState();
}

class _SimpleProfilePageState extends State<SimpleProfilePage> {
  int _tabIndex = 0;
  final List<String> _tabs = ['Graffiti', 'Saved', 'Liked'];
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.currentUser;
  }

  Future<void> _logout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        ToastHelper.success(context, 'Logged out successfully');
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.genericError(context, e);
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.secondaryBlack,
          title: const Text('Logout', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: AppTheme.secondaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppTheme.secondaryText),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              child: Text(
                'Logout',
                style: TextStyle(color: AppTheme.accentOrange),
              ),
            ),
          ],
        );
      },
    );
  }

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
    if (_currentUser == null) {
      return const Scaffold(
        backgroundColor: AppTheme.primaryBlack,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentOrange),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _userService.getUserStream(_currentUser!.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.accentOrange,
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ToastHelper.loadingError(context, itemName: 'profile');
                });
                return Center(
                  child: Text(
                    'Error loading profile',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }

              final userData = snapshot.data?.data() ?? {};

              return Column(
                children: [
                  _buildHeader(),
                  _buildProfileInfo(userData),
                  _buildStats(userData),
                  _buildActionButtons(),
                  _buildTabBar(),
                  Expanded(child: _buildContent()),
                ],
              );
            },
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(),
                    ),
                  );
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.accentGray,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _showLogoutDialog,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.accentGray,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(Map<String, dynamic> userData) {
    return Column(
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
            child: ClipOval(
              child:
                  userData['profileImageUrl'] != null &&
                      userData['profileImageUrl'].toString().isNotEmpty
                  ? Image.network(
                      userData['profileImageUrl'],
                      fit: BoxFit.cover,
                      width: 94,
                      height: 94,
                      errorBuilder: (context, error, stackTrace) {
                        return const CircleAvatar(
                          radius: 47,
                          backgroundColor: Colors.transparent,
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 48,
                          ),
                        );
                      },
                    )
                  : const CircleAvatar(
                      radius: 47,
                      backgroundColor: Colors.transparent,
                      child: Icon(Icons.person, color: Colors.white, size: 48),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          userData['displayName'] ?? _currentUser?.displayName ?? 'User',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          userData['email'] ?? _currentUser?.email ?? 'user@example.com',
          style: const TextStyle(color: AppTheme.secondaryText, fontSize: 16),
        ),
        if (userData['bio'] != null &&
            userData['bio'].toString().isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              userData['bio'],
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        if (userData['location'] != null &&
            userData['location'].toString().isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppTheme.secondaryText,
              ),
              const SizedBox(width: 4),
              Text(
                userData['location'],
                style: const TextStyle(
                  color: AppTheme.secondaryText,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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

  Widget _buildStats(Map<String, dynamic> userData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStat('${userData['graffitiCount'] ?? 0}', 'Graffiti'),
          _buildStat('${userData['followersCount'] ?? 0}', 'Followers'),
          _buildStat('${userData['followingCount'] ?? 0}', 'Following'),
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
              child: Container(
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        itemCount: _userGraffiti.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemBuilder: (context, index) {
          final graffiti = _userGraffiti[index];
          return _buildGraffitiItem(graffiti);
        },
      ),
    );
  }

  Widget _buildGraffitiItem(Map<String, dynamic> graffiti) {
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
                    Icon(Icons.view_in_ar, size: 32, color: graffiti['color']),
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
                    const Icon(
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
                        const Icon(
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
