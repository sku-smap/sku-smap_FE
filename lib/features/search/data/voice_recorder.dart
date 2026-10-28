import 'dart:typed_data';

// A recorded question ready to upload
class VoiceClip {
  const VoiceClip({required this.bytes, required this.duration});

  final Uint8List bytes;
  final Duration duration;
}

// Microphone recording for voice search
abstract interface class VoiceRecorder {
  // Stops by itself after this long (S-17)
  static const maxListen = Duration(seconds: 8);

  // False when microphone access is refused
  Future<bool> start();

  // Null when nothing was recorded
  Future<VoiceClip?> stop();

  Future<void> cancel();

  Future<void> dispose();
}
