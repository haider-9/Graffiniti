import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/glassmorphic_container.dart';

class ARGraffitiPage extends StatefulWidget {
  const ARGraffitiPage({super.key});

  @override
  State<ARGraffitiPage> createState() => _ARGraffitiPageState();
}

class _ARGraffitiPageState extends State<ARGraffitiPage> {
  bool _showStickerPanel = false;
  bool _showTextPanel = false;
  String _selectedSticker = '😀';
  String _textInput = '';
  Color _selectedColor = AppTheme.accentOrange;

  final List<String> _stickers = [
    '😀',
    '😂',
    '😍',
    '🤔',
    '😎',
    '🔥',
    '💯',
    '❤️',
    '👍',
    '👎',
    '✨',
    '🎉',
    '🎊',
    '🌟',
    '💫',
    '⭐',
    '🎨',
    '🖌️',
    '🎭',
    '🎪',
    '🎯',
    '🎲',
    '🎮',
    '🎸',
  ];

  final List<Color> _colors = [
    AppTheme.accentOrange,
    AppTheme.accentBlue,
    AppTheme.accentGreen,
    AppTheme.accentPurple,
    AppTheme.accentRed,
    Colors.white,
    Colors.yellow,
    Colors.pink,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: Stack(
        children: [
          // Placeholder for AR view - showing gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.view_in_ar,
                    size: 100,
                    color: AppTheme.accentOrange.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'AR Camera View',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'AR functionality placeholder',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          // Top controls
          _buildTopControls(),

          // Bottom controls
          _buildBottomControls(),

          // Sticker panel
          if (_showStickerPanel) _buildStickerPanel(),

          // Text input panel
          if (_showTextPanel) _buildTextPanel(),

          // Instructions overlay
          if (!_showStickerPanel && !_showTextPanel) _buildInstructions(),
        ],
      ),
    );
  }

  void _addSticker() {
    // Placeholder for adding sticker
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sticker "$_selectedSticker" would be added here'),
        backgroundColor: AppTheme.accentOrange,
      ),
    );
    setState(() {
      _showStickerPanel = false;
    });
  }

  void _addText() {
    // Placeholder for adding text
    if (_textInput.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Text "$_textInput" would be added here'),
          backgroundColor: AppTheme.accentOrange,
        ),
      );
      setState(() {
        _showTextPanel = false;
        _textInput = '';
      });
    }
  }

  void _clearAllNodes() {
    // Placeholder for clearing all nodes
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All AR items would be cleared here'),
        backgroundColor: AppTheme.accentOrange,
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
              child: Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),

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
                  'AR Graffiti',
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
            onTap: _clearAllNodes,
            child: GlassmorphicContainer(
              width: 44,
              height: 44,
              borderRadius: BorderRadius.circular(22),
              child: Icon(Icons.clear_all, color: Colors.white, size: 20),
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Stickers button
          GestureDetector(
            onTap: () {
              setState(() {
                _showStickerPanel = !_showStickerPanel;
                _showTextPanel = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: _showStickerPanel ? AppTheme.accentGradient : null,
                color: _showStickerPanel
                    ? null
                    : AppTheme.lightGray.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_emotions, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Stickers',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Text button
          GestureDetector(
            onTap: () {
              setState(() {
                _showTextPanel = !_showTextPanel;
                _showStickerPanel = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: _showTextPanel ? AppTheme.accentGradient : null,
                color: _showTextPanel
                    ? null
                    : AppTheme.lightGray.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.text_fields, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Text',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickerPanel() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 100,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.secondaryBlack.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Choose a Sticker',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _showStickerPanel = false),
                  child: Icon(Icons.close, color: Colors.white70, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sticker grid
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _stickers.length,
              itemBuilder: (context, index) {
                final sticker = _stickers[index];
                final isSelected = _selectedSticker == sticker;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSticker = sticker;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.accentOrange.withValues(alpha: 0.3)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.accentOrange
                            : Colors.white24,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(sticker, style: TextStyle(fontSize: 20)),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),
            // Add sticker button
            ElevatedButton(
              onPressed: _addSticker,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text('Add Sticker'),
            ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.accentOrange.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.accentOrange,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Real-World Anchoring:',
                        style: TextStyle(
                          color: AppTheme.accentOrange,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Move phone to detect surfaces (white planes)\n2. Tap on a plane to anchor sticker to real world\n3. Move camera away and back - sticker stays in place!',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextPanel() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 100,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.secondaryBlack.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Text',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _showTextPanel = false),
                  child: Icon(Icons.close, color: Colors.white70, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Text input
            TextField(
              onChanged: (value) => setState(() => _textInput = value),
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter your text...',
                hintStyle: TextStyle(color: Colors.white54),
                filled: true,
                fillColor: AppTheme.lightGray.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Color picker
            Text(
              'Choose Color',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _colors.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),
            // Add text button
            ElevatedButton(
              onPressed: _addText,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text('Add Text'),
            ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.accentOrange.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.accentOrange,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AR Text Placeholder:',
                        style: TextStyle(
                          color: AppTheme.accentOrange,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This is a placeholder for AR text functionality. In a real AR implementation, text would be anchored to real-world surfaces.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.25,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlack.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.view_in_ar, size: 48, color: AppTheme.accentOrange),
            const SizedBox(height: 16),
            Text(
              'AR Graffiti Mode',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Anchor stickers and text to the real world!',
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.accentOrange.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How Real-World Anchoring Works:',
                    style: TextStyle(
                      color: AppTheme.accentOrange,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Move phone slowly to detect surfaces\n• White planes show detected surfaces\n• Tap on planes to anchor items to real world\n• Items stay in their 3D position\n• Walk around - items remain anchored!\n• Perfect for virtual graffiti on walls!',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
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
}
