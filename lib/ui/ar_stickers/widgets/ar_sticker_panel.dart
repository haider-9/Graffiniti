import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../view_model/ar_sticker_view_model.dart';
import '../../../models/ar_sticker.dart';

class ARStickerPanel extends StatefulWidget {
  final ARStickerViewModel viewModel;

  const ARStickerPanel({super.key, required this.viewModel});

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

    // Listen to view model state changes
    widget.viewModel.addListener(_onViewModelStateChanged);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelStateChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onViewModelStateChanged() {
    // Hide panel when not in placement mode
    if (!widget.viewModel.isPlacementMode && _showPanel) {
      setState(() {
        _showPanel = false;
      });
    }
  }

  void _togglePanel() {
    debugPrint('Toggle panel tapped - current state: $_showPanel');
    setState(() {
      _showPanel = !_showPanel;
    });
    debugPrint('Panel state changed to: $_showPanel');
  }

  void _selectTemplate(ARStickerTemplate template) {
    debugPrint('Template selected: ${template.name} (${template.type})');
    setState(() {
      _selectedTemplate = template;
    });
  }

  void _enterPlacementMode() {
    debugPrint(
      'Enter placement mode tapped - selected template: ${_selectedTemplate?.name}',
    );
    if (_selectedTemplate != null) {
      debugPrint(
        'Calling viewModel.enterPlacementMode with template: ${_selectedTemplate!.name}',
      );
      widget.viewModel.enterPlacementMode(_selectedTemplate!);
      setState(() {
        _showPanel = false;
      });
      debugPrint('Panel hidden, placement mode should be active');
    } else {
      debugPrint('No template selected - cannot enter placement mode');
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

      widget.viewModel.enterPlacementMode(template);
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
        if (widget.viewModel.isPlacementMode) _buildPlacementIndicator(),
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
          Tab(text: 'Images'),
          Tab(text: 'Text'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [_buildEmojiTab(), _buildImageTab(), _buildTextTab()],
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

  Widget _buildImageTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              itemCount: StickerTemplates.images.length,
              itemBuilder: (context, index) {
                final template = StickerTemplates.images[index];
                final isSelected = _selectedTemplate?.id == template.id;

                return GestureDetector(
                  onTap: () => _selectTemplate(template),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.accentOrange.withValues(alpha: 0.3)
                          : AppTheme.lightGray.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.accentOrange
                            : Colors.white24,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // PNG Image preview
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Image.asset(
                              template.content,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.image_not_supported,
                                  color: Colors.white54,
                                  size: 48,
                                );
                              },
                            ),
                          ),
                        ),
                        // Template name
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            template.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
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
    debugPrint(
      'Building placement indicator - placement mode: ${widget.viewModel.isPlacementMode}',
    );
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
              onTap: () {
                debugPrint('Placement indicator close button tapped');
                widget.viewModel.exitPlacementMode();
              },
              child: Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
