import 'dart:io';
import 'package:flutter/material.dart';
import '../../../domain/models/community.dart';
import '../../../core/config/cloudinary_config.dart';
import 'image_upload_widget.dart';

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
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      enabled: enabled,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        prefixText: prefix,
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
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
  final File? profileImage;
  final File? bannerImage;
  final List<String> rules;
  final List<String> tags;
  final CommunityVisibility visibility;

  CommunityFormData({
    required this.name,
    this.handle,
    required this.description,
    this.photoUrl,
    this.bannerUrl,
    this.profileImage,
    this.bannerImage,
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
  final String? submitButtonText;
  final String? loadingButtonText;
  final IconData? submitButtonIcon;
  final Color? submitButtonColor;
  final bool showSubmitButton;

  const CommunityForm({
    super.key,
    this.initialData,
    this.isEditing = false,
    required this.onSubmit,
    this.isLoading = false,
    this.submitButtonText,
    this.loadingButtonText,
    this.submitButtonIcon,
    this.submitButtonColor,
    this.showSubmitButton = true,
  });

  @override
  State<CommunityForm> createState() => _CommunityFormState();
}

class _CommunityFormState extends State<CommunityForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _handleController;
  late TextEditingController _descriptionController;
  late TextEditingController _ruleController;
  late TextEditingController _tagController;

  late List<String> _rules;
  late List<String> _tags;
  late CommunityVisibility _visibility;

  // Image handling
  File? _selectedProfileImage;
  File? _selectedBannerImage;
  bool _isUploadingProfile = false;
  bool _isUploadingBanner = false;

  @override
  void initState() {
    super.initState();

    final data = widget.initialData;
    _nameController = TextEditingController(text: data?.name ?? '');
    _handleController = TextEditingController(text: data?.handle ?? '');
    _descriptionController = TextEditingController(
      text: data?.description ?? '',
    );
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
      photoUrl: widget.initialData?.photoUrl,
      bannerUrl: widget.initialData?.bannerUrl,
      profileImage: _selectedProfileImage,
      bannerImage: _selectedBannerImage,
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
                ImageUploadWidget(
                  initialImageUrl: widget.initialData?.photoUrl,
                  label: 'Profile Photo',
                  hint: 'Add a profile photo for your community',
                  icon: Icons.photo_camera_outlined,
                  height: 120,
                  maxSizeBytes: CloudinaryConfig.maxCommunityImageSize,
                  onImageSelected: (file) {
                    setState(() {
                      _selectedProfileImage = file;
                    });
                  },
                  isUploading: _isUploadingProfile,
                ),
                const SizedBox(height: 20),
                ImageUploadWidget(
                  initialImageUrl: widget.initialData?.bannerUrl,
                  label: 'Banner Image',
                  hint: 'Add a banner image for your community',
                  icon: Icons.panorama_outlined,
                  height: 150,
                  maxSizeBytes: CloudinaryConfig.maxCommunityBannerSize,
                  onImageSelected: (file) {
                    setState(() {
                      _selectedBannerImage = file;
                    });
                  },
                  isUploading: _isUploadingBanner,
                ),
              ],
            ),
          ),
          FormSection(
            title: 'Rules',
            icon: Icons.rule_outlined,
            subtitle: 'Set community guidelines',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ModernInput(
                        controller: _ruleController,
                        label: 'Add rule',
                        icon: Icons.add_circle_outline,
                        hint: 'Enter a community rule',
                        onSubmitted: (_) => _addRule(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: _addRule,
                      icon: const Icon(Icons.add),
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
                if (_rules.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...List.generate(_rules.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${index + 1}. ${_rules[index]}',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            IconButton(
                              onPressed: () => _removeRule(index),
                              icon: const Icon(Icons.delete_outline),
                              iconSize: 20,
                              color: Colors.red.shade600,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
          FormSection(
            title: 'Tags',
            icon: Icons.tag_outlined,
            subtitle: 'Help people discover your community',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ModernInput(
                        controller: _tagController,
                        label: 'Add tag',
                        icon: Icons.add_circle_outline,
                        hint: 'Enter a tag (lowercase, no spaces)',
                        onSubmitted: (_) => _addTag(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: _addTag,
                      icon: const Icon(Icons.add),
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
                if (_tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(_tags.length, (index) {
                      return Chip(
                        label: Text('#${_tags[index]}'),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () => _removeTag(index),
                        backgroundColor: colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      );
                    }),
                  ),
                ],
              ],
            ),
          ),
          if (widget.showSubmitButton) ...[
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: widget.isLoading ? null : submitForm,
                icon: widget.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(widget.submitButtonIcon ?? Icons.save),
                label: Text(
                  widget.isLoading
                      ? (widget.loadingButtonText ?? 'Saving...')
                      : (widget.submitButtonText ?? 'Save Community'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.submitButtonColor ?? colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
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
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class VisibilityToggle extends StatelessWidget {
  final CommunityVisibility visibility;
  final void Function(CommunityVisibility) onChanged;

  const VisibilityToggle({
    super.key,
    required this.visibility,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        _VisibilityOption(
          title: 'Public',
          subtitle: 'Anyone can find and join this community',
          icon: Icons.public,
          isSelected: visibility == CommunityVisibility.public,
          onTap: () => onChanged(CommunityVisibility.public),
        ),
        const SizedBox(height: 12),
        _VisibilityOption(
          title: 'Private',
          subtitle: 'Only invited members can join',
          icon: Icons.lock_outline,
          isSelected: visibility == CommunityVisibility.private,
          onTap: () => onChanged(CommunityVisibility.private),
        ),
      ],
    );
  }
}

class _VisibilityOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _VisibilityOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? colorScheme.primaryContainer.withOpacity(0.1)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withOpacity(0.7),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}