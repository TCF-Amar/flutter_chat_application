import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class CallController extends ChangeNotifier {

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  bool isCallConnected = false;

  // ---------------- INIT ----------------
  Future<void> init() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
    await _createPeerConnection();
    await _getUserMedia();
  }

  // ---------------- GET MEDIA ----------------
  Future<void> _getUserMedia() async {
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': true,
    });

    localRenderer.srcObject = _localStream;

    _localStream!.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });
  }

  // ---------------- PEER ----------------
  Future<void> _createPeerConnection() async {
    _peerConnection = await createPeerConnection({
      "iceServers": [
        {"urls": "stun:stun.l.google.com:19302"}
      ]
    });

    _peerConnection?.onTrack = (event) {
      remoteRenderer.srcObject = event.streams[0];
      isCallConnected = true;
      notifyListeners();
    };
  }

  // ---------------- CREATE OFFER ----------------
  Future<RTCSessionDescription> createOffer() async {
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    return offer;
  }

  // ---------------- SET REMOTE ----------------
  Future<void> setRemoteDescription(RTCSessionDescription desc) async {
    await _peerConnection!.setRemoteDescription(desc);
  }

  // ---------------- END CALL ----------------
  Future<void> endCall() async {
    await _localStream?.dispose();
    await _peerConnection?.close();
    await localRenderer.dispose();
    await remoteRenderer.dispose();
  }
}
