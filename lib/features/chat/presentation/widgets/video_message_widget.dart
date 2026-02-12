import 'dart:io';
import 'package:chat_kare/core/routes/app_routes.dart';
import 'package:chat_kare/core/theme/theme_extensions.dart';
import 'package:chat_kare/features/chat/domain/entities/chats_entity.dart';
import 'package:chat_kare/features/chat/presentation/widgets/upload_overlay_widgets.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

//* Widget for displaying video messages with upload state management.
//*
//* Features:
//* - Distinct visual for local vs network videos
//* - Upload progress with cancel
//* - Failed state with retry
//* - Play button overlay for successful uploads
//* - Thumbnail generation and caching
class VideoMessageWidget extends StatefulWidget {
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
  State<VideoMessageWidget> createState() => _VideoMessageWidgetState();
}

class _VideoMessageWidgetState extends State<VideoMessageWidget> {
  String? _thumbnailPath;
  bool _isLoadingThumbnail = true;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  @override
  void didUpdateWidget(VideoMessageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.message.localFilePath != oldWidget.message.localFilePath ||
        widget.message.mediaUrl != oldWidget.message.mediaUrl) {
      _generateThumbnail();
    }
  }

  Future<void> _generateThumbnail() async {
    if (!mounted) return;

    setState(() {
      _isLoadingThumbnail = true;
    });

    try {
      String? path;
      final tempDir = await getTemporaryDirectory();

      if (widget.message.localFilePath != null &&
          widget.message.localFilePath!.isNotEmpty) {
        // Generate from local file
        path = await VideoThumbnail.thumbnailFile(
          video: widget.message.localFilePath!,
          thumbnailPath: tempDir.path,
          imageFormat: ImageFormat.JPEG,
          maxHeight: 150,
          quality: 75,
        );
      } else if (widget.message.mediaUrl != null &&
          widget.message.mediaUrl!.isNotEmpty) {
        // Generate from network URL
        path = await VideoThumbnail.thumbnailFile(
          video: widget.message.mediaUrl!,
          thumbnailPath: tempDir.path,
          imageFormat: ImageFormat.JPEG,
          maxHeight: 150,
          quality: 75,
        );
      }

      if (mounted) {
        setState(() {
          _thumbnailPath = path;
          _isLoadingThumbnail = false;
        });
      }
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
      if (mounted) {
        setState(() {
          _isLoadingThumbnail = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUploading = widget.message.status == MessageStatus.uploading;
    final isFailed = widget.message.status == MessageStatus.failed;

    return GestureDetector(
      onTap: () {
        // Navigate to video player for successfully uploaded videos
        if (!isUploading && !isFailed && widget.message.mediaUrl != null) {
          context.pushNamed(
            AppRoutes.networkMediaView.name,
            extra: {'url': widget.message.mediaUrl, 'type': MessageType.video},
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                alignment: Alignment.center,
                fit: StackFit.expand,
                children: [
                  // Thumbnail or Placeholder
                  if (_thumbnailPath != null)
                    Image.file(
                      File(_thumbnailPath!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholder(),
                    )
                  else
                    _buildPlaceholder(),

                  // Play button for ready-to-play videos
                  if (!_isLoadingThumbnail && widget.message.mediaUrl != null)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_circle_fill,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),

                  // Loading indicator for thumbnail
                  if (_isLoadingThumbnail)
                    const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white70,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Upload progress overlay
          if (isUploading)
            UploadingOverlay(
              message: widget.message,
              onCancel: widget.onCancelUpload,
            ),

          // Failed upload overlay
          if (isFailed)
            FailedOverlay(
              message: widget.message,
              onRetry: widget.onRetryUpload,
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: context.colorScheme.surface,
      child: const Center(
        child: Icon(Icons.videocam, size: 50, color: Colors.white70),
      ),
    );
  }
}
