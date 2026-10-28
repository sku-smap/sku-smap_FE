import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/toast_host.dart';
import '../../campus/state/launch_provider.dart';
import '../data/location_service.dart';
import '../data/mock_location.dart';
import '../data/mock_speech.dart';
import '../data/search_models.dart';
import '../data/speech_recognizer.dart';

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

class SearchFlowController extends Notifier<SearchFlowState>
    with ToastHost<SearchFlowState> {
  SearchFlowController(this.entry);

  final SearchEntry entry;

  @override
  SearchFlowState build() {
    bindToast();
    final intro = entry.intro;
    if (intro != null) scheduleToastHide();
    return SearchFlowState(
      target: entry.target,
      voice: entry.voice,
      toast: intro,
    );
  }

  @override
  SearchFlowState withToast(SearchFlowState state, String? message) =>
      state.copyWith(toast: () => message);

  void pick(PickTarget target) =>
      state = state.copyWith(target: target, voice: false);

  void openVoice() => state = state.copyWith(voice: true);
}

final searchFlowProvider = NotifierProvider.autoDispose
    .family<SearchFlowController, SearchFlowState, SearchEntry>(
      SearchFlowController.new,
    );

final locatorProvider = Provider<LocationService>(
  (ref) => MockLocator(onCampus: ref.watch(launchEntryProvider).onCampus),
);

final speechRecognizerProvider = Provider<SpeechRecognizer>(
  (ref) => const MockSpeechRecognizer(),
);
