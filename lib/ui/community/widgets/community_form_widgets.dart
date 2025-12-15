import 'package:flutter/material.dart';
import '../../../domain/models/community.dart';

class ModernInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final String? prefix;
  final Widget? suffix;
  final int maxLines;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;
  final bool enabled;

  const ModernInput({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.prefix,
    this.suffix,
    this.maxLines = 1,
    this.validator,
    this.onSubmitted,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix,
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        prefixIcon: Icon(icon, size: 22),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
      ),
    );
  }
}

class FormSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;
  final Widget child;

  const FormSection({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.primaryColor,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class RuleChip extends StatelessWidget {
  final int index;
  final String rule;
  final VoidCallback onDelete;

  const RuleChip({
    super.key,
    required this.index,
    required this.rule,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(rule, style: Theme.of(context).textTheme.bodyMedium),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
            tooltip: 'Remove rule',
          ),
        ],
      ),
    );
  }
}

class TagChip extends StatelessWidget {
  final String tag;
  final VoidCallback onDelete;

  const TagChip({super.key, required this.tag, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Chip(
      label: Text(
        '# $tag',
        style: TextStyle(
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: colorScheme.primary,
      deleteIcon: Icon(
        Icons.close,
        size: 18,
        color: colorScheme.onSecondaryContainer,
      ),
      onDeleted: onDelete,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide.none,
      ),
    );
  }
}

class VisibilityToggle extends StatelessWidget {
  final CommunityVisibility visibility;
  final ValueChanged<CommunityVisibility> onChanged;

  const VisibilityToggle({
    super.key,
    required this.visibility,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: ToggleButtons(
        isSelected: [
          visibility == CommunityVisibility.public,
          visibility == CommunityVisibility.private,
        ],
        onPressed: (index) {
          onChanged(
            index == 0
                ? CommunityVisibility.public
                : CommunityVisibility.private,
          );
        },
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.public),
                SizedBox(width: 8),
                Text('Public'),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [Icon(Icons.lock), SizedBox(width: 8), Text('Private')],
            ),
          ),
        ],
      ),
    );
  }
}

class CommunityFormData {
  final String name;
  final String? handle;
  final String description;
  final String? photoUrl;
  final String? bannerUrl;
  final List<String> rules;
  final List<String> tags;
  final CommunityVisibility visibility;

  CommunityFormData({
    required this.name,
    this.handle,
    required this.description,
    this.photoUrl,
    this.bannerUrl,
    required this.rules,
    required this.tags,
    required this.visibility,
  });
}

class CommunityForm extends StatefulWidget {
  final CommunityFormData? initialData;
  final bool isEditing;
  final void Function(CommunityFormData) onSubmit;
  final bool isLoading;

