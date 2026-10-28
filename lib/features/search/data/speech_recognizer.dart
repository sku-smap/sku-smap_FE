// Server speech-to-text for a recorded question
abstract interface class SpeechRecognizer {
  static const maxListen = Duration(seconds: 8);

  Future<String?> transcribe();
}
