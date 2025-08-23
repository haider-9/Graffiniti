import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _autoSaveEnabled = false;
  bool _highQualityEnabled = true;
  double _brushSensitivity = 0.7;

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
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildSection('General', [
                      _buildSwitchTile(
                        'Push Notifications',
                        'Receive notifications for likes and comments',
                        Icons.notifications_outlined,
                        _notificationsEnabled,
                        (value) =>
                            setState(() => _notificationsEnabled = value),
                      ),
                      _buildSwitchTile(
                        'Location Services',
                        'Allow app to access your location for AR graffiti',
                        Icons.location_on_outlined,
                        _locationEnabled,
                        (value) => setState(() => _locationEnabled = value),
                      ),
                      _buildSwitchTile(
                        'Auto-Save Creations',
                        'Automatically save your graffiti to gallery',
                        Icons.save_outlined,
                        _autoSaveEnabled,
                        (value) => setState(() => _autoSaveEnabled = value),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('AR & Camera', [
                      _buildSwitchTile(
                        'High Quality Rendering',
                        'Better quality but uses more battery',
                        Icons.high_quality_outlined,
                        _highQualityEnabled,
                        (value) => setState(() => _highQualityEnabled = value),
                      ),
                      _buildSliderTile(
                        'Brush Sensitivity',
                        'Adjust how responsive the brush is to movement',
                        Icons.brush_outlined,
                        _brushSensitivity,
                        (value) => setState(() => _brushSensitivity = value),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('Privacy & Safety', [
                      _buildActionTile(
                        'Privacy Settings',
                        'Control who can see your graffiti',
                        Icons.privacy_tip_outlined,
                        () {
                          // Navigate to privacy settings
                        },
                      ),
                      _buildActionTile(
                        'Blocked Users',
                        'Manage blocked users and content',
                        Icons.block_outlined,
                        () {
                          // Navigate to blocked users
                        },
                      ),
                      _buildActionTile(
                        'Report Content',
                        'Report inappropriate content or behavior',
                        Icons.report_outlined,
                        () {
                          // Navigate to report content
                        },
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('Account', [
                      _buildActionTile(
                        'Account Information',
                        'View and edit your account details',
                        Icons.account_circle_outlined,
                        () {
                          // Navigate to account info
                        },
                      ),
                      _buildActionTile(
                        'Data & Storage',
                        'Manage your data and storage usage',
                        Icons.storage_outlined,
                        () {
                          // Navigate to data settings
                        },
                      ),
                      _buildActionTile(
                        'Export Data',
                        'Download your graffiti and account data',
                        Icons.download_outlined,
                        () {
                          // Export data
                        },
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('Support', [
                      _buildActionTile(
                        'Help Center',
                        'Get help and find answers to common questions',
                        Icons.help_outline,
                        () {
                          // Navigate to help
                        },
                      ),
                      _buildActionTile(
                        'Contact Support',
                        'Get in touch with our support team',
                        Icons.support_agent_outlined,
                        () {
                          // Contact support
                        },
                      ),
                      _buildActionTile(
                        'About Griffiniti',
                        'App version and legal information',
                        Icons.info_outline,
                        () {
                          // Show about dialog
                          _showAboutDialog();
                        },
                      ),
                    ]),
                    const SizedBox(height: 32),
                    _buildLogoutButton(),
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
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.accentGray,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.accentOrange,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.secondaryBlack,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.accentGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.accentOrange,
            inactiveThumbColor: Colors.white54,
            inactiveTrackColor: AppTheme.accentGray,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile(
    String title,
    String subtitle,
    IconData icon,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.accentGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.accentOrange,
              inactiveTrackColor: AppTheme.accentGray,
              thumbColor: AppTheme.accentOrange,
              overlayColor: AppTheme.accentOrange.withOpacity(0.2),
            ),
            child: Slider(
              value: value,
              onChanged: onChanged,
              min: 0.0,
              max: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.accentGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.secondaryText,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () {
          _showLogoutDialog();
        },
        borderRadius: BorderRadius.circular(16),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Text(
              'Log Out',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: Image.asset(
                'assets/images/logo.png',
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.brush,
                      color: Colors.white,
                      size: 20,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            const Text('Griffiniti', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version 1.0.0',
              style: TextStyle(color: AppTheme.secondaryText),
            ),
            SizedBox(height: 8),
            Text(
              'AR Graffiti App for creating digital street art in augmented reality.',
              style: TextStyle(color: AppTheme.secondaryText),
            ),
            SizedBox(height: 16),
            Text(
              '© 2024 Griffiniti. All rights reserved.',
              style: TextStyle(color: AppTheme.mutedText, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: AppTheme.accentOrange),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to log out of your account?',
          style: TextStyle(color: AppTheme.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Perform logout
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
