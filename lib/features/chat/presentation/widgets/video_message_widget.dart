import 'dart:io';
import 'package:chat_kare/core/routes/app_routes.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_kare/core/theme/theme_extensions.dart';
import 'package:chat_kare/features/chat/domain/entities/chats_entity.dart';
import 'package:chat_kare/features/chat/presentation/widgets/upload_overlay_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
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
//* - Video caching (Download once, play forever)
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
  bool _isDownloaded = false;
  bool _isDownloadingVideo = false;
  File? _cachedFile;

  @override
  void initState() {
    super.initState();
    _checkCacheStatus();
    _generateThumbnail();
  }

  @override
  void didUpdateWidget(VideoMessageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.message.localFilePath != oldWidget.message.localFilePath ||
        widget.message.mediaUrl != oldWidget.message.mediaUrl) {
      _checkCacheStatus();
      _generateThumbnail();
    }
  }

  Future<void> _checkCacheStatus() async {
    if (widget.message.localFilePath != null &&
        widget.message.localFilePath!.isNotEmpty) {
      setState(() {
        _isDownloaded = true;
        _cachedFile = File(widget.message.localFilePath!);
      });
      return;
    }

    final url = widget.message.videoUrl ?? widget.message.mediaUrl;
    if (url != null && url.isNotEmpty) {
      final fileInfo = await DefaultCacheManager().getFileFromCache(url);
      if (fileInfo != null && mounted) {
        setState(() {
          _isDownloaded = true;
          _cachedFile = fileInfo.file;
        });
      }
    }
  }

  Future<void> _downloadVideo() async {
    final url = widget.message.videoUrl ?? widget.message.mediaUrl;
    if (url == null) return;

    setState(() {
      _isDownloadingVideo = true;
    });

    try {
      final file = await DefaultCacheManager().getSingleFile(url);
      if (mounted) {
        setState(() {
          _isDownloaded = true;
          _cachedFile = file;
          _isDownloadingVideo = false;
        });
      }
    } catch (e) {
      debugPrint('Error downloading video: $e');
      if (mounted) {
        setState(() {
          _isDownloadingVideo = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to download video: $e')));
      }
    }
  }

  Future<void> _generateThumbnail() async {
    if (!mounted) return;

    // If we have a separate videoUrl, then mediaUrl is the thumbnail.
    // We don't need to generate a local thumbnail file if we can just use the URL.
    if (widget.message.videoUrl != null && widget.message.mediaUrl != null) {
      // We will handle this in build method by checking mediaUrl directly
      return;
    }

    setState(() {
      _isLoadingThumbnail = true;
    });

    try {
      String? path;
      final tempDir = await getTemporaryDirectory();

      // Prefer local file/cached file for thumbnail generation if available
      if (_cachedFile != null) {
        path = await VideoThumbnail.thumbnailFile(
          video: _cachedFile!.path,
          thumbnailPath: tempDir.path,
          imageFormat: ImageFormat.JPEG,
          maxHeight: 150,
          quality: 75,
        );
      } else if (widget.message.localFilePath != null &&
          widget.message.localFilePath!.isNotEmpty) {
        path = await VideoThumbnail.thumbnailFile(
          video: widget.message.localFilePath!,
          thumbnailPath: tempDir.path,
          imageFormat: ImageFormat.JPEG,
          maxHeight: 150,
          quality: 75,
        );
      } else if (widget.message.mediaUrl != null &&
          widget.message.mediaUrl!.isNotEmpty) {
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
      if (mounted) {
        setState(() {
          _isLoadingThumbnail = false;
        });
      }
    }
  }

  void _handleTap() {
    final isUploading = widget.message.status == MessageStatus.uploading;
    final isFailed = widget.message.status == MessageStatus.failed;

    if (isUploading || isFailed) return;

    if (_isDownloaded && _cachedFile != null) {
      // Play from local cache
      context.pushNamed(
        AppRoutes.networkMediaView.name,
        extra: {'url': _cachedFile!.path, 'type': MessageType.video},
      );
    } else {
      // Download
      _downloadVideo();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUploading = widget.message.status == MessageStatus.uploading;
    final isFailed = widget.message.status == MessageStatus.failed;

    return GestureDetector(
      onTap: _handleTap,
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
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    )
                  else if (widget.message.videoUrl != null &&
                      widget.message.mediaUrl != null)
                    CachedNetworkImage(
                      imageUrl: widget.message.mediaUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _buildPlaceholder(),
                      errorWidget: (_, __, ___) => _buildPlaceholder(),
                    )
                  else
                    _buildPlaceholder(),

                  // Overlay Icons (Play vs Download vs loading)
                  if (!isUploading && !isFailed) ...[
                    if (_isDownloadingVideo)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      )
                    else if (_isDownloaded)
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
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.download_rounded,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                  ],

                  // Loading indicator for thumbnail (only if not downloading video)
                  if (_isLoadingThumbnail && !_isDownloadingVideo)
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
