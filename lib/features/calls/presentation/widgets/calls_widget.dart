import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CallBackground extends StatelessWidget {
  final String? photoUrl;

  const CallBackground({super.key, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (photoUrl != null)
          CachedNetworkImage(
            imageUrl: photoUrl!,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) =>
                Container(color: Colors.grey.shade900),
          )
        else
          Container(color: Colors.grey.shade900),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(color: Colors.black.withOpacity(0.6)),
        ),
      ],
    );
  }
}

class CallAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;

  const CallAvatar({super.key, this.photoUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: CircleAvatar(
        radius: 80,
        backgroundColor: Colors.grey.shade800,
        backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
        child: photoUrl == null
            ? Text(
                name.substring(0, 1).toUpperCase(),
                style: const TextStyle(fontSize: 60, color: Colors.white),
              )
            : null,
      ),
    );
  }
}

class CallStatusText extends StatelessWidget {
  final String text;

  const CallStatusText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white70, fontSize: 18),
    );
  }
}

class CallTimer extends StatelessWidget {
  final String time;

  const CallTimer(this.time, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      time,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class CallButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const CallButton({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 35),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class CallControlButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const CallControlButton({
    super.key,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white24,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.black : Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

class CallActionButtons extends StatelessWidget {
  final CallStatus status;
  final CallType callType;
  final bool isMuted;
  final bool isVideoEnabled;
  final VoidCallback onEnd;
  final VoidCallback onAccept;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleVideo;
  final VoidCallback? onSwitchCamera;

  const CallActionButtons({
    super.key,
    required this.status,
    required this.callType,
    required this.onEnd,
    required this.onAccept,
    this.isMuted = false,
    this.isVideoEnabled = true,
    required this.onToggleMute,
    required this.onToggleVideo,
    this.onSwitchCamera,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case CallStatus.incoming:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CallButton(
              icon: Icons.call_end,
              color: Colors.red,
              label: 'Decline',
              onTap: onEnd,
            ),
            CallButton(
              icon: callType == CallType.video ? Icons.videocam : Icons.call,
              color: Colors.green,
              label: 'Accept',
              onTap: onAccept,
            ),
          ],
        );

      case CallStatus.outgoing:
        return Center(
          child: CallButton(
            icon: Icons.call_end,
            color: Colors.red,
            label: 'Cancel',
            onTap: onEnd,
          ),
        );

      case CallStatus.connected:
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CallControlButton(
                  icon: isMuted ? Icons.mic_off : Icons.mic,
                  isActive: isMuted,
                  onTap: onToggleMute,
                ),
                if (callType == CallType.video) ...[
                  CallControlButton(
                    icon: isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                    isActive: !isVideoEnabled,
                    onTap: onToggleVideo,
                  ),
                  CallControlButton(
                    icon: Icons.cameraswitch,
                    isActive: false,
                    onTap: onSwitchCamera ?? () {},
                  ),
                ],
                CallControlButton(
                  icon: Icons.volume_up,
                  isActive: false,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 30),
            CallButton(
              icon: Icons.call_end,
              color: Colors.red,
              label: 'End Call',
              onTap: onEnd,
            ),
          ],
        );

      case CallStatus.ended:
        return const SizedBox.shrink();
    }
  }
}

enum CallType { video, audio }

enum CallStatus { incoming, outgoing, connected, ended }

class CallMainVideoBackground extends StatelessWidget {
  final bool isVideoEnabled;
  final bool isCameraInitialized;
  final CameraController? cameraController;
  final String? photoUrl;

  const CallMainVideoBackground({
    super.key,
    required this.isVideoEnabled,
    required this.isCameraInitialized,
    required this.cameraController,
    required this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (isVideoEnabled && isCameraInitialized && cameraController != null) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: cameraController!.value.previewSize?.height ?? 100,
          height: cameraController!.value.previewSize?.width ?? 100,
          child: CameraPreview(cameraController!),
        ),
      );
    } else {
      return CallBackground(photoUrl: photoUrl);
    }
  }
}

class CallPipVideo extends StatelessWidget {
  final bool isVideoEnabled;
  final bool isCameraInitialized;
  final CameraController? cameraController;

  const CallPipVideo({
    super.key,
    required this.isVideoEnabled,
    required this.isCameraInitialized,
    required this.cameraController,
  });

  @override
  Widget build(BuildContext context) {
    if (isVideoEnabled && isCameraInitialized && cameraController != null) {
      return Positioned(
        top: 40,
        right: 20,
        child: Container(
          width: 100,
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(12),
            color: Colors.black,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CameraPreview(cameraController!),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
