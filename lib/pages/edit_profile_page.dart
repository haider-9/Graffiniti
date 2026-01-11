import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../core/theme/app_theme.dart';
import '../core/widgets/gradient_button.dart';
import '../core/utils/toast_helper.dart';
import '../core/services/user_service.dart';
import '../core/config/cloudinary_config.dart';

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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _isLoadingData = true;
  bool _isUploadingImage = false;
  Map<String, dynamic> _userData = {};
  File? _selectedImage;
  File? _selectedBannerImage;
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
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 50,
                      ), // Space for overlapping profile image
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
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryBlack,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Edit Profile',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Cover/Banner Image
            _buildCoverImage(),
            // Dark gradient overlay for better visual hierarchy
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.1),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  stops: const [0.0, 0.2, 0.6, 1.0],
                ),
              ),
            ),
            // Cover image action buttons positioned higher for better spacing
            Positioned(bottom: 25, right: 15, child: _buildCoverImageActions()),
            // Profile picture positioned to overlap from cover into content area
            Positioned(bottom: 10, left: 20, child: _buildProfilePicture()),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage() {
    if (_selectedBannerImage != null) {
      return Image.file(_selectedBannerImage!, fit: BoxFit.cover);
    }

    if (_userData['bannerImageUrl'] != null &&
        _userData['bannerImageUrl'].toString().isNotEmpty) {
      return Image.network(
        _userData['bannerImageUrl'],
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultCover();
        },
      );
    }

    return _buildDefaultCover();
  }

  Widget _buildDefaultCover() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a1a1a), Color(0xFF2d2d2d), Color(0xFF404040)],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              color: Colors.white54,
              size: 48,
            ),
            SizedBox(height: 8),
            Text(
              'Add Cover Photo',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImageActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCoverActionButton(
          icon: Icons.camera_alt,
          label: 'Change Cover',
          onTap: _showBannerImagePickerDialog,
        ),
        if (_selectedBannerImage != null ||
            (_userData['bannerImageUrl'] != null &&
                _userData['bannerImageUrl'].toString().isNotEmpty)) ...[
          const SizedBox(width: 8),
          _buildCoverActionButton(
            icon: Icons.delete_outline,
            label: 'Remove',
            onTap: _removeBannerImage,
            isDestructive: true,
          ),
        ],
      ],
    );
  }

  Widget _buildCoverActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withValues(alpha: 0.8)
              : Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePicture() {
    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryBlack, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipOval(
            child: _selectedImage != null
                ? Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                    width: 80,
                    height: 80,
                  )
                : _userData['profileImageUrl'] != null &&
                      _userData['profileImageUrl'].toString().isNotEmpty
                ? Image.network(
                    _userData['profileImageUrl'],
                    fit: BoxFit.cover,
                    width: 80,
                    height: 80,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppTheme.accentGray,
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 40,
                        ),
                      );
                    },
                  )
                : Container(
                    color: AppTheme.accentGray,
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 40,
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
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.accentOrange,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryBlack, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _isUploadingImage
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.camera_alt, color: Colors.white, size: 18),
            ),
          ),
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

  void _showBannerImagePickerDialog() {
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
              'Change Banner Image',
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
                  () => _pickBannerImage(ImageSource.camera),
                ),
                _buildImageOption(
                  'Gallery',
                  Icons.photo_library,
                  () => _pickBannerImage(ImageSource.gallery),
                ),
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
            style: TextStyle(color: AppTheme.secondaryText, fontSize: 12),
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
        // Validate file size
        final file = File(pickedFile.path);
        final fileSize = await file.length();

        if (fileSize > CloudinaryConfig.maxProfileImageSize) {
          if (mounted) {
            ToastHelper.error(
              context,
              'Image too large. Please select an image smaller than 5MB.',
            );
          }
          return;
        }

        // Validate file format
        final extension = pickedFile.path.split('.').last.toLowerCase();
        if (!CloudinaryConfig.supportedFormats.contains(extension) &&
            !['jpg', 'jpeg'].contains(extension)) {
          if (mounted) {
            ToastHelper.error(
              context,
              'Unsupported format. Please select a JPG, PNG, or WebP image.',
            );
          }
          return;
        }

        setState(() {
          _selectedImage = file;
        });
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.error(context, 'Failed to select image: ${e.toString()}');
      }
    }
  }

  Future<void> _pickBannerImage(ImageSource source) async {
    Navigator.pop(context); // Close the bottom sheet

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Validate file size
        final file = File(pickedFile.path);
        final fileSize = await file.length();

        if (fileSize > CloudinaryConfig.maxBannerImageSize) {
          if (mounted) {
            ToastHelper.error(
              context,
              'Image too large. Please select an image smaller than 10MB.',
            );
          }
          return;
        }

        // Validate file format
        final extension = pickedFile.path.split('.').last.toLowerCase();
        if (!CloudinaryConfig.supportedFormats.contains(extension) &&
            !['jpg', 'jpeg'].contains(extension)) {
          if (mounted) {
            ToastHelper.error(
              context,
              'Unsupported format. Please select a JPG, PNG, or WebP image.',
            );
          }
          return;
        }

        setState(() {
          _selectedBannerImage = file;
        });
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.error(
          context,
          'Failed to select banner image: ${e.toString()}',
        );
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

  void _removeBannerImage() {
    setState(() {
      _selectedBannerImage = null;
      _userData['bannerImageUrl'] = '';
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

      String? profileImageUrl;
      String? bannerImageUrl;

      // Handle profile image update/removal
      if (_selectedImage != null) {
        try {
          setState(() {
            _isUploadingImage = true;
          });
          profileImageUrl = await _userService.updateProfileImage(
            userId,
            _selectedImage,
          );
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
              'Image upload failed. Other changes will be saved.',
            );
          }
        }
      } else if (_userData['profileImageUrl'] == '') {
        // Remove profile image
        try {
          profileImageUrl = await _userService.updateProfileImage(userId, null);
        } catch (e) {
          // Ignore if offline
        }
      }

      // Handle banner image update/removal
      if (_selectedBannerImage != null) {
        try {
          bannerImageUrl = await _userService.updateBannerImage(
            userId,
            _selectedBannerImage,
          );
        } catch (imageError) {
          if (mounted) {
            ToastHelper.warning(
              context,
              'Banner image upload failed. Other changes will be saved.',
            );
          }
        }
      } else if (_userData['bannerImageUrl'] == '') {
        // Remove banner image
        try {
          bannerImageUrl = await _userService.updateBannerImage(userId, null);
        } catch (e) {
          // Ignore if offline
        }
      }

      // Update Firebase Auth display name first (works offline)
      if (_nameController.text.trim() != _auth.currentUser?.displayName) {
        await _auth.currentUser?.updateDisplayName(_nameController.text.trim());
      }

      // Update other profile fields (only if images weren't updated separately)
      if (profileImageUrl == null && bannerImageUrl == null) {
        try {
          await _userService.updateUserProfile(
            userId: userId,
            displayName: _nameController.text.trim(),
            bio: _bioController.text.trim(),
            location: _locationController.text.trim(),
            website: _websiteController.text.trim(),
          );
        } catch (firestoreError) {
          if (mounted) {
            if (firestoreError.toString().contains('network') ||
                firestoreError.toString().contains('offline') ||
                firestoreError.toString().contains('UNAVAILABLE')) {
              ToastHelper.warning(
                context,
                'You are offline. Changes will sync when online.',
              );
            } else {
              ToastHelper.error(
                context,
                'Failed to save: ${firestoreError.toString()}',
              );
            }
          }
          return;
        }
      } else {
        // If images were updated, just update the text fields in Firestore
        try {
          await _firestore.collection('users').doc(userId).update({
            'displayName': _nameController.text.trim(),
            'bio': _bioController.text.trim(),
            'location': _locationController.text.trim(),
            'website': _websiteController.text.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          // Handle error but don't fail the whole operation
          debugPrint('Error updating text fields: $e');
        }
      }

      if (mounted) {
        ToastHelper.updateSuccess(context, itemName: 'Profile');
        // Delay navigation to show toast
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate success
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
