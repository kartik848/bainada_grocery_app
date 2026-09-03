import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

ImageProvider? getProfileImageProvider(String? url) {
  if (url == null || url.trim().isEmpty) return null;
  try {
    if (url.startsWith('data:image')) {
      final base64Data = url.split(',').last;
      return MemoryImage(base64Decode(base64Data));
    }
    return NetworkImage(url);
  } catch (_) {
    return null;
  }
}

class ProfileAvatarPicker extends StatefulWidget {
  final double radius;
  final bool editable;
  final VoidCallback? onPhotoUpdated;

  const ProfileAvatarPicker({
    super.key,
    this.radius = 36,
    this.editable = true,
    this.onPhotoUpdated,
  });

  @override
  State<ProfileAvatarPicker> createState() => _ProfileAvatarPickerState();
}

class _ProfileAvatarPickerState extends State<ProfileAvatarPicker> {
  bool _isUploading = false;

  Future<void> _pickAndUploadImage(ImageSource source) async {
    Navigator.of(context).pop(); // Close bottom sheet
    final picker = ImagePicker();
    try {
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 78,
      );

      if (file == null) return;

      setState(() => _isUploading = true);

      final bytes = await file.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = auth.currentUserModel;

      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(profileImageUrl: base64String);
        await auth.updateProfile(updatedUser);
        widget.onPhotoUpdated?.call();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ प्रोफ़ाइल फ़ोटो सफलतापूर्वक अपडेट हो गई'),
              backgroundColor: AppColors.primary,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('फ़ोटो अपलोड नहीं हो सकी: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showImagePickerSheet(BuildContext context) {
    if (!widget.editable) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'प्रोफ़ाइल फ़ोटो बदलें',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            const Text(
              'दुकान या अपना आधिकारिक फ़ोटो अपलोड करें',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'कैमरा (Camera)',
                  color: AppColors.primary,
                  onTap: () => _pickAndUploadImage(ImageSource.camera),
                ),
                _buildPickerOption(
                  icon: Icons.photo_library_rounded,
                  label: 'गैलरी (Gallery)',
                  color: const Color(0xFFE65100),
                  onTap: () => _pickAndUploadImage(ImageSource.gallery),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUserModel;
    final imgProvider = getProfileImageProvider(user?.profileImageUrl);

    return GestureDetector(
      onTap: widget.editable ? () => _showImagePickerSheet(context) : null,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(30),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: Colors.white, width: 2.5),
            ),
            child: CircleAvatar(
              radius: widget.radius,
              backgroundColor: AppColors.primarySurface,
              backgroundImage: imgProvider,
              child: _isUploading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                    )
                  : (imgProvider == null
                      ? Icon(
                          user?.role == UserRole.merchant
                              ? Icons.storefront_rounded
                              : (user?.role == UserRole.salesman ? Icons.badge_rounded : Icons.local_shipping_rounded),
                          size: widget.radius * 0.95,
                          color: AppColors.primary,
                        )
                      : null),
            ),
          ),
          if (widget.editable)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
