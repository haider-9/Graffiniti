import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../core/theme/app_theme.dart';
import '../core/widgets/gradient_button.dart';
import '../core/utils/toast_helper.dart';
import '../core/services/user_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _websiteController = TextEditingController();

  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool _isLoadingData = true;
  bool _isUploadingImage = false;
  Map<String, dynamic> _userData = {};
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (mounted) {
          ToastHelper.error(context, 'No user logged in');
          Navigator.pop(context);
        }
        return;
      }

      // First, load basic data from Firebase Auth (always available offline)
      setState(() {
        _nameController.text = user.displayName ?? '';
        _userData['displayName'] = user.displayName ?? '';
        _userData['email'] = user.email ?? '';
        _userData['profileImageUrl'] = user.photoURL ?? '';
      });

      // Then try to load full data from Firestore (may fail if offline)
      try {
        final userData = await _userService.getUserData(user.uid);
        if (userData != null && mounted) {
          setState(() {
            _userData = userData;
            _nameController.text =
                userData['displayName'] ?? user.displayName ?? '';
            _bioController.text = userData['bio'] ?? '';
            _locationController.text = userData['location'] ?? '';
            _websiteController.text = userData['website'] ?? '';
          });
        }
      } catch (firestoreError) {
        // If Firestore fails (offline), show a warning but continue with Auth data
        if (mounted) {
          ToastHelper.warning(
            context,
            'Offline mode: Some data may not be available',
          );
        }
      }

      setState(() {
        _isLoadingData = false;
      });
    } catch (e) {
      // Fallback: use whatever data we have from Firebase Auth
      final user = _auth.currentUser;
      if (user != null) {
        setState(() {
          _nameController.text = user.displayName ?? '';
          _userData['displayName'] = user.displayName ?? '';
          _userData['email'] = user.email ?? '';
          _userData['profileImageUrl'] = user.photoURL ?? '';
          _isLoadingData = false;
        });
        if (mounted) {
          ToastHelper.warning(context, 'Limited data available offline');
        }
      } else {
        setState(() {
          _isLoadingData = false;
        });
        if (mounted) {
          ToastHelper.error(context, 'Unable to load profile data');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        backgroundColor: AppTheme.primaryBlack,
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentOrange),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildProfilePicture(),
                        const SizedBox(height: 32),
                        _buildTextField(
                          controller: _nameController,
                          label: 'Display Name',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Display name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _bioController,
                          label: 'Bio',
                          icon: Icons.description_outlined,
                          maxLines: 3,
                          maxLength: 150,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _locationController,
                          label: 'Location',
                          icon: Icons.location_on_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _websiteController,
                          label: 'Website',
                          icon: Icons.link_outlined,
                        ),
                        const SizedBox(height: 32),
                        _buildSaveButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.accentGray,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Edit Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePicture() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentOrange.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.secondaryBlack,
                ),
                child: ClipOval(
                  child: _selectedImage != null
                      ? Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                          width: 114,
                          height: 114,
                        )
                      : _userData['profileImageUrl'] != null &&
                            _userData['profileImageUrl'].toString().isNotEmpty
                      ? Image.network(
                          _userData['profileImageUrl'],
                          fit: BoxFit.cover,
                          width: 114,
                          height: 114,
                          errorBuilder: (context, error, stackTrace) {
                            return const CircleAvatar(
                              radius: 57,
                              backgroundColor: Colors.transparent,
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 60,
                              ),
                            );
                          },
                        )
                      : const CircleAvatar(
                          radius: 57,
                          backgroundColor: Colors.transparent,
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _isUploadingImage ? null : _showImagePickerDialog,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: _isUploadingImage
                        ? LinearGradient(
                            colors: [Colors.grey, Colors.grey.shade600],
                          )
                        : AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryBlack, width: 2),
                  ),
                  child: _isUploadingImage
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Tap to change profile picture',
          style: TextStyle(color: AppTheme.secondaryText, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? prefix,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        validator: validator,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppTheme.secondaryText),
          prefixIcon: Icon(icon, color: AppTheme.secondaryText),
          prefixText: prefix,
          prefixStyle: const TextStyle(color: AppTheme.secondaryText),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.accentOrange),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red),
          ),
          contentPadding: const EdgeInsets.all(16),
          counterStyle: const TextStyle(color: AppTheme.secondaryText),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Column(
      children: [
        GradientButton(
          text: _isLoading ? 'Saving...' : 'Save Changes',
          onPressed: _isLoading
              ? () {} // Empty function instead of null
              : () => _saveProfile(),
          icon: _isLoading ? null : Icons.save,
          width: double.infinity,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  Navigator.pop(context);
                },
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppTheme.secondaryText, fontSize: 16),
          ),
        ),
      ],
    );
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.secondaryBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.accentGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Change Profile Picture',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageOption(
                  'Camera',
                  Icons.camera_alt,
                  () => _pickImage(ImageSource.camera),
                ),
                _buildImageOption(
                  'Gallery',
                  Icons.photo_library,
                  () => _pickImage(ImageSource.gallery),
                ),
                _buildImageOption('Remove', Icons.delete, () => _removeImage()),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.accentGray,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: AppTheme.secondaryText, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context); // Close the bottom sheet

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.uploadError(context, itemName: 'image');
      }
    }
  }

  void _removeImage() {
    Navigator.pop(context); // Close the bottom sheet
    setState(() {
      _selectedImage = null;
      _userData['profileImageUrl'] = '';
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        if (mounted) {
          ToastHelper.error(context, 'No user logged in');
        }
        return;
      }

      // Update Firebase Auth display name first (works offline)
      if (_nameController.text.trim() != _auth.currentUser?.displayName) {
        await _auth.currentUser?.updateDisplayName(_nameController.text.trim());
      }

      // Try to update profile image if changed (requires internet)
      if (_selectedImage != null) {
        try {
          setState(() {
            _isUploadingImage = true;
          });
          await _userService.updateProfileImage(userId, _selectedImage);
          setState(() {
            _isUploadingImage = false;
          });
        } catch (imageError) {
          setState(() {
            _isUploadingImage = false;
          });
          if (mounted) {
            ToastHelper.warning(
              context,
              'Image upload failed. Changes will sync when online.',
            );
          }
        }
      } else if (_userData['profileImageUrl'] == '') {
        // Remove profile image
        try {
          await _userService.updateProfileImage(userId, null);
        } catch (e) {
          // Ignore if offline
        }
      }

      // Update other profile fields in Firestore
      try {
        await _userService.updateUserProfile(
          userId: userId,
          displayName: _nameController.text.trim(),
          bio: _bioController.text.trim(),
          location: _locationController.text.trim(),
          website: _websiteController.text.trim(),
        );

        if (mounted) {
          ToastHelper.updateSuccess(context, itemName: 'Profile');
          // Delay navigation to show toast
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        }
      } catch (firestoreError) {
        // If Firestore update fails (offline), still show success for Auth update
        if (mounted) {
          ToastHelper.warning(
            context,
            'Profile saved locally. Will sync when online.',
          );
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('network') ||
            e.toString().contains('offline') ||
            e.toString().contains('UNAVAILABLE')) {
          ToastHelper.warning(
            context,
            'You are offline. Changes will sync when online.',
          );
        } else {
          ToastHelper.error(context, 'Failed to save: ${e.toString()}');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploadingImage = false;
        });
      }
    }
  }
}