  const CommunityForm({
    super.key,
    this.initialData,
    this.isEditing = false,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<CommunityForm> createState() => CommunityFormState();
}

// Make the state class public so it can be accessed from parent widgets
class CommunityFormState extends State<CommunityForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _handleController;
  late TextEditingController _descriptionController;
  late TextEditingController _photoUrlController;
  late TextEditingController _bannerUrlController;
  late TextEditingController _ruleController;
  late TextEditingController _tagController;

  late List<String> _rules;
  late List<String> _tags;
  late CommunityVisibility _visibility;

  @override
  void initState() {
    super.initState();

    final data = widget.initialData;
    _nameController = TextEditingController(text: data?.name ?? '');
    _handleController = TextEditingController(text: data?.handle ?? '');
    _descriptionController = TextEditingController(
      text: data?.description ?? '',
    );
    _photoUrlController = TextEditingController(text: data?.photoUrl ?? '');
    _bannerUrlController = TextEditingController(text: data?.bannerUrl ?? '');
    _ruleController = TextEditingController();
    _tagController = TextEditingController();

    _rules = List.from(data?.rules ?? []);
    _tags = List.from(data?.tags ?? []);
    _visibility = data?.visibility ?? CommunityVisibility.public;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _handleController.dispose();
    _descriptionController.dispose();
    _photoUrlController.dispose();
    _bannerUrlController.dispose();
    _ruleController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addRule() {
    final rule = _ruleController.text.trim();
    if (rule.isEmpty) {
      _showErrorSnackBar('Rule cannot be empty');
      return;
    }
    if (rule.length < 5) {
      _showErrorSnackBar('Rule must be at least 5 characters long');
      return;
    }
    if (rule.length > 200) {
      _showErrorSnackBar('Rule must be less than 200 characters');
      return;
    }
    if (_rules.contains(rule)) {
      _showErrorSnackBar('This rule already exists');
      return;
    }
    if (_rules.length >= 10) {
      _showErrorSnackBar('Maximum 10 rules allowed');
      return;
    }

    setState(() {
      _rules.add(rule);
      _ruleController.clear();
    });
  }

  void _removeRule(int index) {
    setState(() => _rules.removeAt(index));
  }

  void _addTag() {
    final tag = _tagController.text.trim().toLowerCase();
    if (tag.isEmpty) {
      _showErrorSnackBar('Tag cannot be empty');
      return;
    }
    if (tag.length < 2) {
      _showErrorSnackBar('Tag must be at least 2 characters long');
      return;
    }
    if (tag.length > 20) {
      _showErrorSnackBar('Tag must be less than 20 characters');
      return;
    }
    if (!RegExp(r'^[a-z0-9]+$').hasMatch(tag)) {
      _showErrorSnackBar('Tags can only contain lowercase letters and numbers');
      return;
    }
    if (_tags.contains(tag)) {
      _showErrorSnackBar('This tag already exists');
      return;
    }
    if (_tags.length >= 5) {
      _showErrorSnackBar('Maximum 5 tags allowed');
      return;
    }

    setState(() {
      _tags.add(tag);
      _tagController.clear();
    });
  }

  void _removeTag(int index) {
    setState(() => _tags.removeAt(index));
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final data = CommunityFormData(
      name: _nameController.text.trim(),
      handle: widget.isEditing ? null : _handleController.text.trim(),
      description: _descriptionController.text.trim(),
      photoUrl: _photoUrlController.text.trim().isEmpty
          ? null
          : _photoUrlController.text.trim(),
      bannerUrl: _bannerUrlController.text.trim().isEmpty
          ? null
          : _bannerUrlController.text.trim(),
      rules: _rules,
      tags: _tags,
      visibility: _visibility,
    );

    widget.onSubmit(data);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FormSection(
            title: 'General Information',
            icon: Icons.info_outline,
            child: Column(
              children: [
                ModernInput(
                  controller: _nameController,
                  label: 'Community name',
                  icon: Icons.groups_rounded,
                  hint: 'e.g., Flutter Enthusiasts',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Community name is required';
                    }
                    if (v.trim().length < 3) {
                      return 'Name must be at least 3 characters';
                    }
                    if (v.trim().length > 50) {
                      return 'Name must be less than 50 characters';
                    }
                    return null;
                  },
                ),
                if (!widget.isEditing) ...[
                  const SizedBox(height: 16),
                  ModernInput(
                    controller: _handleController,
                    label: 'Handle',
                    icon: Icons.alternate_email,
                    prefix: '@',
                    hint: 'unique_handle',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Handle is required';
                      }
                      if (v.trim().length < 3) {
                        return 'Handle must be at least 3 characters';
                      }
                      if (v.trim().length > 20) {
                        return 'Handle must be less than 20 characters';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
                        return 'Only letters, numbers & underscore allowed';
                      }
                      if (v.trim().startsWith('_') || v.trim().endsWith('_')) {
                        return 'Handle cannot start or end with underscore';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),
                ModernInput(
                  controller: _descriptionController,
                  label: 'Description',
                  icon: Icons.description_outlined,
                  hint: 'Tell people what your community is about',
                  maxLines: 4,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Description is required';
                    }
                    if (v.trim().length < 10) {
                      return 'Description must be at least 10 characters';
                    }
                    if (v.trim().length > 500) {
                      return 'Description must be less than 500 characters';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          FormSection(
            title: 'Visibility',
            icon: Icons.visibility_outlined,
            child: VisibilityToggle(
              visibility: _visibility,
              onChanged: (value) => setState(() => _visibility = value),
            ),
          ),
          FormSection(
            title: 'Media',
            icon: Icons.image_outlined,
            subtitle: 'Add images to make your community stand out',
            child: Column(
              children: [
                ModernInput(
                  controller: _photoUrlController,
                  label: 'Profile Photo URL',
                  icon: Icons.photo_camera_outlined,
                  hint: 'https://example.com/photo.jpg',
                ),
                const SizedBox(height: 16),
                ModernInput(
                  controller: _bannerUrlController,
                  label: 'Banner Image URL',
                  icon: Icons.panorama_outlined,
                  hint: 'https://example.com/banner.jpg',
                ),
              ],
            ),
          ),
          FormSection(
            title: 'Community Rules',
            icon: Icons.rule,
            subtitle: 'Add rules to keep your community safe and friendly',
            child: Column(
              children: [
                ModernInput(
                  controller: _ruleController,
                  label: _rules.length >= 10
                      ? 'Maximum rules reached (10/10)'
                      : 'Add a rule (${_rules.length}/10)',
                  icon: Icons.add_circle_outline,
                  hint: _rules.length >= 10
                      ? 'Remove a rule to add more'
                      : 'Be respectful to all members',
                  enabled: _rules.length < 10,
                  suffix: IconButton(
                    icon: const Icon(Icons.add_rounded),
                    onPressed: _rules.length >= 10 ? null : _addRule,
                    tooltip: _rules.length >= 10
                        ? 'Maximum rules reached'
                        : 'Add rule',
                  ),
                  onSubmitted: _rules.length >= 10 ? null : (_) => _addRule(),
                ),
                if (_rules.length >= 10) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Maximum of 10 rules reached. Remove a rule to add more.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
                if (_rules.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: List.generate(
                        _rules.length,
                        (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: RuleChip(
                            index: i + 1,
                            rule: _rules[i],
                            onDelete: () => _removeRule(i),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          FormSection(
            title: 'Tags',
            icon: Icons.local_offer_outlined,
            subtitle: 'Help people discover your community',
            child: Column(
              children: [
                ModernInput(
                  controller: _tagController,
                  label: _tags.length >= 5
                      ? 'Maximum tags reached (5/5)'
                      : 'Add a tag (${_tags.length}/5)',
                  icon: Icons.tag,
                  hint: _tags.length >= 5
                      ? 'Remove a tag to add more'
                      : 'flutter, mobile, development',
                  enabled: _tags.length < 5,
                  suffix: IconButton(
                    icon: const Icon(Icons.add_rounded),
                    onPressed: _tags.length >= 5 ? null : _addTag,
                    tooltip: _tags.length >= 5
                        ? 'Maximum tags reached'
                        : 'Add tag',
                  ),
                  onSubmitted: _tags.length >= 5 ? null : (_) => _addTag(),
                ),
                if (_tags.length >= 5) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Maximum of 5 tags reached. Remove a tag to add more.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
                if (_tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(
                      _tags.length,
                      (i) =>
                          TagChip(tag: _tags[i], onDelete: () => _removeTag(i)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
