import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_config.dart';
import '../../../core/network/data_source.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/state/toast_host.dart';
import '../../campus/state/launch_provider.dart';
import '../data/api_search_repository.dart';
import '../data/location_service.dart';
import '../data/mock_location.dart';
import '../data/mock_search_repository.dart';
import '../data/record_voice_recorder.dart';
import '../data/search_models.dart';
import '../data/search_repository.dart';
import '../data/voice_recorder.dart';

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

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => selectDataSource(
    ref.watch(appConfigProvider),
    mock: MockSearchRepository.new,
    api: () => ApiSearchRepository(ref.watch(apiClientProvider)),
  ),
);

final voiceRecorderProvider = Provider<VoiceRecorder>((ref) {
  final recorder = RecordVoiceRecorder();
  ref.onDispose(recorder.dispose);
  return recorder;
});
