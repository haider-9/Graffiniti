import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';

class SwipeableGraffitiPanel extends StatefulWidget {
  final List<Map<String, dynamic>> graffitiList;
  final Function(Map<String, dynamic>) onGraffitiTap;
  final Function(LatLng) onLocationTap;
  final VoidCallback onClose;

  const SwipeableGraffitiPanel({
    super.key,
    required this.graffitiList,
    required this.onGraffitiTap,
    required this.onLocationTap,
    required this.onClose,
  });

  @override
  State<SwipeableGraffitiPanel> createState() => _SwipeableGraffitiPanelState();
}

class _SwipeableGraffitiPanelState extends State<SwipeableGraffitiPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  double _panelPosition = 0.6; // 0.0 = closed, 0.6 = collapsed, 1.0 = expanded

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    // Start with collapsed state
    _controller.value = 0.6;
    _panelPosition = 0.6;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final screenHeight = MediaQuery.of(context).size.height;
    final delta =
        -details.delta.dy / screenHeight; // Negative because up is positive

    setState(() {
      _panelPosition = (_panelPosition + delta).clamp(0.0, 1.0);
      _controller.value = _panelPosition;
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    final velocity = -details.velocity.pixelsPerSecond.dy;
    final screenHeight = MediaQuery.of(context).size.height;
    final velocityThreshold = screenHeight * 2.0;

    double targetPosition;

    if (velocity > velocityThreshold) {
      // Fast upward swipe - expand
      targetPosition = 1.0;
    } else if (velocity < -velocityThreshold) {
      // Fast downward swipe - close or collapse
      targetPosition = _panelPosition > 0.8 ? 0.0 : 0.0;
    } else {
      // Slow drag - snap to nearest state
      if (_panelPosition < 0.3) {
        targetPosition = 0.0; // Close
      } else if (_panelPosition < 0.8) {
        targetPosition = 0.6; // Collapsed
      } else {
        targetPosition = 1.0; // Expanded
      }
    }

    _animateToPosition(targetPosition);
  }

  void _animateToPosition(double position) {
    if (position == 0.0) {
      // Closing
      _controller.animateTo(0.0).then((_) {
        widget.onClose();
      });
    } else {
      // Moving to collapsed or expanded
      _controller.animateTo(position).then((_) {
        setState(() {
          _panelPosition = position;
        });
      });
    }
  }

  void _collapseToNormal() {
    _animateToPosition(0.6);
  }

  void _close() {
    _animateToPosition(0.0);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final animatedPosition = _animation.value;
        final panelHeight = screenHeight * animatedPosition;
        final isFullScreen = animatedPosition >= 0.85;

        return Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: panelHeight,
          child: GestureDetector(
            onPanUpdate: _handlePanUpdate,
            onPanEnd: _handlePanEnd,
            child: Container(
              width: screenWidth,
              height: panelHeight,
              decoration: BoxDecoration(
                gradient: AppTheme.backgroundGradient,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isFullScreen ? 0 : 20),
                  topRight: Radius.circular(isFullScreen ? 0 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag indicator
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryText,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Text(
                          'Nearby Graffiti',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _close,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryBlack,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: AppTheme.secondaryText,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Content
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: widget.graffitiList.length,
                      itemBuilder: (context, index) {
                        final graffiti = widget.graffitiList[index];
                        return _buildGraffitiListItem(graffiti);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGraffitiListItem(Map<String, dynamic> graffiti) {
    final color = graffiti['color'] as Color? ?? Colors.grey;

    Widget fallbackPreview() {
      return Container(
        height: 80,
        width: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.3),
              color.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(child: Icon(Icons.view_in_ar, size: 32, color: color)),
      );
    }

    Widget graffitiImage() {
      final imageUrl = graffiti['imageUrl'];
      if (imageUrl == null || imageUrl.isEmpty) return fallbackPreview();

      return SizedBox(
        height: 80,
        width: 80,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
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
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => fallbackPreview(),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: graffitiImage(),
        title: Text(
          graffiti['title'] ?? 'Untitled',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              graffiti['artist'] ?? 'Unknown Artist',
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${graffiti['address'] ?? 'Unknown Location'} • ${graffiti['distance'] ?? '-'}',
              style: const TextStyle(
                color: AppTheme.secondaryText,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.favorite_outline,
                  color: AppTheme.secondaryText,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${graffiti['likes'] ?? 0}',
                  style: const TextStyle(
                    color: AppTheme.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              graffiti['time'] ?? '',
              style: const TextStyle(color: AppTheme.mutedText, fontSize: 10),
            ),
          ],
        ),
        onTap: () {
          final location = graffiti['location'];
          if (location != null) {
            widget.onLocationTap(location);
          }
        },
        onLongPress: () {
          widget.onGraffitiTap(graffiti);
        },
      ),
    );
  }
}
