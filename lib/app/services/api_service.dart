import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../models/duo_models.dart';
import '../models/puzzle_model.dart';
import '../models/user_model.dart';

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

/// FastAPI + MongoDB Compass / Render Live API client using Bearer Token JWT.
class ApiService extends GetxService {
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  final http.Client _http = http.Client();
  final customBaseUrl = ''.obs;
  final bearerToken = RxnString();
  final isConnected = false.obs;

  WebSocket? _ws;
  Timer? _wsPingTimer;
  Timer? _wsReconnectTimer;
  bool _wsConnecting = false;
  final Set<String> _joinedMatches = {};

  final _wsEvents = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get wsEvents => _wsEvents.stream;

  String _resolvedLocalUrl = 'http://127.0.0.1:8000';

  static const List<String> _localCandidates = [
    'http://127.0.0.1:8000',
    'http://192.168.1.7:8000',
    'http://10.0.2.2:8000',
  ];

  String get baseUrl {
    if (customBaseUrl.value.trim().isNotEmpty) {
      final raw = customBaseUrl.value.trim();
      return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
    }
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl.endsWith('/')
          ? _envBaseUrl.substring(0, _envBaseUrl.length - 1)
          : _envBaseUrl;
    }
    if (kIsWeb) return 'http://localhost:8000';
    return _resolvedLocalUrl;
  }

  String get wsUrl {
    final base = baseUrl;
    if (base.startsWith('https://')) {
      return '${base.replaceFirst('https://', 'wss://')}/v1/ws';
    }
    return '${base.replaceFirst('http://', 'ws://')}/v1/ws';
  }

  void setBearerToken(String? token) {
    bearerToken.value = (token != null && token.trim().isNotEmpty) ? token.trim() : null;
    if (bearerToken.value != null) {
      connectWebSocket();
    } else {
      disconnectWebSocket();
    }
  }

  Map<String, String> _headers({bool auth = true}) {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = bearerToken.value;
    if (auth && token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  Future<http.Response> _sendHttp(
    String base,
    String method,
    String path, {
    Map<String, dynamic>? body,
    required bool auth,
    Duration timeout = const Duration(seconds: 8),
  }) {
    final uri = Uri.parse('$base$path');
    switch (method) {
      case 'GET':
        return _http.get(uri, headers: _headers(auth: auth)).timeout(timeout);
      case 'POST':
        return _http
            .post(uri, headers: _headers(auth: auth), body: jsonEncode(body ?? const {}))
            .timeout(timeout);
      case 'PUT':
        return _http
            .put(uri, headers: _headers(auth: auth), body: jsonEncode(body ?? const {}))
            .timeout(timeout);
      case 'PATCH':
        return _http
            .patch(uri, headers: _headers(auth: auth), body: jsonEncode(body ?? const {}))
            .timeout(timeout);
      default:
        throw ArgumentError('Unsupported HTTP method $method');
    }
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    http.Response? res;
    try {
      res = await _sendHttp(baseUrl, method, path, body: body, auth: auth);
      isConnected.value = true;
    } catch (_) {
      // If using default local server, automatically probe other local candidates (USB, LAN, Emulator)
      if (customBaseUrl.value.trim().isEmpty && _envBaseUrl.isEmpty && !kIsWeb) {
        for (final candidate in _localCandidates) {
          if (candidate == _resolvedLocalUrl) continue;
          try {
            res = await _sendHttp(
              candidate,
              method,
              path,
              body: body,
              auth: auth,
              timeout: const Duration(seconds: 3),
            );
            _resolvedLocalUrl = candidate;
            isConnected.value = true;
            break;
          } catch (_) {}
        }
      }
      if (res == null) {
        isConnected.value = false;
        throw ApiException(
          503,
          'Cannot reach FastAPI server at $baseUrl. Ensure backend is running or configure your Render URL.',
        );
      }
    }

    Map<String, dynamic> decoded = {};
    if (res.body.isNotEmpty) {
      try {
        final raw = jsonDecode(res.body);
        if (raw is Map<String, dynamic>) decoded = raw;
      } catch (_) {}
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded;
    }

    final detail = decoded['detail']?.toString() ??
        decoded['message']?.toString() ??
        'Request failed (${res.statusCode})';
    throw ApiException(res.statusCode, detail);
  }

  // ---------------------------------------------------------------------------
  // 1. Mobile Number OTP + Bearer JWT Auth
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> sendOtp({
    required String phone,
    String countryCode = '+91',
  }) async {
    return _request(
      'POST',
      '/v1/auth/send-otp',
      body: {'phone': phone, 'countryCode': countryCode},
      auth: false,
    );
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
    String? name,
    String? avatar,
  }) async {
    return _request(
      'POST',
      '/v1/auth/verify-otp',
      body: {
        'phone': phone,
        'otp': otp,
        if (name != null && name.isNotEmpty) 'name': name,
        if (avatar != null && avatar.isNotEmpty) 'avatar': avatar,
      },
      auth: false,
    );
  }

  Future<Map<String, dynamic>> fetchMe() async {
    return _request('GET', '/v1/auth/me');
  }

  Future<UserModel> updateProfile({
    String? name,
    String? avatar,
    String? bio,
    String? title,
    bool? haptics,
    bool? soundOn,
    bool? musicOn,
  }) async {
    final res = await _request(
      'PATCH',
      '/v1/auth/profile',
      body: {
        if (name != null) 'name': name,
        if (avatar != null) 'avatar': avatar,
        if (bio != null) 'bio': bio,
        if (title != null) 'title': title,
        if (haptics != null) 'haptics': haptics,
        if (soundOn != null) 'soundOn': soundOn,
        if (musicOn != null) 'musicOn': musicOn,
      },
    );
    return UserModel.fromJson(Map<String, dynamic>.from(res['user'] as Map));
  }

  Future<void> logout() async {
    try {
      await _request('POST', '/v1/auth/logout');
    } catch (_) {}
    setBearerToken(null);
  }

  // ---------------------------------------------------------------------------
  // 2. Dynamic Solo Game State (MongoDB `solo_states`)
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> fetchSoloState() async {
    return _request('GET', '/v1/solo/state');
  }

  Future<Map<String, dynamic>> saveSoloState({
    required int level,
    required int coins,
    required int wordsTotal,
    required int bonusTotal,
    required bool haptics,
    required bool soundOn,
    required bool musicOn,
    required Puzzle? puzzle,
    required Iterable<String> found,
    required Iterable<String> revealed,
    required Iterable<String> bonus,
  }) async {
    return _request(
      'PUT',
      '/v1/solo/state',
      body: {
        'level': level,
        'coins': coins,
        'wordsTotal': wordsTotal,
        'bonusTotal': bonusTotal,
        'haptics': haptics,
        'soundOn': soundOn,
        'musicOn': musicOn,
        if (puzzle != null) 'puzzle': puzzle.toJson(),
        'found': found.toList(),
        'revealed': revealed.toList(),
        'bonus': bonus.toList(),
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Active Users Presence, Leaderboard & History
  // ---------------------------------------------------------------------------
  Future<List<UserModel>> heartbeat({
    bool inGameplay = false,
    String mode = 'lobby',
  }) async {
    final res = await _request(
      'POST',
      '/v1/presence/heartbeat',
      body: {'inGameplay': inGameplay, 'mode': mode},
    );
    final raw = (res['activeUsers'] as List?) ?? const [];
    return raw
        .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<UserModel>> fetchActiveUsers() async {
    final res = await _request('GET', '/v1/presence/active-users');
    final raw = (res['activeUsers'] as List?) ?? const [];
    return raw
        .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<UserModel>> fetchLeaderboard() async {
    final res = await _request('GET', '/v1/leaderboard');
    final raw = (res['leaderboard'] as List?) ?? const [];
    return raw
        .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<DuoMatchModel>> fetchDuoHistory() async {
    final res = await _request('GET', '/v1/duo/history');
    final raw = (res['matches'] as List?) ?? const [];
    return raw
        .map((e) => DuoMatchModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // 4. Duo Matchmaking, 30s Turn Moves, Chat & WebRTC Signaling
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> autoMatch({bool instantBotFallback = false}) async {
    return _request(
      'POST',
      '/v1/duo/auto-match',
      body: {'instantBotFallback': instantBotFallback},
    );
  }

  Future<void> cancelQueue() async {
    try {
      await _request('POST', '/v1/duo/cancel-queue');
    } catch (_) {}
  }

  Future<DuoMatchModel> fetchDuoMatch(String matchId) async {
    final res = await _request('GET', '/v1/duo/$matchId');
    return DuoMatchModel.fromJson(Map<String, dynamic>.from(res['match'] as Map));
  }

  Future<Map<String, dynamic>> submitDuoMove(String matchId, String word) async {
    return _request('POST', '/v1/duo/$matchId/move', body: {'word': word});
  }

  Future<DuoMatchModel> passDuoTurn(String matchId) async {
    final res = await _request('POST', '/v1/duo/$matchId/pass-turn');
    return DuoMatchModel.fromJson(Map<String, dynamic>.from(res['match'] as Map));
  }

  Future<DuoMatchModel> forfeitDuoMatch(String matchId) async {
    final res = await _request('POST', '/v1/duo/$matchId/forfeit');
    return DuoMatchModel.fromJson(Map<String, dynamic>.from(res['match'] as Map));
  }

  Future<List<ChatMessageModel>> fetchMatchChat(String matchId) async {
    final res = await _request('GET', '/v1/duo/$matchId/chat');
    final raw = (res['messages'] as List?) ?? const [];
    return raw
        .map((e) => ChatMessageModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<ChatMessageModel> sendMatchChat(
    String matchId,
    String text, {
    bool isQuick = false,
  }) async {
    final res = await _request(
      'POST',
      '/v1/duo/$matchId/chat',
      body: {'text': text, 'isQuick': isQuick},
    );
    return ChatMessageModel.fromJson(
      Map<String, dynamic>.from(res['message'] as Map),
    );
  }

  Future<Map<String, dynamic>> getCallSignal(String matchId) async {
    return _request('GET', '/v1/duo/$matchId/call');
  }

  Future<Map<String, dynamic>> postCallSignal(
    String matchId, {
    required String type,
    bool video = false,
    Map<String, dynamic>? sdp,
    Map<String, dynamic>? candidate,
    bool? micMuted,
    bool? camOff,
  }) async {
    return _request(
      'POST',
      '/v1/duo/$matchId/call',
      body: {
        'type': type,
        'video': video,
        if (sdp != null) 'sdp': sdp,
        if (candidate != null) 'candidate': candidate,
        if (micMuted != null) 'micMuted': micMuted,
        if (camOff != null) 'camOff': camOff,
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Real-time WebSocket Connection
  // ---------------------------------------------------------------------------
  Future<void> connectWebSocket() async {
    final token = bearerToken.value;
    if (token == null || token.isEmpty) return;
    if (_wsConnecting || (_ws != null && _ws!.readyState == WebSocket.open)) {
      return;
    }
    _wsConnecting = true;
    try {
      final url = '$wsUrl?token=${Uri.encodeQueryComponent(token)}';
      final socket = await WebSocket.connect(url).timeout(
        const Duration(seconds: 6),
      );
      _ws = socket;
      isConnected.value = true;
      socket.listen(
        (raw) {
          if (raw is String) {
            try {
              final map = jsonDecode(raw);
              if (map is Map<String, dynamic>) {
                _wsEvents.add(map);
              }
            } catch (_) {}
          }
        },
        onDone: _handleWsDisconnect,
        onError: (_) => _handleWsDisconnect(),
        cancelOnError: true,
      );

      for (final mid in _joinedMatches) {
        sendWs({'t': 'join_match', 'matchId': mid});
      }

      _wsPingTimer?.cancel();
      _wsPingTimer = Timer.periodic(const Duration(seconds: 18), (_) {
        sendWs({'t': 'ping'});
      });
    } catch (_) {
      _handleWsDisconnect();
    } finally {
      _wsConnecting = false;
    }
  }

  void _handleWsDisconnect() {
    _wsPingTimer?.cancel();
    _ws = null;
    if (bearerToken.value != null && bearerToken.value!.isNotEmpty) {
      _wsReconnectTimer?.cancel();
      _wsReconnectTimer = Timer(const Duration(seconds: 3), connectWebSocket);
    }
  }

  void disconnectWebSocket() {
    _wsPingTimer?.cancel();
    _wsReconnectTimer?.cancel();
    _joinedMatches.clear();
    try {
      _ws?.close();
    } catch (_) {}
    _ws = null;
  }

  void joinMatchChannel(String matchId) {
    _joinedMatches.add(matchId);
    sendWs({'t': 'join_match', 'matchId': matchId});
  }

  void leaveMatchChannel(String matchId) {
    _joinedMatches.remove(matchId);
    sendWs({'t': 'leave_match', 'matchId': matchId});
  }

  void sendWs(Map<String, dynamic> msg) {
    if (_ws != null && _ws!.readyState == WebSocket.open) {
      try {
        _ws!.add(jsonEncode(msg));
      } catch (_) {}
    } else {
      connectWebSocket();
    }
  }

  @override
  void onClose() {
    disconnectWebSocket();
    _wsEvents.close();
    super.onClose();
  }
}
