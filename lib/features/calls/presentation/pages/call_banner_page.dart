import 'dart:async';
import 'package:chat_kare/core/routes/app_router.dart';
import 'package:chat_kare/features/calls/presentation/widgets/calls_widget.dart';
import 'package:flutter/material.dart';

OverlayEntry? overlayEntry;

void showCallBanner(
  BuildContext context, {
  required String name,
  required String? photoUrl,
  required CallType callType,
  CallStatus initialStatus = CallStatus.incoming,
}) {
  if (overlayEntry != null) {
    overlayEntry?.remove();
    overlayEntry = null;
  }

  final overlay = navigatorKey.currentState!.overlay;
  overlayEntry = OverlayEntry(
    builder: (context) {
      return CallOverlayWidget(
        name: name,
        photoUrl: photoUrl,
        callType: callType,
        initialStatus: initialStatus,
        onClose: () {
          overlayEntry?.remove();
          overlayEntry = null;
        },
      );
    },
  );

  overlay!.insert(overlayEntry!);
}

class CallOverlayWidget extends StatefulWidget {
  final String name;
  final String? photoUrl;
  final CallType callType;
  final CallStatus initialStatus;
  final VoidCallback onClose;

  const CallOverlayWidget({
    super.key,
    required this.name,
    required this.photoUrl,
    required this.callType,
    required this.initialStatus,
    required this.onClose,
  });

  @override
  State<CallOverlayWidget> createState() => _CallOverlayWidgetState();
}

class _CallOverlayWidgetState extends State<CallOverlayWidget> {
  late CallStatus _status;
  Timer? _callTimer;
  int _seconds = 0;
  bool _isMuted = false;
  bool _isVideoEnabled = true;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _isVideoEnabled = widget.callType == CallType.video;

    if (_status == CallStatus.outgoing) {
      // Simulate pickup after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _status == CallStatus.outgoing) {
          setState(() {
            _status = CallStatus.connected;
            _startTimer();
          });
        }
      });
    } else if (_status == CallStatus.connected) {
      _startTimer();
    }
  }

  void _startTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  String get _formattedTime {
    final minutes = (_seconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _endCall() {
    _callTimer?.cancel();
    setState(() {
      _status = CallStatus.ended;
    });
    Future.delayed(const Duration(seconds: 2), widget.onClose);
  }

  void _acceptCall() {
    setState(() {
      _status = CallStatus.connected;
      _startTimer();
    });
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CallBackground(photoUrl: widget.photoUrl),

            // Content based on status
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),

                  CallAvatar(name: widget.name, photoUrl: widget.photoUrl),

                  const SizedBox(height: 24),

                  Text(
                    widget.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  CallStatusText(_getStatusText()),

                  if (_status == CallStatus.connected) ...[
                    const SizedBox(height: 8),
                    CallTimer(_formattedTime),
                  ],

                  const Spacer(),

                  CallActionButtons(
                    status: _status,
                    callType: widget.callType,
                    isMuted: _isMuted,
                    isVideoEnabled: _isVideoEnabled,
                    onEnd: _endCall,
                    onAccept: _acceptCall,
                    onToggleMute: () => setState(() => _isMuted = !_isMuted),
                    onToggleVideo: () =>
                        setState(() => _isVideoEnabled = !_isVideoEnabled),
                  ),
                ],
              ),
            ),

            // Close button (top right)
            if (_status == CallStatus.incoming ||
                _status == CallStatus.outgoing)
              Positioned(
                top: 50,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: widget.onClose,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getStatusText() {
    switch (_status) {
      case CallStatus.incoming:
        return widget.callType == CallType.video
            ? 'Incoming Video Call...'
            : 'Incoming Audio Call...';
      case CallStatus.outgoing:
        return 'Calling...';
      case CallStatus.connected:
        return 'Connected';
      case CallStatus.ended:
        return 'Call Ended';
    }
  }
}
