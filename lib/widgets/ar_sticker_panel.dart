import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/managers/ar_sticker_manager.dart';
import '../models/ar_sticker.dart';

class ARStickerPanel extends StatefulWidget {
  final ARStickerManager manager;

  const ARStickerPanel({super.key, required this.manager});

  @override
  State<ARStickerPanel> createState() => _ARStickerPanelState();
}

class _ARStickerPanelState extends State<ARStickerPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showPanel = false;
  ARStickerTemplate? _selectedTemplate;
  String _customText = '';
  Color _selectedColor = AppTheme.accentOrange;

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
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Listen to manager state changes
    widget.manager.addListener(_onManagerStateChanged);
  }

  @override
  void dispose() {
    widget.manager.removeListener(_onManagerStateChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onManagerStateChanged() {
    // Hide panel when not in placement mode
    if (!widget.manager.isPlacementMode && _showPanel) {
      setState(() {
        _showPanel = false;
      });
    }
  }

  void _togglePanel() {
    setState(() {
      _showPanel = !_showPanel;
    });
  }

  void _selectTemplate(ARStickerTemplate template) {
    setState(() {
      _selectedTemplate = template;
    });
  }

  void _enterPlacementMode() {
    if (_selectedTemplate != null) {
      widget.manager.enterPlacementMode(_selectedTemplate!);
      setState(() {
        _showPanel = false;
      });
    }
  }

  void _createCustomTextSticker() {
    if (_customText.trim().isNotEmpty) {
      final template = ARStickerTemplate(
        id: 'custom_text_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Custom Text',
        type: StickerType.text,
        content: _customText.trim(),
        defaultProperties: {'fontSize': 24.0, 'color': _selectedColor.value},
      );

      widget.manager.enterPlacementMode(template);
      setState(() {
        _showPanel = false;
        _customText = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Bottom control button
        _buildBottomButton(),

        // Sticker panel
        if (_showPanel) _buildPanel(),

        // Placement mode indicator
        if (widget.manager.isPlacementMode) _buildPlacementIndicator(),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 32,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: _togglePanel,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: _showPanel ? AppTheme.accentGradient : null,
              color: _showPanel
                  ? null
                  : AppTheme.lightGray.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Add Sticker',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanel() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 100,
      left: 16,
      right: 16,
      child: Container(
        height: 400,
        decoration: BoxDecoration(
          color: AppTheme.secondaryBlack.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            _buildPanelHeader(),

            // Tab bar
            _buildTabBar(),

            // Tab content
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildPanelHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Choose Sticker',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showPanel = false),
            child: Icon(Icons.close, color: Colors.white70, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.lightGray.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(25),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Emojis'),
          Tab(text: 'Shapes'),
          Tab(text: 'Text'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [_buildEmojiTab(), _buildShapeTab(), _buildTextTab()],
    );
  }

  Widget _buildEmojiTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: StickerTemplates.emojis.length,
              itemBuilder: (context, index) {
                final template = StickerTemplates.emojis[index];
                final isSelected = _selectedTemplate?.id == template.id;

                return GestureDetector(
                  onTap: () => _selectTemplate(template),
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
                      child: Text(
                        template.content,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildPlaceButton(),
        ],
      ),
    );
  }

  Widget _buildShapeTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: StickerTemplates.shapes.length,
              itemBuilder: (context, index) {
                final template = StickerTemplates.shapes[index];
                final isSelected = _selectedTemplate?.id == template.id;

                return GestureDetector(
                  onTap: () => _selectTemplate(template),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.accentOrange.withValues(alpha: 0.3)
                          : AppTheme.lightGray.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.accentOrange
                            : Colors.white24,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildShapeIcon(template.content),
                        const SizedBox(height: 8),
                        Text(
                          template.name,
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
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildPlaceButton(),
        ],
      ),
    );
  }

  Widget _buildShapeIcon(String shape) {
    IconData icon;
    switch (shape) {
      case 'circle':
        icon = Icons.circle;
        break;
      case 'square':
        icon = Icons.square;
        break;
      case 'triangle':
        icon = Icons.change_history;
        break;
      case 'arrow':
        icon = Icons.arrow_forward;
        break;
      default:
        icon = Icons.circle;
    }

    return Icon(icon, color: Colors.white, size: 32);
  }

  Widget _buildTextTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text input
          TextField(
            onChanged: (value) => setState(() => _customText = value),
            style: const TextStyle(color: Colors.white),
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
            maxLines: 3,
          ),

          const SizedBox(height: 20),

          // Color picker
          Text(
            'Text Color',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _colors.map((color) {
              final isSelected = _selectedColor == color;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),

          const Spacer(),

          // Create text button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _customText.trim().isNotEmpty
                  ? _createCustomTextSticker
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                'Place Text',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _selectedTemplate != null ? _enterPlacementMode : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentOrange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Text(
          'Place Sticker',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildPlacementIndicator() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.accentOrange.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.touch_app, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tap on a detected surface to place your sticker',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => widget.manager.exitPlacementMode(),
              child: Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
