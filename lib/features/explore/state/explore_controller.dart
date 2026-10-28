import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/toast_host.dart';
import '../../campus/data/campus_directory.dart';
import '../../campus/data/campus_models.dart';
import '../../navigation/data/route_graph.dart';
import '../../navigation/state/link_yaw_controller.dart';

typedef ExploreEntry = ({String node, String? intro, bool edit});

const exploreGate = 'gate_front';

const noLinksNotice = '이 지점은 아직 이동 연결이 없어요';

String? _known(String? node) => spotById.containsKey(node) ? node : null;

// Map tab opens at the chosen start (or the gate); building sheet opens there;
// ids the spot list does not know fall back to the gate
ExploreEntry exploreEntryFor(
  Map<String, String> query,
  CampusPlace? from, {
  bool edit = false,
}) {
  final building = query['building'];
  if (building != null) {
    final floor = query['floor'];
    final node = _known(
      floor == null
          ? nodeOf('b-$building')
          : floorsOf(building).where((f) => f.label == floor).firstOrNull?.node,
    );
    return (node: node ?? exploreGate, intro: null, edit: edit);
  }
  final start = _known(nodeOf(from?.id));
  if (from == null || start == null) {
    return (
      node: exploreGate,
      intro: '정문에서 둘러봐요. 출발지를 정하면 그 자리에서 열려요',
      edit: edit,
    );
  }
  return (
    node: start,
    intro: '지금 위치(${from.name})에서 둘러봐요. 사진 속 화살표로 이동하세요',
    edit: edit,
  );
}

class ExploreState {
  const ExploreState({
    required this.node,
    this.showMap = true,
    this.toast,
    this.editLink,
  });

  final String node;
  final bool showMap;
  final String? toast;
  final String? editLink;

  ExploreState copyWith({
    String? node,
    bool? showMap,
    String? Function()? toast,
    String? Function()? editLink,
  }) {
    return ExploreState(
      node: node ?? this.node,
      showMap: showMap ?? this.showMap,
      toast: toast != null ? toast() : this.toast,
      editLink: editLink != null ? editLink() : this.editLink,
    );
  }
}

class ExploreController extends Notifier<ExploreState>
    with ToastHost<ExploreState> {
  ExploreController(this.entry);

  final ExploreEntry entry;

  @override
  ExploreState build() {
    bindToast();
    final intro = _linkNotice(entry.node) ?? entry.intro;
    if (intro != null) scheduleToastHide();
    return ExploreState(
      node: entry.node,
      toast: intro,
      editLink: _firstLink(entry.node),
    );
  }

  @override
  ExploreState withToast(ExploreState state, String? message) =>
      state.copyWith(toast: () => message);

  String? _firstLink(String node) =>
      entry.edit ? linksOf(node).firstOrNull?.to : null;

  // Spots only the server knows have no arrows until links are provided
  String? _linkNotice(String node) =>
      linksOf(node).isEmpty ? noLinksNotice : null;

  void goTo(String node) {
    if (!spotById.containsKey(node)) return;
    state = state.copyWith(node: node, editLink: () => _firstLink(node));
    final notice = _linkNotice(node);
    if (notice != null) toast(notice);
  }

  void toggleMap() => state = state.copyWith(showMap: !state.showMap);

  void selectEditLink(String to) => state = state.copyWith(editLink: () => to);

  // Edit mode: the tapped photo direction becomes the chosen link's arrow
  Future<void> fixDirection(double yaw) async {
    final to = state.editLink;
    if (!entry.edit || to == null) return;
    await ref.read(linkYawProvider.notifier).fix(state.node, to, yaw);
  }
}

final exploreProvider = NotifierProvider.autoDispose
    .family<ExploreController, ExploreState, ExploreEntry>(
      ExploreController.new,
    );
