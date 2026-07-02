import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Singleton audio + haptic service.
/// Win/fail use real asset files; all other sounds are synthesized procedurally.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  bool soundEnabled = true;
  bool hapticsEnabled = true;

  bool _initialized = false;

  // Pool of AudioPlayer instances for concurrent low-latency playback.
  static const int _poolSize = 5;
  final List<AudioPlayer> _pool = [];
  int _poolIdx = 0;

  // Dedicated players for asset-based sounds (win / fail).
  final AudioPlayer _winPlayer = AudioPlayer();
  final AudioPlayer _failPlayer = AudioPlayer();

  // Pre-generated WAV byte buffers (procedural sounds only).
  late Uint8List _moveSound;
  late Uint8List _drawSound;
  late Uint8List _flipSound;
  late Uint8List _slideSound;
  late Uint8List _successSound;

  /// Call once at app startup (e.g. in [main]) before using any sound method.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Create player pool.
    for (int i = 0; i < _poolSize; i++) {
      final p = AudioPlayer();
      await p.setReleaseMode(ReleaseMode.stop);
      _pool.add(p);
    }

    // Pre-generate procedural sounds.
    _moveSound = _beep(freq: 460, ms: 90, amp: 0.22);
    _flipSound = _beep(freq: 620, ms: 100, amp: 0.20);
    _slideSound = _beep(freq: 340, ms: 70, amp: 0.18);
    _drawSound = _chord([440, 494, 523], ms: 220, amp: 0.22);
    _successSound = _arpeggio([523, 659, 784], noteMs: 110, amp: 0.28);

    // Pre-configure asset players.
    await _winPlayer.setReleaseMode(ReleaseMode.stop);
    await _failPlayer.setReleaseMode(ReleaseMode.stop);
  }

  // Public API

  Future<void> buttonTap() async {
    _haptic(_HapticType.light);
  }

  Future<void> gameMove() async {
    _haptic(_HapticType.medium);
    await _play(_moveSound);
  }

  Future<void> win() async {
    _haptic(_HapticType.heavy);
    await _playAsset(_winPlayer, 'audio/win.mp3');
  }

  Future<void> lose() async {
    _haptic(_HapticType.medium);
    await _playAsset(_failPlayer, 'audio/fail.mp3');
  }

  Future<void> draw() async {
    _haptic(_HapticType.selection);
    await _play(_drawSound);
  }

  Future<void> cardFlip() async {
    _haptic(_HapticType.light);
    await _play(_flipSound);
  }

  Future<void> tileSlide() async {
    _haptic(_HapticType.light);
    await _play(_slideSound);
  }

  Future<void> mineExplode() async {
    _haptic(_HapticType.heavy);
    // Play fail sound for mine hits — it fits a loss event.
    await _playAsset(_failPlayer, 'audio/fail.mp3');
  }

  Future<void> wordFound() async {
    _haptic(_HapticType.medium);
    await _play(_successSound);
  }

  // Internal playback

  Future<void> _play(Uint8List data) async {
    if (!soundEnabled || !_initialized) return;
    try {
      final player = _pool[_poolIdx % _poolSize];
      _poolIdx++;
      await player.stop();
      await player.play(BytesSource(data));
    } catch (_) {
      // Silently swallow audio errors so they never crash the game.
    }
  }

  Future<void> _playAsset(AudioPlayer player, String assetPath) async {
    if (!soundEnabled || !_initialized) return;
    try {
      await player.stop();
      await player.play(AssetSource(assetPath));
    } catch (_) {
      // Silently swallow audio errors.
    }
  }

  void _haptic(_HapticType type) {
    if (!hapticsEnabled) return;
    switch (type) {
      case _HapticType.light:
        HapticFeedback.lightImpact();
      case _HapticType.medium:
        HapticFeedback.mediumImpact();
      case _HapticType.heavy:
        HapticFeedback.heavyImpact();
      case _HapticType.selection:
        HapticFeedback.selectionClick();
    }
  }

  // WAV synthesis helpers

  static const int _sampleRate = 44100;

  Uint8List _beep({required int freq, required int ms, required double amp}) {
    final numSamples = (_sampleRate * ms / 1000).round();
    final samples = List<int>.generate(numSamples, (i) {
      final t = i / _sampleRate;
      final env = math.exp(-4.0 * i / numSamples);
      final v = math.sin(2 * math.pi * freq * t) * amp * env;
      return (v * 32767).round().clamp(-32768, 32767);
    });
    return _buildWav(samples);
  }

  Uint8List _chord(List<int> freqs, {required int ms, required double amp}) {
    final numSamples = (_sampleRate * ms / 1000).round();
    final perFreq = amp / freqs.length;
    final samples = List<int>.generate(numSamples, (i) {
      final t = i / _sampleRate;
      final env = math.exp(-3.5 * i / numSamples);
      double v = 0;
      for (final f in freqs) {
        v += math.sin(2 * math.pi * f * t) * perFreq;
      }
      return (v * env * 32767).round().clamp(-32768, 32767);
    });
    return _buildWav(samples);
  }

  Uint8List _arpeggio(
    List<int> freqs, {
    required int noteMs,
    required double amp,
    bool descend = false,
  }) {
    final ordered = descend ? freqs.reversed.toList() : freqs;
    final samplesPerNote = (_sampleRate * noteMs / 1000).round();
    final allSamples = <int>[];
    for (final freq in ordered) {
      for (int i = 0; i < samplesPerNote; i++) {
        final t = i / _sampleRate;
        final env = math.exp(-3.0 * i / samplesPerNote);
        final v = math.sin(2 * math.pi * freq * t) * amp * env;
        allSamples.add((v * 32767).round().clamp(-32768, 32767));
      }
    }
    return _buildWav(allSamples);
  }

  Uint8List _noise({required int ms, required double amp}) {
    final rng = math.Random();
    final numSamples = (_sampleRate * ms / 1000).round();
    final samples = List<int>.generate(numSamples, (i) {
      final env = math.exp(-5.0 * i / numSamples);
      final v = (rng.nextDouble() * 2 - 1) * amp * env;
      return (v * 32767).round().clamp(-32768, 32767);
    });
    return _buildWav(samples);
  }

  Uint8List _buildWav(List<int> samples) {
    final dataSize = samples.length * 2;
    final buffer = ByteData(44 + dataSize);

    void setChars(int offset, String chars) {
      for (int i = 0; i < chars.length; i++) {
        buffer.setUint8(offset + i, chars.codeUnitAt(i));
      }
    }

    setChars(0, 'RIFF');
    buffer.setUint32(4, 36 + dataSize, Endian.little);
    setChars(8, 'WAVE');
    setChars(12, 'fmt ');
    buffer.setUint32(16, 16, Endian.little);
    buffer.setUint16(20, 1, Endian.little);
    buffer.setUint16(22, 1, Endian.little);
    buffer.setUint32(24, _sampleRate, Endian.little);
    buffer.setUint32(28, _sampleRate * 2, Endian.little);
    buffer.setUint16(32, 2, Endian.little);
    buffer.setUint16(34, 16, Endian.little);
    setChars(36, 'data');
    buffer.setUint32(40, dataSize, Endian.little);

    for (int i = 0; i < samples.length; i++) {
      buffer.setInt16(44 + i * 2, samples[i], Endian.little);
    }

    return buffer.buffer.asUint8List();
  }
}

enum _HapticType { light, medium, heavy, selection }
