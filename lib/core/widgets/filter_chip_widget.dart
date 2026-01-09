import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final EdgeInsets? padding;
  final double? fontSize;
  final IconData? icon;

  const FilterChipWidget({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.padding,
    this.fontSize,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: isSelected ? null : AppTheme.accentGray,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.accentOrange.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppTheme.secondaryText,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.secondaryText,
                  fontSize: fontSize ?? 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  height: 1.2, // Add line height for better text rendering
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FilterChipList extends StatelessWidget {
  final List<FilterChipData> chips;
  final String selectedFilter;
  final Function(String) onFilterChanged;
  final EdgeInsets? padding;
  final double spacing;
  final double? height;

  const FilterChipList({
    super.key,
    required this.chips,
    required this.selectedFilter,
    required this.onFilterChanged,
    this.padding,
    this.spacing = 8,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: chips.map((chip) {
            final index = chips.indexOf(chip);
            return Padding(
              padding: EdgeInsets.only(
                right: index < chips.length - 1 ? spacing : 0,
              ),
              child: FilterChipWidget(
                label: chip.label,
                isSelected: selectedFilter == chip.value,
                onTap: () => onFilterChanged(chip.value),
                icon: chip.icon,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class FilterChipData {
  final String label;
  final String value;
  final IconData? icon;

  const FilterChipData({required this.label, required this.value, this.icon});
}
