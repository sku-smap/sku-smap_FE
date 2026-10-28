import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/data/campus_models.dart';
import '../../navigation/data/route_graph.dart';

typedef ExploreEntry = ({String node, String? intro});

const exploreGate = 'gate_front';

// Map tab opens at the chosen start (or the gate); building sheet opens there
ExploreEntry exploreEntryFor(Map<String, String> query, CampusPlace? from) {
  final building = query['building'];
  if (building != null) {
    final floor = query['floor'];
    final node = floor == null
        ? routeEndFor('b-$building')?.node
        : floorsOf(building).where((f) => f.label == floor).firstOrNull?.node;
    return (node: node ?? exploreGate, intro: null);
  }
  final start = from == null ? null : routeEndFor(from.id)?.node;
  if (from == null || start == null) {
    return (node: exploreGate, intro: '정문에서 둘러봐요. 출발지를 정하면 그 자리에서 열려요');
  }
  return (node: start, intro: '지금 위치(${from.name})에서 둘러봐요. 사진 속 화살표로 이동하세요');
}

class ExploreState {
  const ExploreState({required this.node, this.showMap = true, this.toast});

  final String node;
  final bool showMap;
  final String? toast;

  ExploreState copyWith({
    String? node,
    bool? showMap,
    String? Function()? toast,
  }) {
    return ExploreState(
      node: node ?? this.node,
      showMap: showMap ?? this.showMap,
      toast: toast != null ? toast() : this.toast,
    );
  }
}

class ExploreController extends Notifier<ExploreState> {
  ExploreController(this.entry);

  static const toastDuration = Duration(milliseconds: 3200);

  final ExploreEntry entry;
  Timer? _toastTimer;

  @override
  ExploreState build() {
    ref.onDispose(() => _toastTimer?.cancel());
    if (entry.intro != null) _scheduleHide();
    return ExploreState(node: entry.node, toast: entry.intro);
  }

  void goTo(String node) => state = state.copyWith(node: node);

  void toggleMap() => state = state.copyWith(showMap: !state.showMap);

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

final exploreProvider = NotifierProvider.autoDispose
    .family<ExploreController, ExploreState, ExploreEntry>(
      ExploreController.new,
    );
