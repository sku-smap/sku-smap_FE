import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../campus/data/campus_models.dart';
import '../data/place_search.dart';
import '../data/search_models.dart';
import '../data/speech_recognizer.dart';
import 'search_flow_controller.dart';

enum VoiceBusy {
  hearing('알아듣는 중…'),
  finding('찾는 중…');

  const VoiceBusy(this.label);

  final String label;
}

class VoiceState {
  const VoiceState({
    this.listening = false,
    this.busy,
    this.heard,
    this.candidates,
    this.result,
  });

  final bool listening;
  final VoiceBusy? busy;
  final String? heard;
  final List<SearchPlace>? candidates;
  final VoiceIntent? result;

  String get hint =>
      busy?.label ??
      (listening
          ? '듣고 있어요… 다 말하면 버튼을 누르세요'
          : heard != null
          ? '이렇게 들었어요'
          : '버튼을 누르고 말해 주세요');
}

class VoiceController extends Notifier<VoiceState> {
  static const parseDelay = Duration(milliseconds: 600);

  Timer? _autoStop;
  var _run = 0;

  @override
  VoiceState build() {
    ref.onDispose(() {
      _autoStop?.cancel();
      _run++;
    });
    _autoStop = Timer(SpeechRecognizer.maxListen, stop);
    return const VoiceState(listening: true);
  }

  // Start recording; stops by itself after 8 seconds
  void start() {
    _run++;
    _autoStop?.cancel();
    _autoStop = Timer(SpeechRecognizer.maxListen, stop);
    state = const VoiceState(listening: true);
  }

  // Stop recording and send it to speech-to-text
  Future<void> stop() async {
    if (!state.listening) return;
    _autoStop?.cancel();
    final run = ++_run;
    state = const VoiceState(busy: VoiceBusy.hearing);
    final text = await ref.read(speechRecognizerProvider).transcribe();
    if (run != _run) return;
    if (text == null) {
      state = const VoiceState(candidates: []);
    } else {
      await handle(text);
    }
  }

  // Find the destination in a sentence, or offer close matches
  Future<void> handle(String text) async {
    _autoStop?.cancel();
    final run = ++_run;
    state = VoiceState(heard: text, busy: VoiceBusy.finding);
    await Future<void>.delayed(parseDelay);
    if (run != _run) return;
    final intent = parseUtterance(text);
    state = intent.to != null
        ? VoiceState(heard: text, result: intent)
        : VoiceState(heard: text, candidates: intent.candidates);
  }

  void choose(SearchPlace place) => state = VoiceState(
    heard: state.heard,
    result: VoiceIntent(to: place),
  );
}

final voiceControllerProvider =
    NotifierProvider.autoDispose<VoiceController, VoiceState>(
      VoiceController.new,
    );
