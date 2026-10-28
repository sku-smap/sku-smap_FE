import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

import 'voice_recorder.dart';

// 16 kHz mono PCM wrapped as WAV: 8 s stays far under the 1 MB upload limit
class RecordVoiceRecorder implements VoiceRecorder {
  static const _rate = 16000;

  final _recorder = AudioRecorder();
  final _bytes = BytesBuilder(copy: false);
  StreamSubscription<Uint8List>? _sub;
  DateTime? _startedAt;

  @override
  Future<bool> start() async {
    if (!await _recorder.hasPermission()) return false;
    await cancel();
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _rate,
        numChannels: 1,
      ),
    );
    _startedAt = DateTime.now();
    _sub = stream.listen(_bytes.add);
    return true;
  }

  @override
  Future<VoiceClip?> stop() async {
    final started = _startedAt;
    await _recorder.stop();
    await _sub?.cancel();
    _sub = null;
    _startedAt = null;
    final pcm = _bytes.takeBytes();
    if (started == null || pcm.isEmpty) return null;
    return VoiceClip(
      bytes: wavOf(pcm, sampleRate: _rate),
      duration: DateTime.now().difference(started),
    );
  }

  @override
  Future<void> cancel() async {
    await _sub?.cancel();
    _sub = null;
    _startedAt = null;
    _bytes.clear();
    if (await _recorder.isRecording()) await _recorder.stop();
  }

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    await _recorder.dispose();
  }
}

// 44-byte RIFF header in front of 16-bit mono PCM
Uint8List wavOf(Uint8List pcm, {required int sampleRate}) {
  final header = ByteData(44)
    ..setUint32(0, 0x52494646) // RIFF
    ..setUint32(4, 36 + pcm.length, Endian.little)
    ..setUint32(8, 0x57415645) // WAVE
    ..setUint32(12, 0x666d7420) // fmt
    ..setUint32(16, 16, Endian.little)
    ..setUint16(20, 1, Endian.little)
    ..setUint16(22, 1, Endian.little)
    ..setUint32(24, sampleRate, Endian.little)
    ..setUint32(28, sampleRate * 2, Endian.little)
    ..setUint16(32, 2, Endian.little)
    ..setUint16(34, 16, Endian.little)
    ..setUint32(36, 0x64617461) // data
    ..setUint32(40, pcm.length, Endian.little);
  return (BytesBuilder(copy: false)
        ..add(header.buffer.asUint8List())
        ..add(pcm))
      .takeBytes();
}
