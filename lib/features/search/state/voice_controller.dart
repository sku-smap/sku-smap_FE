import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_exception.dart';
import '../../campus/data/campus_models.dart';
import '../data/search_models.dart';
import '../data/voice_recorder.dart';
import 'search_flow_controller.dart';

enum VoiceBusy {
  hearing('알아듣는 중…'),
  finding('찾는 중…');

  const VoiceBusy(this.label);

  final String label;
}

// What the voice screen hands back once a place is settled
class VoiceOutcome {
  const VoiceOutcome({
    required this.place,
    this.origin,
    this.routeOption,
    this.reply,
  });

  final SearchCandidate place;
  final SearchCandidate? origin;
  final RouteOption? routeOption;
  final String? reply;
}

class VoiceState {
  const VoiceState({
    this.listening = false,
    this.busy,
    this.heard,
    this.searchId,
    this.message,
    this.candidates,
    this.result,
    this.error,
  });

  final bool listening;
  final VoiceBusy? busy;
  final String? heard;
  final int? searchId;
  final String? message;
  final List<SearchCandidate>? candidates;
  final VoiceOutcome? result;
  final String? error;

  String get hint =>
      busy?.label ??
      (listening
          ? '듣고 있어요… 다 말하면 버튼을 누르세요'
          : heard != null
          ? '이렇게 들었어요'
          : '버튼을 누르고 말해 주세요');
}

// Records or takes a sentence, asks the server, and settles on one place
class VoiceController extends Notifier<VoiceState> {
  VoiceController(this.target);

  static const micDenied = '마이크를 쓸 수 없어요. 설정에서 허용하거나 아래 문장을 눌러 보세요.';

  final SearchTarget target;
  Timer? _autoStop;
  var _run = 0;
  Future<SearchResult> Function()? _last;
  String? _lastHeard;
  RouteOption? _routeOption;

  VoiceRecorder get _recorder => ref.read(voiceRecorderProvider);

  @override
  VoiceState build() {
    final recorder = _recorder;
    ref.onDispose(() {
      _autoStop?.cancel();
      _run++;
      recorder.cancel();
    });
    Future.microtask(start);
    return const VoiceState(listening: true);
  }

  // Start recording; stops by itself after 8 seconds
  Future<void> start() async {
    final run = ++_run;
    _autoStop?.cancel();
    state = const VoiceState(listening: true);
    final allowed = await _recorder.start();
    if (run != _run) return;
    if (!allowed) {
      state = const VoiceState(error: micDenied);
      return;
    }
    _autoStop = Timer(VoiceRecorder.maxListen, stop);
  }

  // Stop recording and send it for speech-to-text and search
  Future<void> stop() async {
    if (!state.listening) return;
    _autoStop?.cancel();
    final run = ++_run;
    state = const VoiceState(busy: VoiceBusy.hearing);
    final clip = await _recorder.stop();
    if (run != _run) return;
    if (clip == null) {
      state = const VoiceState(candidates: []);
      return;
    }
    final repo = ref.read(searchRepositoryProvider);
    await _ask(
      () => repo.searchVoice(target: target, clip: clip),
      busy: VoiceBusy.hearing,
    );
  }

  // A typed or example sentence goes to the text search
  Future<void> handle(String text) async {
    if (state.busy != null) return;
    _autoStop?.cancel();
    final recorder = _recorder;
    final repo = ref.read(searchRepositoryProvider);
    await _ask(
      () async {
        await recorder.cancel();
        return repo.searchText(target: target, query: text);
      },
      busy: VoiceBusy.finding,
      heard: text,
    );
  }

  Future<void> retry() async {
    final last = _last;
    if (last == null || state.busy != null) return;
    await _ask(
      last,
      busy: _lastHeard == null ? VoiceBusy.hearing : VoiceBusy.finding,
      heard: _lastHeard,
    );
  }

  // Shows busy before any await so a second tap is refused; only the
  // newest request may update the screen
  Future<void> _ask(
    Future<SearchResult> Function() request, {
    required VoiceBusy busy,
    String? heard,
  }) async {
    final run = ++_run;
    _last = request;
    _lastHeard = heard;
    state = VoiceState(heard: heard, busy: busy);
    try {
      final r = await request();
      if (run != _run) return;
      final said = r.transcript ?? heard;
      // One candidate is settled at once; several are offered as chips
      state = r.candidates.length == 1
          ? VoiceState(
              heard: said,
              searchId: r.searchId,
              result: VoiceOutcome(
                place: r.candidates.single,
                origin: r.origin,
                routeOption: r.routeOption,
                reply: r.message,
              ),
            )
          : VoiceState(
              heard: said,
              searchId: r.searchId,
              message: r.message,
              candidates: r.candidates,
            );
      _routeOption = r.routeOption;
    } on AppException catch (e) {
      if (run != _run) return;
      state = VoiceState(heard: heard, error: e.message);
    }
  }

  void choose(SearchCandidate place) => state = VoiceState(
    heard: state.heard,
    searchId: state.searchId,
    result: VoiceOutcome(place: place, routeOption: _routeOption),
  );
}

final voiceControllerProvider = NotifierProvider.autoDispose
    .family<VoiceController, VoiceState, SearchTarget>(VoiceController.new);
