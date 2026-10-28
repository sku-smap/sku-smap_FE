import 'speech_recognizer.dart';

// Stand-in for server speech-to-text; returns a fixed sentence
class MockSpeechRecognizer implements SpeechRecognizer {
  const MockSpeechRecognizer({this.transcript = '학생 어디야'});

  final String? transcript;

  @override
  Future<String?> transcribe() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return transcript;
  }
}
