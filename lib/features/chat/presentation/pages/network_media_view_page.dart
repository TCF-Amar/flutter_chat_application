import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_kare/features/chat/domain/entities/chats_entity.dart';
import 'package:chat_kare/features/shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class NetworkMediaViewPage extends StatefulWidget {
  final String url;
  final MessageType type;

  const NetworkMediaViewPage({
    super.key,
    required this.url,
    required this.type,
  });

  @override
  State<NetworkMediaViewPage> createState() => _NetworkMediaViewPageState();
}

class _NetworkMediaViewPageState extends State<NetworkMediaViewPage> {
  VideoPlayerController? _videoController;
  bool _isPlaying = false;
  bool _isControlVisible = true;

  @override
  void initState() {
    super.initState();
    if (widget.type == MessageType.video) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    await _videoController!.initialize();
    _videoController!.addListener(() {
      if (mounted) {
        setState(() {
          _isPlaying = _videoController!.value.isPlaying;
        });
      }
    });
    setState(() {});
    _videoController!.play();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _isControlVisible = !_isControlVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: widget.type == MessageType.image
            ? _buildImageView()
            : _buildVideoView(),
      ),
    );
  }

  Widget _buildImageView() {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: CachedNetworkImage(
        imageUrl: widget.url,
        fit: BoxFit.contain,
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) =>
            const Center(child: Icon(Icons.error, color: Colors.white)),
      ),
    );
  }

  Widget _buildVideoView() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return const CircularProgressIndicator();
    }

    return GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!,),
          ),
          if (_isControlVisible)
            Container(
              color: Colors.black26,
              child: IconButton(
                iconSize: 64,
                icon: Icon(
                  _isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: Colors.white,
                ),
                onPressed: () {
                  if (_isPlaying) {
                    _videoController!.pause();
                  } else {
                    _videoController!.play();
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
