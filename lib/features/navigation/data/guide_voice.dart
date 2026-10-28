import 'package:flutter_tts/flutter_tts.dart';

abstract class GuideVoice {
  Future<void> speak(String text);
  Future<void> stop();
}

class TtsGuideVoice implements GuideVoice {
  TtsGuideVoice() {
    _tts
      ..setLanguage('ko-KR')
      ..setSpeechRate(0.5);
  }

  final _tts = FlutterTts();

  // Read a step aloud, cutting off the previous one
  @override
  Future<void> speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  @override
  Future<void> stop() => _tts.stop();
}
