import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../shared/utils/app_toast.dart';
import '../../../shared/utils/avatar_utils.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  String _selectedBloodGroup = 'O+';
  String _selectedGender = 'Male';
  bool _isAvailable = true;
  bool _isLoading = false;

  File? _imageFile;
  String? _currentAvatarUrl;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _selectedBloodGroup = user?.bloodGroup ?? 'O+';
    _selectedGender = user?.gender ?? 'Male';
    _isAvailable = user?.isAvailableToDonate ?? true;
    _currentAvatarUrl = user?.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    try {
      showModalBottomSheet(
        context: context,
        builder: (ctx) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(lang.getText('gallery')),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picked = await _picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 400, // Smaller for Base64 storage
                    maxHeight: 400,
                    imageQuality: 30, // More compression for smaller file size
                  );
                  if (picked != null) {
                    setState(() => _imageFile = File(picked.path));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(lang.getText('camera')),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picked = await _picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 400, // Smaller for Base64 storage
                    maxHeight: 400,
                    imageQuality: 30, // More compression for smaller file size
                  );
                  if (picked != null) {
                    setState(() => _imageFile = File(picked.path));
                  }
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        AppToast.error(context, lang.getText('pick_image_failed'));
      }
    }
  }

  Future<void> _handleSave() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    String? newAvatarUrl = _currentAvatarUrl;

    // 1. Process Image if Changed
    if (_imageFile != null) {
      try {
        final userId = authProvider.user?.id;
        if (userId != null) {
          // Save image locally for future Plesk upload
          final appDir = await getApplicationDocumentsDirectory();
          final avatarDir = Directory('${appDir.path}/avatars');
          if (!await avatarDir.exists()) {
            await avatarDir.create(recursive: true);
          }

          final extension = _imageFile!.path.split('.').last.toLowerCase();
          final localPath = '${avatarDir.path}/$userId.$extension';
          await _imageFile!.copy(localPath);

          // For now, store as optimized Base64 (will be replaced with Plesk URL later)
          // Image is already compressed by image_picker (maxWidth: 400, quality: 30)
          final bytes = await _imageFile!.readAsBytes();
          final base64String = base64Encode(bytes);
          final mimeType = ['jpg', 'jpeg'].contains(extension)
              ? 'image/jpeg'
              : 'image/$extension';

          newAvatarUrl = 'data:$mimeType;base64,$base64String';

          debugPrint('Avatar saved locally to: $localPath');
          debugPrint('Base64 length: ${base64String.length} chars');
        }
      } catch (e) {
        debugPrint('Error processing image: $e');
        setState(() => _isLoading = false);
        if (mounted) {
          AppToast.error(context, lang.getText('process_photo_failed'));
        }
        return;
      }
    }

    // 2. Update Profile
    debugPrint('🚀 Calling updateProfile...');
    debugPrint(
      '🔗 Avatar URL prefix: ${newAvatarUrl?.substring(0, newAvatarUrl.length > 50 ? 50 : newAvatarUrl.length)}...',
    );

    final success = await authProvider.updateProfile({
      'full_name': _nameController.text.trim(),
      'phone_number': _phoneController.text.trim(),
      'blood_group': _selectedBloodGroup,
      'gender': _selectedGender,
      'is_available_to_donate': _isAvailable,
      'avatar_url': newAvatarUrl,
    });

    debugPrint('✅ updateProfile returned: $success');

    setState(() => _isLoading = false);

    if (success && mounted) {
      AppToast.success(context, lang.getText('profile_updated'));
      context.pop();
    } else if (mounted) {
      debugPrint('❌ Profile update failed: ${authProvider.error}');
      AppToast.error(
        context,
        authProvider.error ?? lang.getText('profile_update_failed'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(lang.getText('edit_profile')),
        backgroundColor: context.scaffoldBg,
        surfaceTintColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleSave,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(lang.getText('save')),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Avatar Section
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!) as ImageProvider
                          : AvatarUtils.getImageProvider(_currentAvatarUrl),
                      child: (_imageFile == null && _currentAvatarUrl == null)
                          ? Text(
                              _getInitials(_nameController.text),
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: lang.getText('full_name'),
                prefixIcon: const Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  v?.isEmpty ?? true ? lang.getText('required') : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Phone Field
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: lang.getText('phone_number'),
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Gender Field
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: InputDecoration(
                labelText:
                    lang.getText('gender') ??
                    'Gender', // Fallback if key missing
                prefixIcon: const Icon(Icons.wc),
              ),
              items: [
                'Male',
                'Female',
                'Other',
              ].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (v) => setState(() => _selectedGender = v ?? 'Male'),
            ),
            const SizedBox(height: 24),

            // Blood Group Selection
            Text(
              lang.getText('blood_group'),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: AppConstants.bloodGroups.length,
              itemBuilder: (context, index) {
                final group = AppConstants.bloodGroups[index];
                final isSelected = group == _selectedBloodGroup;

                return GestureDetector(
                  onTap: () => setState(() => _selectedBloodGroup = group),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : context.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        group,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Availability Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _isAvailable
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.volunteer_activism,
                      color: _isAvailable
                          ? AppColors.success
                          : AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.getText('available_to_donate'),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _isAvailable
                              ? lang.getText('available_desc_true')
                              : lang.getText('available_desc_false'),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _isAvailable,
                    onChanged: (v) => setState(() => _isAvailable = v),
                    activeTrackColor: AppColors.success,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Delete Account Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.error,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        lang.getText('danger_zone'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    lang.getText('delete_account_desc'),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showDeleteConfirmation,
                      icon: const Icon(Icons.delete_forever),
                      label: Text(lang.getText('delete_account')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: 12),
            Text(lang.getText('delete_account')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.getText('delete_account_confirm_title'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(lang.getText('delete_account_confirm_desc')),
            const SizedBox(height: 8),
            const Text('• All your profile information'),
            const Text('• Your donation history'),
            const Text('• Your blood request history'),
            const Text('• All earned points and badges'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.getText('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(lang.getText('delete_forever')),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.deleteAccount();

    setState(() => _isLoading = false);

    if (success && mounted) {
      AppToast.success(context, lang.getText('account_deleted'));
      context.go('/login');
    } else if (mounted) {
      AppToast.error(
        context,
        authProvider.error ?? lang.getText('delete_failed'),
      );
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
