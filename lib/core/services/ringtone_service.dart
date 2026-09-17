import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';

class RingtoneService {
  static AudioPlayer? _audioPlayer;
  static String? _cachedRingbackWav;
  static bool _isPlaying = false;
  static bool _isOpInProgress = false;
  static bool _vibrating = false;

  static String _generateRingbackWav() {
    if (_cachedRingbackWav != null) return _cachedRingbackWav!;

    const sampleRate = 8000;
    const numChannels = 1;
    const bitsPerSample = 16;
    const durationSeconds = 4.0;
    final numSamples = (sampleRate * durationSeconds).toInt();
    final dataSize = numSamples * numChannels * (bitsPerSample ~/ 8);
    final fileSize = 36 + dataSize;

    final buffer = Uint8List(fileSize + 8);
    final byteData = ByteData.sublistView(buffer);

    buffer.setRange(0, 4, 'RIFF'.codeUnits);
    byteData.setUint32(4, fileSize, Endian.little);
    buffer.setRange(8, 12, 'WAVE'.codeUnits);

    buffer.setRange(12, 16, 'fmt '.codeUnits);
    byteData.setUint32(16, 16, Endian.little);
    byteData.setUint16(20, 1, Endian.little);
    byteData.setUint16(22, numChannels, Endian.little);
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * numChannels * (bitsPerSample ~/ 8), Endian.little);
    byteData.setUint16(32, numChannels * (bitsPerSample ~/ 8), Endian.little);
    byteData.setUint16(34, bitsPerSample, Endian.little);

    buffer.setRange(36, 40, 'data'.codeUnits);
    byteData.setUint32(40, dataSize, Endian.little);

    int offset = 44;
    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      int sampleValue = 0;

      // Ringback pattern: 1.5s tone, 2.5s quiet
      if (t % 4.0 < 1.5) {
        final sample1 = math.sin(2 * math.pi * 440 * t);
        final sample2 = math.sin(2 * math.pi * 480 * t);
        final combined = (sample1 + sample2) / 2.0;
        sampleValue = (combined * 16000).toInt().clamp(-32768, 32767);
      }

      byteData.setInt16(offset, sampleValue, Endian.little);
      offset += 2;
    }

    final base64Str = base64Encode(buffer);
    _cachedRingbackWav = 'data:audio/wav;base64,$base64Str';
    return _cachedRingbackWav!;
  }

  static Future<void> playOutgoingRingback() async {
    await _playRingtone('outgoing');
  }

  static Future<void> playIncomingRingtone() async {
    await _playRingtone('incoming');
  }

  static Future<void> _playRingtone(String type) async {
    if (_isOpInProgress) return;
    _isOpInProgress = true;
    try {
      await stopRingtone();
      _isPlaying = true;
      final player = AudioPlayer();
      _audioPlayer = player;

      try {
        await AudioPlayer.global.setAudioContext(AudioContext(
          android: const AudioContextAndroid(
            audioFocus: AndroidAudioFocus.gainTransient,
            audioMode: AndroidAudioMode.normal,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.notificationRingtone,
            stayAwake: true,
          ),
        ));
      } catch (e) {
        AppLogger.d('AudioContext setup notice: $e');
      }

      if (!_isPlaying || _audioPlayer != player) {
        try {
          await player.stop();
          await player.dispose();
        } catch (_) {}
        return;
      }

      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(1.0);

      if (_isPlaying && _audioPlayer == player) {
        final base64Str = _generateRingbackWav().split(',').last;
        final bytes = base64Decode(base64Str);
        await player.play(BytesSource(bytes));
        AppLogger.d('RingtoneService: Playing $type ringtone');
      }

      if (type == 'incoming' && _isPlaying && _audioPlayer == player) {
        await _startIncomingVibration();
      }

      if (!_isPlaying) {
        await stopRingtone();
      }
    } catch (e) {
      AppLogger.d('RingtoneService play $type error: $e');
      await stopRingtone();
    } finally {
      _isOpInProgress = false;
    }
  }

  /// Rumbles the device in a repeating call-style pattern while the incoming
  /// call rings. Stops automatically when [stopRingtone] is called (accept,
  /// decline, end, or timeout).
  static Future<void> _startIncomingVibration() async {
    if (_vibrating) return;
    try {
      final supported = await Vibration.hasVibrator();
      if (supported && !kIsWeb) {
        _vibrating = true;
        // Vibrate 1s on / 500ms off, repeating indefinitely like a phone call.
        await Vibration.vibrate(
          pattern: <int>[0, 1000, 500, 1000],
          repeat: -1,
        );
      }
    } catch (e) {
      _vibrating = false;
      AppLogger.d('RingtoneService vibration notice: $e');
    }
  }

  static Future<void> stopRingtone() async {
    _isPlaying = false;
    if (_vibrating) {
      _vibrating = false;
      try {
        await Vibration.cancel();
      } catch (e) {
        AppLogger.d('RingtoneService vibration cancel notice: $e');
      }
    }
    final player = _audioPlayer;
    _audioPlayer = null;
    if (player != null) {
      try {
        await player.stop();
      } catch (_) {}
      try {
        await player.dispose();
      } catch (_) {}
    }
  }

  static Future<void> dispose() async {
    await stopRingtone();
  }
}
