import 'dart:io';
import 'package:chat_kare/core/utils/media_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePhotoSelectionSheet extends StatelessWidget {
  final Function(File) onPhotoSelected;

  const ProfilePhotoSelectionSheet({super.key, required this.onPhotoSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Change Profile Photo',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPhotoOption(
                context,
                icon: Icons.camera_alt,
                label: 'Camera',
                onTap: () => _handleSelection(context, ImageSource.camera),
              ),
              _buildPhotoOption(
                context,
                icon: Icons.photo_library,
                label: 'Gallery',
                onTap: () => _handleSelection(context, ImageSource.gallery),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPhotoOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _handleSelection(
    BuildContext context,
    ImageSource source,
  ) async {
    Navigator.pop(context); // Close sheet
    File? file;
    if (source == ImageSource.camera) {
      file = await MediaPicker.instance.pickImageFromCamera();
    } else {
      file = await MediaPicker.instance.pickImageFromGallery();
    }

    if (file != null) {
      final croppedFile = await MediaPicker.instance.cropImage(file);
      if (croppedFile != null) {
        onPhotoSelected(croppedFile);
      }
    }
  }
}
