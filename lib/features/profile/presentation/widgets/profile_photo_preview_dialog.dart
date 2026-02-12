import 'dart:io';
import 'package:chat_kare/features/shared/widgets/app_button.dart';
import 'package:chat_kare/features/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfilePhotoPreviewDialog extends StatelessWidget {
  final File file;
  final VoidCallback onUpload;
  final bool isLoading;

  const ProfilePhotoPreviewDialog({
    super.key,
    required this.file,
    required this.onUpload,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Preview Photo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: Image.file(file, width: 200, height: 200, fit: BoxFit.cover),
          ),
          const SizedBox(height: 16),
          const Text('Do you want to set this as your profile photo?'),
        ],
      ),
      actions: [
        TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
        AppButton(
          isLoading: isLoading,
          onPressed: () {
            if (isLoading == false) {
              onUpload();
            }
          },
          child: AppText("Upload"),
        ),
      ],
    );
  }
}
