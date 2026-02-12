import 'dart:io';

import 'package:chat_kare/features/chat/domain/entities/chats_entity.dart';
import 'package:chat_kare/features/chat/presentation/pages/media_preview_page.dart';
import 'package:flutter/material.dart';

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
      final file = result['file'] as File;
      final messageType = result['type'] as MessageType;
      // Extract the onSend callback from result
      final onSendCallback = result['onSend'];

      if (onSendCallback != null) {
        // Use Navigator.push instead of context.pushNamed to preserve the underlying ChatPage
        // This prevents the "Contact details missing" error when popping back
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MediaPreviewPage(
              file: file,
              type: messageType,
              onSend: onSendCallback,
            ),
          ),
        );
      }
    }
  }
}
