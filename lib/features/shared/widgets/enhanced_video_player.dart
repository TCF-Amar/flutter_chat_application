import 'dart:async';

import 'package:chat_kare/core/theme/theme_extensions.dart';
import 'package:chat_kare/features/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class EnhancedVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;

  const EnhancedVideoPlayer({super.key, required this.controller});

  @override
  State<EnhancedVideoPlayer> createState() => _EnhancedVideoPlayerState();
}

class _EnhancedVideoPlayerState extends State<EnhancedVideoPlayer> {
  bool _showControls = true;
  Timer? _hideTimer;
  final List<double> _playbackSpeeds = [0.25, 0.5, 1.0, 1.5, 2.0, 4.0];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_videoListener);
    _startHideTimer();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_videoListener);
    _hideTimer?.cancel();
    super.dispose();
  }

  void _videoListener() {
    if (mounted) setState(() {});
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && widget.controller.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) _startHideTimer();
  }

  void _togglePlay() {
    if (widget.controller.value.isPlaying) {
      widget.controller.pause();
      _hideTimer?.cancel();
      setState(() => _showControls = true);
    } else {
      widget.controller.play();
      _startHideTimer();
    }
  }

  void _changeSpeed(double speed) {
    widget.controller.setPlaybackSpeed(speed);
    _startHideTimer(); // Reset timer to keep controls visible briefly
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTap: _toggleControls,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: widget.controller.value.aspectRatio,
            child: VideoPlayer(widget.controller),
          ),
          if (_showControls) ...[
            Container(color: Colors.black26),
            // Center Play/Pause Button
            Center(
              child: IconButton(
                iconSize: 64,
                icon: Icon(
                  widget.controller.value.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: Colors.white,
                ),
                onPressed: _togglePlay,
              ),
            ),
            // Bottom Controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black87],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Current Time
                        AppText(
                          _formatDuration(widget.controller.value.position),
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        const SizedBox(width: 8),
                        // Seek Bar
                        Expanded(
                          child: VideoProgressIndicator(
                            widget.controller,
                            allowScrubbing: true,
                            colors: VideoProgressColors(
                              playedColor: context.colorScheme.primary,
                              bufferedColor: Colors.white24,
                              backgroundColor: Colors.white10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Total Duration
                        AppText(
                          _formatDuration(widget.controller.value.duration),
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Speed Control
                        PopupMenuButton<double>(
                          initialValue: widget.controller.value.playbackSpeed,
                          onSelected: _changeSpeed,
                          itemBuilder: (context) => _playbackSpeeds
                              .map(
                                (speed) => PopupMenuItem(
                                  value: speed,
                                  child: Text('${speed}x'),
                                ),
                              )
                              .toList(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.speed,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                AppText(
                                  '${widget.controller.value.playbackSpeed}x',
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
