import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glassmorphic_container.dart';
import '../view_model/ar_sticker_view_model.dart';

class ARControlsOverlay extends StatelessWidget {
  final ARStickerViewModel viewModel;
  final VoidCallback onClose;

  const ARControlsOverlay({
    super.key,
    required this.viewModel,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top controls
        _buildTopControls(context),

        // Side controls
        _buildSideControls(context),

        // Edit mode controls
        if (viewModel.currentMode == ARMode.editing)
          _buildEditControls(context),

        // Tracking state indicator
        _buildTrackingIndicator(context),
      ],
    );
  }

  Widget _buildTopControls(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close button
          GestureDetector(
            onTap: onClose,
            child: GlassmorphicContainer(
              width: 44,
              height: 44,
              borderRadius: BorderRadius.circular(22),
              child: Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),

          // Title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.view_in_ar, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  'AR Stickers',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Settings menu
          GestureDetector(
            onTap: () => _showSettingsMenu(context),
            child: GlassmorphicContainer(
              width: 44,
              height: 44,
              borderRadius: BorderRadius.circular(22),
              child: Icon(Icons.more_vert, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideControls(BuildContext context) {
    return Positioned(
      right: 16,
      top: MediaQuery.of(context).size.height * 0.3,
      child: Column(
        children: [
          // Toggle plane visibility
          GestureDetector(
            onTap: viewModel.togglePlaneVisibility,
            child: GlassmorphicContainer(
              width: 50,
              height: 50,
              borderRadius: BorderRadius.circular(25),
              child: Icon(
                viewModel.showPlanes ? Icons.grid_on : Icons.grid_off,
                color: viewModel.showPlanes
                    ? AppTheme.accentOrange
                    : Colors.white,
                size: 24,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Clear all stickers
          if (viewModel.stickers.isNotEmpty)
            GestureDetector(
              onTap: () => _showClearConfirmation(context),
              child: GlassmorphicContainer(
                width: 50,
                height: 50,
                borderRadius: BorderRadius.circular(25),
                child: Icon(Icons.clear_all, color: Colors.white, size: 24),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditControls(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 120,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.secondaryBlack.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Edit mode indicator
            Row(
              children: [
                Icon(Icons.edit, color: AppTheme.accentOrange, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Edit Mode',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  'Drag • Pinch • Rotate',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                // Duplicate button
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.copy,
                    label: 'Duplicate',
                    onTap: () {
                      if (viewModel.editingStickerId != null) {
                        viewModel.duplicateSticker(viewModel.editingStickerId!);
                      }
                    },
                  ),
                ),

                const SizedBox(width: 12),

                // Delete button
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.delete,
                    label: 'Delete',
                    color: AppTheme.accentRed,
                    onTap: () {
                      if (viewModel.editingStickerId != null) {
                        viewModel.deleteSticker(viewModel.editingStickerId!);
                      }
                    },
                  ),
                ),

                const SizedBox(width: 12),

                // Done button
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.check,
                    label: 'Done',
                    color: AppTheme.accentGreen,
                    onTap: viewModel.exitEditMode,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: (color ?? AppTheme.accentOrange).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: (color ?? AppTheme.accentOrange).withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color ?? AppTheme.accentOrange, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingIndicator(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      left: 16,
      child: StreamBuilder<bool>(
        stream: viewModel.trackingStateStream,
        builder: (context, snapshot) {
          final isTracking = snapshot.data ?? false;

          if (isTracking) return const SizedBox.shrink();

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.accentRed.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Tracking Lost',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'AR Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),

            // Settings options
            _buildSettingsTile(
              icon: Icons.grid_on,
              title: 'Show Planes',
              subtitle: 'Display detected surfaces',
              value: viewModel.showPlanes,
              onChanged: () => viewModel.togglePlaneVisibility(),
            ),

            _buildSettingsTile(
              icon: Icons.save,
              title: 'Export Session',
              subtitle: 'Save current stickers',
              onTap: () => _exportSession(context),
            ),

            _buildSettingsTile(
              icon: Icons.folder_open,
              title: 'Import Session',
              subtitle: 'Load saved stickers',
              onTap: () => _importSession(context),
            ),

            _buildSettingsTile(
              icon: Icons.info_outline,
              title: 'Help',
              subtitle: 'Learn how to use AR stickers',
              onTap: () => _showHelp(context),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    bool? value,
    VoidCallback? onChanged,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.white70)),
      trailing: value != null
          ? Switch(
              value: value,
              onChanged: (_) => onChanged?.call(),
              activeThumbColor: AppTheme.accentOrange,
            )
          : Icon(Icons.chevron_right, color: Colors.white70),
      onTap: onTap,
    );
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: Text(
          'Clear All Stickers',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to remove all stickers? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.clearAllStickers();
            },
            child: Text(
              'Clear All',
              style: TextStyle(color: AppTheme.accentRed),
            ),
          ),
        ],
      ),
    );
  }

  void _exportSession(BuildContext context) async {
    try {
      await viewModel.exportSession();
      // In a real app, you would save this to a file or share it
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Session exported successfully'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export session'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  void _importSession(BuildContext context) {
    // In a real app, you would show a file picker or import dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Import functionality coming soon'),
        backgroundColor: AppTheme.accentOrange,
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: Text(
          'How to Use AR Stickers',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpItem('1. Move your phone slowly to detect surfaces'),
              _buildHelpItem(
                '2. White planes will appear on detected surfaces',
              ),
              _buildHelpItem('3. Tap "Add Sticker" to choose a sticker'),
              _buildHelpItem('4. Tap on a plane to place your sticker'),
              _buildHelpItem('5. Tap a placed sticker to edit it'),
              _buildHelpItem('6. Use gestures to move, scale, and rotate'),
              _buildHelpItem('7. Tap "Done" to lock the sticker in place'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it!',
              style: TextStyle(color: AppTheme.accentOrange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: TextStyle(color: Colors.white70, fontSize: 14)),
    );
  }
}
