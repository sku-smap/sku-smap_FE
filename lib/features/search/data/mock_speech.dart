class MockSpeechRecognizer {
  const MockSpeechRecognizer({this.transcript = '학생 어디야'});

  static const maxListen = Duration(seconds: 8);

  final String? transcript;

  // Stand-in for server speech-to-text after recording stops
  Future<String?> transcribe() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return transcript;
  }
}
