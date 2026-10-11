import 'dart:math';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

import 'storage_service.dart';

class _BytesAudioSource extends StreamAudioSource {
  _BytesAudioSource(this._bytes);
  final Uint8List _bytes;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final s = start ?? 0;
    final e = end ?? _bytes.length;
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: e - s,
      offset: s,
      stream: Stream.value(_bytes.sublist(s, e)),
      contentType: 'audio/wav',
    );
  }
}

/// Synthesizes crisp musical WAV sound effects in-memory so Solo and Duo
/// gameplay have instant audio feedback without needing external MP3 assets.
class SoundService extends GetxService {
  final List<AudioPlayer> _pool = [];
  int _poolIdx = 0;
  final Map<String, Uint8List> _cache = {};

  bool get _enabled {
    if (!Get.isRegistered<StorageService>()) return true;
    return Get.find<StorageService>().soundOn;
  }

  @override
  void onInit() {
    super.onInit();
    for (var i = 0; i < 4; i++) {
      _pool.add(AudioPlayer());
    }
    _prebuildEffects();
  }

  void _prebuildEffects() {
    _cache['tap_0'] = _buildTone([523.25], 0.065, volume: 0.28);
    _cache['tap_1'] = _buildTone([587.33], 0.065, volume: 0.28);
    _cache['tap_2'] = _buildTone([659.25], 0.065, volume: 0.28);
    _cache['tap_3'] = _buildTone([783.99], 0.065, volume: 0.28);
    _cache['tap_4'] = _buildTone([880.00], 0.065, volume: 0.28);
    _cache['correct'] = _buildArpeggio([523.25, 659.25, 783.99, 1046.50], 0.085, volume: 0.42);
    _cache['bonus'] = _buildArpeggio([587.33, 739.99, 880.0, 1174.66], 0.075, volume: 0.38);
    _cache['wrong'] = _buildArpeggio([240.0, 195.0], 0.11, volume: 0.32);
    _cache['tick'] = _buildTone([920.0], 0.045, volume: 0.26);
    _cache['turn'] = _buildArpeggio([440.0, 659.25], 0.09, volume: 0.34);
    _cache['chat'] = _buildArpeggio([659.25, 880.0], 0.06, volume: 0.30);
    _cache['victory'] = _buildArpeggio(
      [523.25, 659.25, 783.99, 1046.50, 1318.51],
      0.11,
      volume: 0.45,
    );
  }

  Future<void> _playKey(String key) async {
    if (!_enabled || _pool.isEmpty) return;
    final bytes = _cache[key];
    if (bytes == null) return;
    final player = _pool[_poolIdx % _pool.length];
    _poolIdx++;
    try {
      await player.setAudioSource(_BytesAudioSource(bytes));
      unawaited(player.play());
    } catch (_) {}
  }

  void playLetterTap([int index = 0]) => _playKey('tap_${index.clamp(0, 4)}');
  void playWordCorrect() => _playKey('correct');
  void playBonusWord() => _playKey('bonus');
  void playWrongWord() => _playKey('wrong');
  void playTimerTick() => _playKey('tick');
  void playTurnSwitch() => _playKey('turn');
  void playChatPop() => _playKey('chat');
  void playVictory() => _playKey('victory');

  Uint8List _buildTone(List<double> freqs, double durationSec, {double volume = 0.35}) {
    const sampleRate = 22050;
    final numSamples = (sampleRate * durationSec).round();
    final pcm = Int16List(numSamples);

    for (var i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final env = sin(pi * (i / numSamples)).clamp(0.0, 1.0);
      var sample = 0.0;
      for (final f in freqs) {
        sample += sin(2 * pi * f * t);
      }
      sample = (sample / freqs.length) * env * volume;
      pcm[i] = (sample * 32767).round().clamp(-32768, 32767);
    }
    return _wrapWav(pcm, sampleRate);
  }

  Uint8List _buildArpeggio(List<double> notes, double noteSec, {double volume = 0.38}) {
    const sampleRate = 22050;
    final perNote = (sampleRate * noteSec).round();
    final total = perNote * notes.length;
    final pcm = Int16List(total);

    for (var n = 0; n < notes.length; n++) {
      final freq = notes[n];
      for (var i = 0; i < perNote; i++) {
        final t = i / sampleRate;
        final env = sin(pi * (i / perNote)).clamp(0.0, 1.0);
        final val = (sin(2 * pi * freq * t) * 0.75 + sin(4 * pi * freq * t) * 0.25) *
            env *
            volume;
        pcm[n * perNote + i] = (val * 32767).round().clamp(-32768, 32767);
      }
    }
    return _wrapWav(pcm, sampleRate);
  }

  Uint8List _wrapWav(Int16List pcm, int sampleRate) {
    final byteCount = pcm.length * 2;
    final header = ByteData(44 + byteCount);
    void writeStr(int offset, String s) {
      for (var i = 0; i < s.length; i++) {
        header.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    writeStr(0, 'RIFF');
    header.setUint32(4, 36 + byteCount, Endian.little);
    writeStr(8, 'WAVE');
    writeStr(12, 'fmt ');
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little); // PCM
    header.setUint16(22, 1, Endian.little); // Mono
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, sampleRate * 2, Endian.little);
    header.setUint16(32, 2, Endian.little);
    header.setUint16(34, 16, Endian.little);
    writeStr(36, 'data');
    header.setUint32(40, byteCount, Endian.little);

    for (var i = 0; i < pcm.length; i++) {
      header.setInt16(44 + i * 2, pcm[i], Endian.little);
    }
    return header.buffer.asUint8List();
  }

  @override
  void onClose() {
    for (final p in _pool) {
      p.dispose();
    }
    super.onClose();
  }
}

void unawaited(Future<void> future) {}
