import 'dart:async';
import 'package:camera/camera.dart';
import 'package:chat_kare/core/routes/app_router.dart';
import 'package:chat_kare/features/calls/presentation/widgets/calls_widget.dart';
import 'package:flutter/material.dart';

OverlayEntry? overlayEntry;

/// Global list of cameras, initialized once to avoid repeated calls
List<CameraDescription>? _availableCameras;

Future<void> _ensureCamerasInitialized() async {
  if (_availableCameras == null) {
    try {
      _availableCameras = await availableCameras();
    } catch (e) {
      debugPrint('Error initializing cameras: $e');
      _availableCameras = [];
    }
  }
}

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

  // Controllers for "Fake" Dual Camera setup
  CameraController? _backCameraController;
  CameraController? _frontCameraController;
  bool _isBackCameraInitialized = false;
  bool _isFrontCameraInitialized = false;
  bool _isSwapped =
      false; // Track if cameras are swapped (Front=Main, Back=PIP)

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _isVideoEnabled = widget.callType == CallType.video;

    _initializeCameras();

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

  Future<void> _initializeCameras() async {
    await _ensureCamerasInitialized();
    if (_availableCameras == null || _availableCameras!.isEmpty) return;

    // Try to find back and front cameras
    CameraDescription? backCamera;
    CameraDescription? frontCamera;

    for (var camera in _availableCameras!) {
      if (camera.lensDirection == CameraLensDirection.back &&
          backCamera == null) {
        backCamera = camera;
      } else if (camera.lensDirection == CameraLensDirection.front &&
          frontCamera == null) {
        frontCamera = camera;
      }
    }

    // Initialize Back Camera (for "Remote" view simulation)
    if (backCamera != null) {
      _backCameraController = CameraController(
        backCamera,
        ResolutionPreset.ultraHigh,
        enableAudio: false,
      );
      try {
        await _backCameraController!.initialize();
        if (mounted) {
          setState(() {
            _isBackCameraInitialized = true;
          });
        }
      } catch (e) {
        debugPrint('Error initializing back camera: $e');
      }
    }

    // Initialize Front Camera (for "Local" view)
    // Note: Many devices do NOT support two active cameras.
    // This is a "best effort" for testing.
    if (frontCamera != null) {
      _frontCameraController = CameraController(
        frontCamera,
        ResolutionPreset.ultraHigh,
        enableAudio: false,
      );
      try {
        await _frontCameraController!.initialize();
        if (mounted) {
          setState(() {
            _isFrontCameraInitialized = true;
          });
        }
      } catch (e) {
        debugPrint(
          'Error initializing front camera (likely dual-cam not supported): $e',
        );
        // If front fails (likely due to back taking resource), we keep back as remote
      }
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

  void _toggleCameraSwap() {
    setState(() {
      _isSwapped = !_isSwapped;
    });
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _backCameraController?.dispose();
    _frontCameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine which camera is Main and which is PIP based on swap state
    final mainCameraController = _isSwapped
        ? _frontCameraController
        : _backCameraController;
    final isMainInitialized = _isSwapped
        ? _isFrontCameraInitialized
        : _isBackCameraInitialized;

    final pipCameraController = _isSwapped
        ? _backCameraController
        : _frontCameraController;
    final isPipInitialized = _isSwapped
        ? _isBackCameraInitialized
        : _isFrontCameraInitialized;

    return Positioned.fill(
      child: Material(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Layer:
            // If video enabled & main camera works -> Show Main Camera
            // (Show for Connected, Incoming, Outgoing to provide self-view/preview)
            // Else -> Show Static Photo
            CallMainVideoBackground(
              isVideoEnabled:
                  _isVideoEnabled &&
                  (_status == CallStatus.connected ||
                      _status == CallStatus.incoming ||
                      _status == CallStatus.outgoing),
              isCameraInitialized: isMainInitialized,
              cameraController: mainCameraController,
              photoUrl: widget.photoUrl,
            ),

            // Content based on status
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Avatar only if not showing video background
                    if (!(_status == CallStatus.connected &&
                        _isVideoEnabled &&
                        isMainInitialized)) ...[
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
                        textAlign: TextAlign.center,
                      ),
                    ],

                    if (_status == CallStatus.connected &&
                        _isVideoEnabled &&
                        isMainInitialized)
                      const Spacer(), // Push content when showing video

                    if (!(_status == CallStatus.connected &&
                        _isVideoEnabled &&
                        isMainInitialized))
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
                      onSwitchCamera: _toggleCameraSwap,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Local User Preview (PIP)
            // Show only if connected, video enabled, and PIP camera initialized
            CallPipVideo(
              isVideoEnabled:
                  _status == CallStatus.connected && _isVideoEnabled,
              isCameraInitialized: isPipInitialized,
              cameraController: pipCameraController,
            ),

            // Close button (top right) - adjusted if PIP is present or not
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
