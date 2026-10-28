import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/state/home_entry_provider.dart';
import '../data/mock_location.dart';
import '../data/mock_speech.dart';
import '../data/search_models.dart';

typedef SearchEntry = ({PickTarget target, bool voice, String? intro});

class SearchFlowState {
  const SearchFlowState({required this.target, this.voice = false, this.toast});

  final PickTarget target;
  final bool voice;
  final String? toast;

  SearchFlowState copyWith({
    PickTarget? target,
    bool? voice,
    String? Function()? toast,
  }) {
    return SearchFlowState(
      target: target ?? this.target,
      voice: voice ?? this.voice,
      toast: toast != null ? toast() : this.toast,
    );
  }
}

class SearchFlowController extends Notifier<SearchFlowState> {
  SearchFlowController(this.entry);

  static const toastDuration = Duration(milliseconds: 3200);

  final SearchEntry entry;
  Timer? _toastTimer;

  @override
  SearchFlowState build() {
    ref.onDispose(() => _toastTimer?.cancel());
    final intro = entry.intro;
    if (intro != null) _scheduleHide();
    return SearchFlowState(
      target: entry.target,
      voice: entry.voice,
      toast: intro,
    );
  }

  void pick(PickTarget target) =>
      state = state.copyWith(target: target, voice: false);

  void openVoice() => state = state.copyWith(voice: true);

  // Show a short notice that hides itself
  void toast(String message) {
    state = state.copyWith(toast: () => message);
    _scheduleHide();
  }

  void _scheduleHide() {
    _toastTimer?.cancel();
    _toastTimer = Timer(toastDuration, () {
      state = state.copyWith(toast: () => null);
    });
  }
}

final searchFlowProvider = NotifierProvider.autoDispose
    .family<SearchFlowController, SearchFlowState, SearchEntry>(
      SearchFlowController.new,
    );

// Mock GPS: ?location=campus puts you on campus, otherwise off campus
final locatorProvider = Provider<MockLocator>((ref) {
  final query = ref.watch(homeLaunchQueryProvider);
  return MockLocator(onCampus: query['location'] == 'campus');
});

final speechRecognizerProvider = Provider<MockSpeechRecognizer>(
  (ref) => const MockSpeechRecognizer(),
);
