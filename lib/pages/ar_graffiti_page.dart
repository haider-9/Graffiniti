import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/glassmorphic_container.dart';
import '../core/widgets/gradient_button.dart';

class ARGraffitiPage extends StatefulWidget {
  const ARGraffitiPage({super.key});

  @override
  State<ARGraffitiPage> createState() => _ARGraffitiPageState();
}

class _ARGraffitiPageState extends State<ARGraffitiPage>
    with TickerProviderStateMixin {
  late AnimationController _toolsAnimationController;
  late AnimationController _colorAnimationController;

  bool _showTools = false;
  bool _showColorPicker = false;

  Color _selectedColor = AppTheme.accentOrange;
  double _brushSize = 5.0;
  int _selectedTool = 0; // 0: Brush, 1: Spray, 2: Sticker, 3: Text

  final List<Color> _colors = [
    AppTheme.accentOrange,
    AppTheme.accentBlue,
    AppTheme.accentGreen,
    AppTheme.accentPurple,
    AppTheme.accentRed,
    Colors.white,
    const Color(0xFF2C2C2E),
    const Color(0xFF48484A),
  ];

  final List<Map<String, dynamic>> _tools = [
    {'icon': Icons.brush, 'name': 'Brush'},
    {'icon': Icons.format_paint, 'name': 'Spray'},
    {'icon': Icons.emoji_emotions, 'name': 'Sticker'},
    {'icon': Icons.text_fields, 'name': 'Text'},
  ];

  @override
  void initState() {
    super.initState();
    _toolsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _colorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _toolsAnimationController.dispose();
    _colorAnimationController.dispose();
    super.dispose();
  }

  void _toggleTools() {
    setState(() {
      _showTools = !_showTools;
    });
    if (_showTools) {
      _toolsAnimationController.forward();
    } else {
      _toolsAnimationController.reverse();
    }
  }

  void _toggleColorPicker() {
    setState(() {
      _showColorPicker = !_showColorPicker;
    });
    if (_showColorPicker) {
      _colorAnimationController.forward();
    } else {
      _colorAnimationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: Stack(
        children: [
          // AR Camera View (placeholder)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1A1A2E),
                    Color(0xFF16213E),
                    Color(0xFF0F3460),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.view_in_ar,
                      size: 80,
                      color: AppTheme.accentOrange,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'AR Camera View',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Point your camera at a surface to start creating',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Top controls
          _buildTopControls(),

          // Side tools panel
          _buildSideToolsPanel(),

          // Bottom controls
          _buildBottomControls(),

          // Color picker overlay
          if (_showColorPicker) _buildColorPicker(),
        ],
      ),
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: GlassmorphicContainer(
              width: 44,
              height: 44,
              borderRadius: BorderRadius.circular(22),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.view_in_ar, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  'AR Mode',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: () {
              // Undo action
            },
            child: GlassmorphicContainer(
              width: 44,
              height: 44,
              borderRadius: BorderRadius.circular(22),
              child: const Icon(Icons.undo, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideToolsPanel() {
    return Positioned(
      right: 16,
      top: MediaQuery.of(context).size.height * 0.25,
      child: Column(
        children: [
          // Tools toggle
          GestureDetector(
            onTap: _toggleTools,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: _showTools ? AppTheme.primaryGradient : null,
                color: _showTools ? null : AppTheme.lightGray,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_showTools ? AppTheme.accentOrange : Colors.black)
                        .withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _tools[_selectedTool]['icon'],
                color: Colors.white,
                size: 24,
              ),
            ),
          ),

          // Tools list
          AnimatedBuilder(
            animation: _toolsAnimationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -_toolsAnimationController.value * 20),
                child: Opacity(
                  opacity: _toolsAnimationController.value,
                  child: Column(
                    children: _tools.asMap().entries.map((entry) {
                      final index = entry.key;
                      final tool = entry.value;
                      final isSelected = _selectedTool == index;

                      return Container(
                        margin: const EdgeInsets.only(top: 12),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTool = index;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? AppTheme.accentGradient
                                  : null,
                              color: isSelected ? null : AppTheme.accentGray,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              tool['icon'],
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Color picker toggle
          GestureDetector(
            onTap: _toggleColorPicker,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _selectedColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _selectedColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.palette, color: Colors.white, size: 20),
            ),
          ),

          const SizedBox(height: 16),

          // Brush size slider
          Container(
            height: 120,
            width: 44,
            decoration: BoxDecoration(
              color: AppTheme.accentGray,
              borderRadius: BorderRadius.circular(22),
            ),
            child: RotatedBox(
              quarterTurns: 3,
              child: Slider(
                value: _brushSize,
                min: 1.0,
                max: 20.0,
                activeColor: AppTheme.accentOrange,
                inactiveColor: Colors.white24,
                onChanged: (value) {
                  setState(() {
                    _brushSize = value;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 32,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Clear canvas
          GestureDetector(
            onTap: () {
              // Clear canvas
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.red, width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.clear, color: Colors.red, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Clear',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Save graffiti
          GradientButton(
            text: 'Save Graffiti',
            onPressed: () {
              // Save graffiti logic
              Navigator.pop(context);
            },
            icon: Icons.save,
            width: 160,
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker() {
    return AnimatedBuilder(
      animation: _colorAnimationController,
      builder: (context, child) {
        return Positioned(
          right: 80,
          top: MediaQuery.of(context).size.height * 0.4,
          child: Transform.scale(
            scale: _colorAnimationController.value,
            child: Opacity(
              opacity: _colorAnimationController.value,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryBlack,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Colors',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _colors.map((color) {
                        final isSelected = _selectedColor == color;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
