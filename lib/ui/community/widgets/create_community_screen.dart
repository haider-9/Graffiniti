import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../view_model/community_view_model.dart';
import '../../../core/services/community_service.dart';
import '../../../core/services/auth_service.dart';
import 'community_form_widgets.dart';

class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  bool _isLoading = false;
  final CommunityService _communityService = CommunityService();
  final AuthService _authService = AuthService();

  Future<void> _handleFormSubmit(CommunityFormData data) async {
    if (data.handle == null || data.handle!.isEmpty) {
      _showErrorSnackBar('Handle is required');
      return;
    }

    // Check if user is authenticated
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      _showErrorSnackBar('You must be logged in to create a community');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if handle already exists
      await _checkHandleAvailability(data.handle!);

      String? profileImageUrl;
      String? bannerImageUrl;

      // Create community first to get the ID
      final communityViewModel = context.read<CommunityViewModel>();
      final communityId = await communityViewModel.createCommunity(
        name: data.name,
        handle: data.handle!,
        description: data.description,
        createdBy: currentUser.uid,
        photoUrl: data.photoUrl,
        bannerUrl: data.bannerUrl,
        rules: data.rules.isEmpty ? null : data.rules,
        tags: data.tags.isEmpty ? null : data.tags,
        visibility: data.visibility,
      );

      // Upload images if provided
      if (data.profileImage != null) {
        try {
          profileImageUrl = await _communityService.uploadCommunityProfileImage(
            communityId,
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
          bannerImageUrl = await _communityService.uploadCommunityBannerImage(
            communityId,
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

      // Update community with image URLs if uploaded
      if (profileImageUrl != null || bannerImageUrl != null) {
        await FirebaseFirestore.instance
            .collection('communities')
            .doc(communityId)
            .update({
              if (profileImageUrl != null) 'photoUrl': profileImageUrl,
              if (bannerImageUrl != null) 'bannerUrl': bannerImageUrl,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }

      if (mounted) {
        // Navigate back to communities screen and refresh data
        Navigator.of(context).popUntil((route) => route.isFirst);
        _showSuccessSnackBar('Community created successfully! 🎉');

        // Refresh communities data
        final viewModel = context.read<CommunityViewModel>();
        viewModel.loadCommunities();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = _getErrorMessage(e.toString());
        _showErrorSnackBar(errorMessage);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkHandleAvailability(String handle) async {
    try {
      // Query Firestore to check if handle exists
      final querySnapshot = await FirebaseFirestore.instance
          .collection('communities')
          .where('handle', isEqualTo: handle)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        throw Exception('HANDLE_EXISTS');
      }
    } catch (e) {
      if (e.toString().contains('HANDLE_EXISTS')) {
        rethrow;
      }
      // If it's a network error or other issue, we'll let the creation proceed
      // and handle the error there
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('HANDLE_EXISTS')) {
      return 'This handle is already taken. Please choose a different one.';
    } else if (error.contains('network')) {
      return 'Network error. Please check your connection and try again.';
    } else if (error.contains('permission')) {
      return 'You don\'t have permission to create communities.';
    } else if (error.contains('invalid')) {
      return 'Invalid data provided. Please check your inputs.';
    } else if (error.contains('quota')) {
      return 'Service temporarily unavailable. Please try again later.';
    } else {
      return 'Failed to create community. Please try again.';
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: const Text('Create Community'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: CommunityForm(
        isEditing: false,
        onSubmit: _handleFormSubmit,
        isLoading: _isLoading,
        submitButtonText: 'Create Community',
        loadingButtonText: 'Creating...',
        submitButtonIcon: Icons.rocket_launch,
      ),
    );
  }
}
