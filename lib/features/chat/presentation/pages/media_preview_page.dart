import 'dart:io';
import 'package:chat_kare/core/theme/theme_extensions.dart';
import 'package:chat_kare/features/chat/domain/entities/chats_entity.dart';
import 'package:chat_kare/features/shared/widgets/index.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:chat_kare/core/utils/media_picker.dart';

class MediaPreviewPage extends StatefulWidget {
  final File file;
  final MessageType type;
  final Function(File file, String caption) onSend;

  const MediaPreviewPage({
    super.key,
    required this.file,
    required this.type,
    required this.onSend,
  });

  @override
  State<MediaPreviewPage> createState() => _MediaPreviewPageState();
}

class _MediaPreviewPageState extends State<MediaPreviewPage> {
  final TextEditingController _captionController = TextEditingController();
  VideoPlayerController? _videoController;
  late File _currentFile;

  @override
  void initState() {
    super.initState();
    _currentFile = widget.file;

    if (widget.type == MessageType.video) {
      _videoController = VideoPlayerController.file(_currentFile)
        ..initialize().then((_) {
          setState(() {}); // Update UI when video is initialized
          _videoController!.play();
          _videoController!.setLooping(true);
        });
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _editImage() async {
    if (widget.type != MessageType.image) return;

    final edited = await MediaPicker.instance.editImage(context, _currentFile);
    if (edited != null) {
      if (mounted) {
        setState(() {
          _currentFile = edited;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (widget.type == MessageType.image)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: _editImage,
            ),
        ],
      ),
      body: Stack(
        children: [
          Center(child: _buildPreviewContent()),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _captionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Add a caption...',
                        hintStyle: const TextStyle(color: Colors.white70),
                        fillColor: Colors.white.withOpacity(0.2),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    mini: true,
                    backgroundColor: context.colorScheme.primary,
                    child: const Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      widget.onSend(
                        _currentFile,
                        _captionController.text.trim(),
                      );
                      context.pop(); // Close preview after sending
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewContent() {
    if (widget.type == MessageType.image) {
      return Image.file(
        _currentFile,
        key: ValueKey(_currentFile.path),
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
      );
    } else if (widget.type == MessageType.video) {
      if (_videoController != null && _videoController!.value.isInitialized) {
        return Center(
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
        );
      } else {
        return const Center(child: CircularProgressIndicator());
      }
    } else {
      // Document or other types
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              _currentFile.path.split('/').last,
              // style: context.textTheme.titleMedium?.copyWith(
              //   color: Colors.white,
              // ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }
}
