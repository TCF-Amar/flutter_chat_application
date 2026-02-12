import 'package:chat_kare/core/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

//* Popup menu button for media attachments.
//*
//* Provides options for:
//* - Camera photo
//* - Gallery photo
//* - Camera video
//* - Gallery video
//* - Document file
//* - Location sharing
//*
//* Handles media preview navigation for selected attachments.
class AttachmentMenuButton extends StatelessWidget {
  final Future<Map<String, dynamic>?> Function() onTakePhoto;
  final Future<Map<String, dynamic>?> Function() onPickImageFromGallery;
  final Future<Map<String, dynamic>?> Function() onPickVideoFromCamera;
  final Future<Map<String, dynamic>?> Function() onPickVideoFromGallery;
  final Future<Map<String, dynamic>?> Function() onPickDocument;
  final VoidCallback onShareLocation;

  const AttachmentMenuButton({
    super.key,
    required this.onTakePhoto,
    required this.onPickImageFromGallery,
    required this.onPickVideoFromCamera,
    required this.onPickVideoFromGallery,
    required this.onPickDocument,
    required this.onShareLocation,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.attach_file),
      onSelected: (value) => _handleAttachment(context, value),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'camera',
          child: Row(
            children: [
              Icon(Icons.camera_alt, size: 20),
              SizedBox(width: 8),
              Text('Camera'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'gallery',
          child: Row(
            children: [
              Icon(Icons.photo_library, size: 20),
              SizedBox(width: 8),
              Text('Gallery'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'cameraVideo',
          child: Row(
            children: [
              Icon(Icons.camera_alt, size: 20),
              SizedBox(width: 8),
              Text('Camera Video'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'galleryVideo',
          child: Row(
            children: [
              Icon(Icons.photo_library, size: 20),
              SizedBox(width: 8),
              Text('Gallery Video'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'document',
          child: Row(
            children: [
              Icon(Icons.insert_drive_file, size: 20),
              SizedBox(width: 8),
              Text('Document'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'location',
          child: Row(
            children: [
              Icon(Icons.location_on, size: 20),
              SizedBox(width: 8),
              Text('Location'),
            ],
          ),
        ),
      ],
    );
  }

  //* Handles attachment selection and navigates to preview if needed.
  //*
  //* For media files (photo/video), navigates to preview screen.
  //* For location, directly triggers sharing without preview.
  Future<void> _handleAttachment(BuildContext context, String type) async {
    Map<String, dynamic>? result;

    // Handle different attachment types
    switch (type) {
      case 'camera':
        result = await onTakePhoto();
        break;
      case 'gallery':
        result = await onPickImageFromGallery();
        break;
      case 'cameraVideo':
        result = await onPickVideoFromCamera();
        break;
      case 'galleryVideo':
        result = await onPickVideoFromGallery();
        break;
      case 'document':
        result = await onPickDocument();
        break;
      case 'location':
        // Location sharing doesn't need preview
        onShareLocation();
        return;
    }

    // Navigate to media preview screen if media was selected
    if (result != null && context.mounted) {
      // Extract the onSend callback from result if it exists
      final onSendCallback = result['onSend'];

      context.pushNamed(
        AppRoutes.mediaPreview.name,
        extra: {
          'file': result['file'],
          'type': result['type'],
          // Pass the onSend callback if available
          if (onSendCallback != null) 'onSend': onSendCallback,
        },
      );
    }
  }
}
