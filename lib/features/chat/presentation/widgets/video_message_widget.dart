import 'package:chat_kare/core/routes/app_routes.dart';
import 'package:chat_kare/features/chat/domain/entities/chats_entity.dart';
import 'package:chat_kare/features/chat/presentation/widgets/upload_overlay_widgets.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

//* Widget for displaying video messages with upload state management.
//*
//* Features:
//* - Distinct visual for local vs network videos
//* - Upload progress with cancel
//* - Failed state with retry
//* - Play button overlay for successful uploads
class VideoMessageWidget extends StatelessWidget {
  final ChatsEntity message;
  final VoidCallback onCancelUpload;
  final VoidCallback onRetryUpload;

  const VideoMessageWidget({
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
        // Navigate to video player for successfully uploaded videos
        if (!isUploading && !isFailed && message.mediaUrl != null) {
          context.pushNamed(
            AppRoutes.networkMediaView.name,
            extra: {'url': message.mediaUrl, 'type': MessageType.video},
          );
        }
      },
      child: Stack(
        children: [
          Container(
            width: 250,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Local video placeholder
                if ((isUploading || isFailed) && hasLocalFile)
                  const Icon(Icons.videocam, size: 50, color: Colors.white70)
                // Play button for ready-to-play videos
                else if (message.mediaUrl != null)
                  const Icon(
                    Icons.play_circle_fill,
                    size: 50,
                    color: Colors.white,
                  ),
              ],
            ),
          ),

          // Upload progress overlay
          if (isUploading)
            UploadingOverlay(message: message, onCancel: onCancelUpload),

          // Failed upload overlay
          if (isFailed) FailedOverlay(message: message, onRetry: onRetryUpload),
        ],
      ),
    );
  }
}
