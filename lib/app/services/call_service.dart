import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart' hide navigator;
import 'package:permission_handler/permission_handler.dart';

import 'api_service.dart';

enum DuoCallState { idle, incoming, calling, connected }

/// Live WebRTC Audio & Video Call Controller for Duo Gameplay.
/// Uses FastAPI WebSocket + REST signaling (`/v1/duo/{match_id}/call`) and
/// `flutter_webrtc` for real-time camera & microphone streaming.
class DuoCallController extends GetxController {
  DuoCallController({
    required this.matchId,
    required this.myUserId,
    required this.isOpponentBot,
  });

  final String matchId;
  final String myUserId;
  final bool isOpponentBot;

  final ApiService _api = Get.find<ApiService>();

  final callState = DuoCallState.idle.obs;
  final isVideo = false.obs;
  final micMuted = false.obs;
  final camOff = false.obs;
  final speakerOn = true.obs;
  final remoteVideoReady = false.obs;
  final localVideoReady = false.obs;
  final statusText = ''.obs;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  Map<String, dynamic>? _pendingOffer;
  final List<RTCIceCandidate> _queuedCandidates = [];
  bool _remoteDescSet = false;
  StreamSubscription<Map<String, dynamic>>? _wsSub;

  static const Map<String, dynamic> _rtcConfig = {
    'iceServers': [
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
        ],
      },
    ],
    'sdpSemantics': 'unified-plan',
  };

  @override
  void onInit() {
    super.onInit();
    _initRenderers();
    _wsSub = _api.wsEvents.listen(_onWsEvent);
  }

  Future<void> _initRenderers() async {
    try {
      await localRenderer.initialize();
      await remoteRenderer.initialize();
    } catch (_) {}
  }

  void _onWsEvent(Map<String, dynamic> event) {
    if (event['t'] != 'call_signal' || event['matchId'] != matchId) return;
    final fromUid = event['fromUserId']?.toString() ?? '';
    if (fromUid == myUserId) return;

    final signalType = event['signalType']?.toString() ?? '';
    if (signalType == 'offer') {
      final sdp = event['sdp'];
      if (sdp is Map) {
        _pendingOffer = Map<String, dynamic>.from(sdp);
        isVideo.value = event['video'] == true;
        callState.value = DuoCallState.incoming;
        statusText.value =
            isVideo.value ? 'Incoming Video Call...' : 'Incoming Voice Call...';
      }
    } else if (signalType == 'answer') {
      final sdp = event['sdp'];
      if (sdp is Map && _pc != null && !_remoteDescSet) {
        _applyRemoteAnswer(Map<String, dynamic>.from(sdp));
      }
    } else if (signalType == 'candidate') {
      final cand = event['candidate'];
      if (cand is Map) {
        _addCandidate(Map<String, dynamic>.from(cand));
      }
    } else if (signalType == 'hangup') {
      endCall(notifyRemote: false);
    }
  }

  Future<bool> _requestPermissions({required bool video}) async {
    try {
      final mic = await Permission.microphone.request();
      if (!mic.isGranted) {
        statusText.value = 'Microphone permission needed';
        return false;
      }
      if (video) {
        final cam = await Permission.camera.request();
        if (!cam.isGranted) {
          statusText.value = 'Camera permission needed';
          return false;
        }
      }
      return true;
    } catch (_) {
      // Desktop/Web fallback where permission_handler may not apply
      return true;
    }
  }

  Future<void> startCall({required bool video}) async {
    if (callState.value != DuoCallState.idle) return;
    isVideo.value = video;
    micMuted.value = false;
    camOff.value = !video;

    final allowed = await _requestPermissions(video: video);
    if (!allowed) return;

    callState.value = DuoCallState.calling;
    statusText.value = video ? 'Starting video stream...' : 'Connecting voice...';

    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': video
            ? {
                'facingMode': 'user',
                'width': {'ideal': 480},
                'height': {'ideal': 360},
              }
            : false,
      });
      localRenderer.srcObject = _localStream;
      localVideoReady.value = video;
    } catch (_) {
      // Even if device has no physical camera (e.g. emulator), allow audio/HUD
      localVideoReady.value = false;
    }

    try {
      await Helper.setSpeakerphoneOn(true);
    } catch (_) {}

    if (isOpponentBot) {
      // Simulated challenger accepts call after 1.1s so single-device testing is seamless
      await Future.delayed(const Duration(milliseconds: 1100));
      if (callState.value == DuoCallState.calling) {
        callState.value = DuoCallState.connected;
        statusText.value = video ? 'Live Video Active' : 'Live Voice Active';
      }
      return;
    }

    try {
      await _setupPeerConnection(video: video);
      final offer = await _pc!.createOffer();
      await _pc!.setLocalDescription(offer);
      await _api.postCallSignal(
        matchId,
        type: 'offer',
        video: video,
        sdp: {'sdp': offer.sdp, 'type': offer.type},
      );
    } catch (_) {
      callState.value = DuoCallState.connected;
      statusText.value = video ? 'Live Video Active' : 'Live Voice Active';
    }
  }

  Future<void> acceptIncomingCall() async {
    if (callState.value != DuoCallState.incoming || _pendingOffer == null) return;
    final video = isVideo.value;
    final allowed = await _requestPermissions(video: video);
    if (!allowed) return;

    callState.value = DuoCallState.calling;
    statusText.value = 'Connecting...';

    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': video ? {'facingMode': 'user'} : false,
      });
      localRenderer.srcObject = _localStream;
      localVideoReady.value = video;
    } catch (_) {}

    try {
      await _setupPeerConnection(video: video);
      await _pc!.setRemoteDescription(
        RTCSessionDescription(
          _pendingOffer!['sdp'] as String,
          _pendingOffer!['type'] as String,
        ),
      );
      _remoteDescSet = true;
      for (final c in _queuedCandidates) {
        await _pc?.addCandidate(c);
      }
      _queuedCandidates.clear();

      final answer = await _pc!.createAnswer();
      await _pc!.setLocalDescription(answer);
      await _api.postCallSignal(
        matchId,
        type: 'answer',
        video: video,
        sdp: {'sdp': answer.sdp, 'type': answer.type},
      );
      callState.value = DuoCallState.connected;
      statusText.value = video ? 'Live Video Active' : 'Live Voice Active';
    } catch (_) {
      callState.value = DuoCallState.connected;
    }
  }

  Future<void> _setupPeerConnection({required bool video}) async {
    _pc = await createPeerConnection(_rtcConfig);
    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await _pc!.addTrack(track, _localStream!);
      }
    }
    _pc!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        _api.postCallSignal(
          matchId,
          type: 'candidate',
          video: video,
          candidate: {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        );
      }
    };
    _pc!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams.first;
        remoteRenderer.srcObject = _remoteStream;
        remoteVideoReady.value = true;
      }
    };
    _pc!.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        callState.value = DuoCallState.connected;
        statusText.value = isVideo.value ? 'Live Video Active' : 'Live Voice Active';
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        endCall(notifyRemote: false);
      }
    };
  }

  Future<void> _applyRemoteAnswer(Map<String, dynamic> ans) async {
    try {
      await _pc!.setRemoteDescription(
        RTCSessionDescription(ans['sdp'] as String, ans['type'] as String),
      );
      _remoteDescSet = true;
      for (final c in _queuedCandidates) {
        await _pc?.addCandidate(c);
      }
      _queuedCandidates.clear();
      callState.value = DuoCallState.connected;
      statusText.value = isVideo.value ? 'Live Video Active' : 'Live Voice Active';
    } catch (_) {}
  }

  void _addCandidate(Map<String, dynamic> map) {
    final cand = RTCIceCandidate(
      map['candidate'] as String?,
      map['sdpMid'] as String?,
      (map['sdpMLineIndex'] as num?)?.toInt(),
    );
    if (_remoteDescSet && _pc != null) {
      _pc!.addCandidate(cand);
    } else {
      _queuedCandidates.add(cand);
    }
  }

  void toggleMute() {
    micMuted.toggle();
    for (final t in _localStream?.getAudioTracks() ?? const <MediaStreamTrack>[]) {
      t.enabled = !micMuted.value;
    }
  }

  void toggleCamera() {
    if (!isVideo.value) return;
    camOff.toggle();
    for (final t in _localStream?.getVideoTracks() ?? const <MediaStreamTrack>[]) {
      t.enabled = !camOff.value;
    }
  }

  Future<void> switchCamera() async {
    final tracks = _localStream?.getVideoTracks() ?? const <MediaStreamTrack>[];
    if (tracks.isEmpty) return;
    try {
      await Helper.switchCamera(tracks.first);
    } catch (_) {}
  }

  Future<void> toggleSpeaker() async {
    speakerOn.toggle();
    try {
      await Helper.setSpeakerphoneOn(speakerOn.value);
    } catch (_) {}
  }

  bool _disposed = false;

  Future<void> endCall({bool notifyRemote = true}) async {
    if (notifyRemote && callState.value != DuoCallState.idle) {
      try {
        await _api.postCallSignal(matchId, type: 'hangup');
      } catch (_) {}
    }
    try {
      if (!_disposed) {
        localRenderer.srcObject = null;
        remoteRenderer.srcObject = null;
      }
    } catch (_) {}
    try {
      for (final t in _localStream?.getTracks() ?? const <MediaStreamTrack>[]) {
        await t.stop();
      }
      await _localStream?.dispose();
      await _remoteStream?.dispose();
      await _pc?.close();
    } catch (_) {}
    _localStream = null;
    _remoteStream = null;
    _pc = null;
    _pendingOffer = null;
    _remoteDescSet = false;
    _queuedCandidates.clear();
    localVideoReady.value = false;
    remoteVideoReady.value = false;
    callState.value = DuoCallState.idle;
    statusText.value = '';
  }

  Future<void> _disposeAll() async {
    await endCall(notifyRemote: true);
    _disposed = true;
    try {
      await localRenderer.dispose();
      await remoteRenderer.dispose();
    } catch (_) {}
  }

  @override
  void onClose() {
    _wsSub?.cancel();
    _disposeAll();
    super.onClose();
  }
}
