import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

class RingtoneService {
  static AudioPlayer? _audioPlayer;
  static String? _cachedIncomingWav;
  static String? _cachedRingbackWav;

  static String _generateIncomingWav() {
    if (_cachedIncomingWav != null) return _cachedIncomingWav!;

    const sampleRate = 8000;
    const numChannels = 1;
    const bitsPerSample = 16;
    const durationSeconds = 1.5;
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

      if (t % 1.5 < 1.0) {
        final sample1 = math.sin(2 * math.pi * 440 * t);
        final sample2 = math.sin(2 * math.pi * 480 * t);
        final combined = (sample1 + sample2) / 2.0;
        sampleValue = (combined * 22000).toInt().clamp(-32768, 32767);
      }

      byteData.setInt16(offset, sampleValue, Endian.little);
      offset += 2;
    }

    final base64Str = base64Encode(buffer);
    _cachedIncomingWav = 'data:audio/wav;base64,$base64Str';
    return _cachedIncomingWav!;
  }

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

  static void unlockAudio() {}

  static Future<void> playIncomingRingtone() async {
    try {
      await stopRingtone();
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer!.setVolume(1.0);
      await _audioPlayer!.play(UrlSource(_generateIncomingWav()));
      debugPrint('RingtoneService: Playing incoming call ringtone');
    } catch (e) {
      debugPrint('Incoming ringtone error: $e');
    }
  }

  static Future<void> playOutgoingRingback() async {
    try {
      await stopRingtone();
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer!.setVolume(0.8);
      await _audioPlayer!.play(UrlSource(_generateRingbackWav()));
      debugPrint('RingtoneService: Playing outgoing ringback tone');
    } catch (e) {
      debugPrint('Outgoing ringback error: $e');
    }
  }

  static Future<void> stopRingtone() async {
    try {
      await _audioPlayer?.stop();
      await _audioPlayer?.dispose();
      _audioPlayer = null;
    } catch (_) {}
  }
}
