import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/community.dart';
import '../view_model/community_view_model.dart';
import 'community_form_widgets.dart';

class EditCommunityScreen extends StatefulWidget {
  final Community community;

  const EditCommunityScreen({super.key, required this.community});

  @override
  State<EditCommunityScreen> createState() => _EditCommunityScreenState();
}

class _EditCommunityScreenState extends State<EditCommunityScreen> {
  bool _isLoading = false;
  final GlobalKey<CommunityFormState> _formKey =
      GlobalKey<CommunityFormState>();

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
        title: const Text('Edit Community'),
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading
            ? null
            : () => _formKey.currentState?.submitForm(),
        icon: _isLoading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save),
        label: Text(_isLoading ? 'Saving...' : 'Save'),
        elevation: 4,
      ),
      body: CommunityForm(
        key: _formKey,
        initialData: initialData,
        isEditing: true,
        onSubmit: _handleFormSubmit,
        isLoading: _isLoading,
      ),
    );
  }

  Future<void> _handleFormSubmit(CommunityFormData data) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final viewModel = context.read<CommunityViewModel>();

      await viewModel.updateCommunity(
        communityId: widget.community.id,
        name: data.name,
        description: data.description,
        photoUrl: data.photoUrl ?? '',
        bannerUrl: data.bannerUrl ?? '',
        tags: data.tags,
        rules: data.rules,
        visibility: data.visibility,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Community updated successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating community: $e'),
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
}
