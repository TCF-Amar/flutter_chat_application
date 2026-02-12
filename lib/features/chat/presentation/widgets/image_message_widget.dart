import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_kare/core/routes/app_routes.dart';
import 'package:chat_kare/features/chat/domain/entities/chats_entity.dart';
import 'package:chat_kare/features/chat/presentation/widgets/upload_overlay_widgets.dart';
import 'package:chat_kare/features/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

//* Widget for displaying image messages with upload state management.
//*
//* Handles three states:
//* 1. Uploading: Local file preview + progress overlay with cancel
//* 2. Failed: Local file preview + error overlay with retry
//* 3. Success: Cached network image + tap to fullscreen
//*
//* Also supports optional text caption below the image.
class ImageMessageWidget extends StatelessWidget {
  final ChatsEntity message;
  final VoidCallback onCancelUpload;
  final VoidCallback onRetryUpload;

  const ImageMessageWidget({
    super.key,
    required this.message,
    required this.onCancelUpload,
    required this.onRetryUpload,
  });

  @override
  Widget build(BuildContext context) {
    final isUploading = message.status == MessageStatus.uploading;
    final isFailed = message.status == MessageStatus.failed;
    final hasLocalFile = message.localFilePath != null;

    return GestureDetector(
      onTap: () {
        // Navigate to full-screen media viewer only for successfully uploaded images
        if (!isUploading && !isFailed && message.mediaUrl != null) {
          context.pushNamed(
            AppRoutes.networkMediaView.name,
            extra: {'url': message.mediaUrl, 'type': MessageType.image},
          );
        }
      },
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image preview (local or network)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildImagePreview(isUploading, isFailed, hasLocalFile),
              ),

              // Optional caption text
              if (message.text.isNotEmpty) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AppText(
                    message.text,
                    fontSize: 16,
                    overflow: TextOverflow.visible,
                    color: Colors.white, // Caption always white for contrast
                  ),
                ),
              ],
            ],
          ),

          // State overlay for upload in progress
          if (isUploading)
            UploadingOverlay(message: message, onCancel: onCancelUpload),

          // State overlay for failed upload
          if (isFailed) FailedOverlay(message: message, onRetry: onRetryUpload),
        ],
      ),
    );
  }

  //* Builds appropriate image preview based on upload state.
  //*
  //* Priority order:
  //* 1. Local file (during upload/failed states)
  //* 2. Network image (successful upload)
  //* 3. Placeholder (fallback)
  Widget _buildImagePreview(
    bool isUploading,
    bool isFailed,
    bool hasLocalFile,
  ) {
    // Show local file preview during upload or after failure
    if ((isUploading || isFailed) && hasLocalFile) {
      return Image.file(
        File(message.localFilePath!),
        width: 250,
        height: 250,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 250,
            height: 250,
            color: Colors.grey.withValues(alpha: 0.3),
            child: const Icon(Icons.broken_image, size: 50),
          );
        },
      );
    }

    // Show cached network image for successfully uploaded images
    if (message.mediaUrl != null) {
      return CachedNetworkImage(
        imageUrl: message.mediaUrl!,
        width: 250,
        height: 250,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 250,
          height: 250,
          color: Colors.grey.withValues(alpha: 0.1),
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      );
    }

    // Fallback placeholder
    return Container(
      width: 250,
      height: 250,
      color: Colors.grey.withValues(alpha: 0.3),
      child: const Icon(Icons.image, size: 50),
    );
  }
}
