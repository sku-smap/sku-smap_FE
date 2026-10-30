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

// What the voice screen hands back once a place is settled; a sentence that
// named only the start has no place
class VoiceOutcome {
  const VoiceOutcome({
    required this.place,
    this.origin,
    this.routeOption,
    this.reply,
    this.namesOrigin = false,
    this.namesPlace = true,
  });

  final SearchCandidate? place;

  // Ends the sentence spoke of; only those may change
  final bool namesOrigin;
  final bool namesPlace;
  final SearchCandidate? origin;
  final RouteOption? routeOption;
  final String? reply;
}

class VoiceState {
  const VoiceState({
    this.listening = false,
    this.preparing = false,
    this.busy,
    this.heard,
    this.searchId,
    this.message,
    this.candidates,
    this.result,
    this.error,
  });

  final bool listening;

  // The mic is opening; speech before it is ready would be cut off
  final bool preparing;
  final VoiceBusy? busy;
  final String? heard;
  final int? searchId;
  final String? message;
  final List<SearchCandidate>? candidates;
  final VoiceOutcome? result;
  final String? error;

  String get hint =>
      busy?.label ??
      (preparing
          ? '마이크 준비 중… 잠시 후 말해 주세요'
          : listening
          ? '듣고 있어요… 다 말하면 버튼을 누르세요'
          : heard != null
          ? '이렇게 들었어요'
          : '버튼을 누르고 말해 주세요');
}

// Records or takes a sentence, asks the server, and settles on one place
class VoiceController extends Notifier<VoiceState> {
  VoiceController(this.target);

  static const micDenied = '마이크를 쓸 수 없어요. 설정에서 허용하거나 아래 문장을 눌러 보세요.';

  // Same as the search limit sent to the server
  static const maxCandidates = 5;

  final SearchTarget target;
  Timer? _autoStop;
  var _run = 0;
  Future<SearchResult> Function()? _last;
  String? _lastHeard;
  RouteOption? _routeOption;
  SearchCandidate? _origin;
  var _namesOrigin = false;

  VoiceRecorder get _recorder => ref.read(voiceRecorderProvider);

  // Destination voice asks the route search, which can also find the start
  bool get _destination => target == SearchTarget.destination;

  @override
  VoiceState build() {
    final recorder = _recorder;
    ref.onDispose(() {
      _autoStop?.cancel();
      _run++;
      recorder.cancel();
    });
    Future.microtask(start);
    return const VoiceState(preparing: true);
  }

  // Start recording; stops by itself after 8 seconds
  Future<void> start() async {
    final run = ++_run;
    _autoStop?.cancel();
    state = const VoiceState(preparing: true);
    final allowed = await _recorder.start();
    if (run != _run) return;
    if (!allowed) {
      state = const VoiceState(error: micDenied);
      return;
    }
    // Say "listening" only once audio is actually being captured
    state = const VoiceState(listening: true);
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
      () => _destination
          ? repo.searchRouteVoice(clip)
          : repo.searchVoice(target: target, clip: clip),
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
        return _destination
            ? repo.searchRouteText(text)
            : repo.searchText(target: target, query: text);
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
      _routeOption = r.routeOption;
      _origin = r.origin;
      _namesOrigin = r.namesOrigin;
      // No destination found: settle now so the screen can clear it
      if (_destination && r.candidates.isEmpty) {
        state = VoiceState(
          heard: said,
          result: VoiceOutcome(
            place: null,
            origin: r.origin,
            routeOption: r.routeOption,
            namesOrigin: r.namesOrigin,
            namesPlace: r.namesDestination,
          ),
        );
        return;
      }
      state = VoiceState(
        heard: said,
        searchId: r.searchId,
        // The route search's message also asks for the start, so the
        // destination chips keep their own caption
        message: _destination ? null : r.message,
        // Show only what was asked for even if more come back
        candidates: r.candidates.take(maxCandidates).toList(),
      );
      // One candidate is settled at once; several are offered as chips
      if (r.candidates.length == 1) {
        _settle(
          VoiceOutcome(
            place: r.candidates.single,
            origin: r.origin,
            routeOption: r.routeOption,
            reply: r.message,
            namesOrigin: r.namesOrigin,
          ),
        );
      }
    } on AppException catch (e) {
      if (run != _run) return;
      state = VoiceState(heard: heard, error: e.message);
    }
  }

  Future<void> choose(SearchCandidate place) async => _settle(
    VoiceOutcome(
      place: place,
      origin: _origin,
      routeOption: _routeOption,
      namesOrigin: _namesOrigin,
    ),
  );

  // Hand the pick over at once; the server keeps the selection only as a
  // log, so its call is fire-and-forget and a failure never blocks
  void _settle(VoiceOutcome outcome) {
    final s = state;
    final id = outcome.place!.id;
    if (!(s.candidates ?? []).any((c) => c.id == id)) return;
    state = VoiceState(heard: s.heard, searchId: s.searchId, result: outcome);
    _record(s.searchId, outcome.place);
  }

  void _record(int? searchId, SearchCandidate? place) {
    if (searchId == null || place == null) return;
    ref
        .read(searchRepositoryProvider)
        .select(searchId: searchId, candidateId: place.id)
        .ignore();
  }
}

final voiceControllerProvider = NotifierProvider.autoDispose
    .family<VoiceController, VoiceState, SearchTarget>(VoiceController.new);
