import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/community.dart';
import '../view_model/community_view_model.dart';
import '../../../core/services/community_service.dart';
import 'community_form_widgets.dart';

class EditCommunityScreen extends StatefulWidget {
  final Community community;

  const EditCommunityScreen({super.key, required this.community});

  @override
  State<EditCommunityScreen> createState() => _EditCommunityScreenState();
}

class _EditCommunityScreenState extends State<EditCommunityScreen> {
  bool _isLoading = false;
  final CommunityService _communityService = CommunityService();

  @override
  Widget build(BuildContext context) {
    final initialData = CommunityFormData(
      name: widget.community.name,
      description: widget.community.description,
      photoUrl: widget.community.photoUrl,
      bannerUrl: widget.community.bannerUrl,
      rules: widget.community.rules,
      tags: widget.community.tags,
      visibility: widget.community.visibility,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Community Settings'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: CommunityForm(
              initialData: initialData,
              isEditing: true,
              onSubmit: _handleFormSubmit,
              isLoading: _isLoading,
              submitButtonText: 'Save Changes',
              loadingButtonText: 'Saving...',
              submitButtonIcon: Icons.save,
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _showDeleteConfirmationDialog,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete Community'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Community'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete "${widget.community.name}"?',
              ),
              const SizedBox(height: 8),
              const Text(
                'This action cannot be undone. All posts, members, and data associated with this community will be permanently deleted.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleDeleteCommunity();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleDeleteCommunity() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final viewModel = context.read<CommunityViewModel>();

      await viewModel.deleteCommunity(widget.community.id);

      if (mounted) {
        // Navigate back to communities screen and refresh data
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Community deleted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Refresh communities data
        final viewModel = context.read<CommunityViewModel>();
        viewModel.loadCommunities();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting community: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleFormSubmit(CommunityFormData data) async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? profileImageUrl = data.photoUrl;
      String? bannerImageUrl = data.bannerUrl;

      // Upload new images if provided
      if (data.profileImage != null) {
        try {
          profileImageUrl = await _communityService.updateCommunityProfileImage(
            widget.community.id,
            data.profileImage!,
          );
        } catch (e) {
          if (mounted) {
            _showErrorSnackBar(
              'Failed to upload profile image: ${e.toString()}',
            );
          }
        }
      }

      if (data.bannerImage != null) {
        try {
          bannerImageUrl = await _communityService.updateCommunityBannerImage(
            widget.community.id,
            data.bannerImage!,
          );
        } catch (e) {
          if (mounted) {
            _showErrorSnackBar(
              'Failed to upload banner image: ${e.toString()}',
            );
          }
        }
      }

      final viewModel = context.read<CommunityViewModel>();

      await viewModel.updateCommunity(
        communityId: widget.community.id,
        name: data.name,
        description: data.description,
        photoUrl: profileImageUrl ?? '',
        bannerUrl: bannerImageUrl ?? '',
        tags: data.tags,
        rules: data.rules,
        visibility: data.visibility,
      );

      if (mounted) {
        // Navigate back to communities screen and refresh data
        Navigator.of(context).popUntil((route) => route.isFirst);
        _showSuccessSnackBar('Community updated successfully! ✨');

        // Refresh communities data
        final viewModel = context.read<CommunityViewModel>();
        viewModel.loadCommunities();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error updating community: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
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
}
