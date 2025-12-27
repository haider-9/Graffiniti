import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'ar_sphere_page.dart';
import 'ar_graffiti_page.dart';

class ARDemoLauncher extends StatelessWidget {
  const ARDemoLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AR Demos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Demo cards
                Expanded(
                  child: ListView(
                    children: [
                      _buildDemoCard(
                        context,
                        title: 'World-Locked Spheres',
                        description:
                            'Demonstrates proper ARCore anchoring. Spheres stay locked to real-world locations and don\'t drift when you move the camera.',
                        icon: Icons.circle,
                        color: AppTheme.accentOrange,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ARSpherePage(),
                          ),
                        ),
                        features: [
                          '✅ Plane detection',
                          '✅ ARCore anchors',
                          '✅ World-locked positioning',
                          '✅ No camera drift',
                        ],
                      ),

                      const SizedBox(height: 16),

                      _buildDemoCard(
                        context,
                        title: 'AR Stickers (Original)',
                        description:
                            'Your existing AR sticker implementation with various shapes and interactive elements.',
                        icon: Icons.auto_awesome,
                        color: Colors.purple,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ARGraffitiPage(),
                          ),
                        ),
                        features: [
                          '🎨 Multiple sticker types',
                          '🎯 Interactive placement',
                          '📱 Touch gestures',
                          '🎪 Various shapes',
                        ],
                      ),
                    ],
                  ),
                ),

                // Info section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.accentOrange.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppTheme.accentOrange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AR Best Practices',
                            style: TextStyle(
                              color: AppTheme.accentOrange,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '• Always use ARCore Anchors for world-locked objects\n'
                        '• Enable plane detection for better tracking\n'
                        '• Position objects relative to anchors, not camera\n'
                        '• Test on different surfaces and lighting conditions',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required List<String> features,
  }) {
    return Card(
      color: Colors.black.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: color, size: 16),
                ],
              ),

              const SizedBox(height: 16),

              // Features
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: features
                    .map(
                      (feature) => Text(
                        feature,
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
