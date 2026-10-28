import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/toast_host.dart';
import '../../campus/data/campus_directory.dart';
import '../../campus/data/campus_models.dart';
import '../../campus/state/campus_status_providers.dart';
import '../../campus/state/place_providers.dart';
import '../data/guide_voice.dart';
import '../data/navigation_models.dart';
import '../data/route_graph.dart';

typedef NavigationEntry = ({
  String? from,
  String? to,
  RouteMode mode,
  bool indoor,
});

class NavigationState {
  const NavigationState({
    this.loading = false,
    this.route,
    this.node,
    this.showMap = true,
    this.muted = false,
    this.praised = false,
    this.toast,
  });

  final bool loading;
  final ActiveRoute? route;
  final String? node;
  final bool showMap;
  final bool muted;
  final bool praised;
  final String? toast;

  int get stepIdx => route?.path.indexOf(node ?? '') ?? -1;

  String? get next {
    final r = route;
    final i = stepIdx;
    return r != null && i >= 0 && i < r.last ? r.path[i + 1] : null;
  }

  bool get arrived => route != null && stepIdx == route!.last;

  String get text {
    final r = route;
    final here = node;
    final to = next;
    if (r == null || here == null) return '';
    if (arrived) return '도착했어요. ${r.to.label}입니다.';
    return to == null ? '' : instruction(here, to);
  }

  NavigationState copyWith({
    ActiveRoute? Function()? route,
    String? node,
    bool? showMap,
    bool? muted,
    bool? praised,
    String? Function()? toast,
  }) {
    return NavigationState(
      loading: loading,
      route: route != null ? route() : this.route,
      node: node ?? this.node,
      showMap: showMap ?? this.showMap,
      muted: muted ?? this.muted,
      praised: praised ?? this.praised,
      toast: toast != null ? toast() : this.toast,
    );
  }
}

class NavigationController extends Notifier<NavigationState>
    with ToastHost<NavigationState> {
  NavigationController(this.entry);

  final NavigationEntry entry;
  Set<String> _blocked = const {};

  @override
  NavigationState build() {
    bindToast();
    final voice = ref.read(guideVoiceProvider);
    ref.onDispose(voice.stop);
    // Route once places, closures and weather are known
    final places = ref.watch(placeCatalogProvider);
    final closures = ref.watch(campusClosuresProvider);
    final weather = ref.watch(campusWeatherProvider);
    if (places.isLoading || closures.isLoading || weather.isLoading) {
      return const NavigationState(loading: true);
    }
    _blocked = {for (final c in closures.value ?? const <Closure>[]) c.node};
    final from = routeEndFor(entry.from);
    final to = routeEndFor(entry.to);
    final path = from == null || to == null
        ? null
        : findRoute(
            from.node,
            to.node,
            mode: entry.mode,
            indoor: entry.indoor,
            blocked: _blocked,
          );
    if (from == null || to == null || path == null) {
      scheduleToastHide();
      return const NavigationState(toast: '아직 연결된 길 데이터가 없어요');
    }
    final wet = weather.value?.isWet ?? false;
    final notice = entry.indoor && wet
        ? '비가 와서 실내·지하 길로 먼저 안내해요'
        : entry.mode == RouteMode.elevator && usesStairs(path)
        ? '엘리베이터로만 가는 길이 없어서 계단이 조금 포함돼요'
        : null;
    if (notice != null) scheduleToastHide();
    final initial = NavigationState(
      route: ActiveRoute(from: from, to: to, path: path),
      node: path.first,
      toast: notice,
    );
    Future.microtask(() => _speak(initial));
    return initial;
  }

  @override
  NavigationState withToast(NavigationState state, String? message) =>
      state.copyWith(toast: () => message);

  // Move to a spot; off the route, search again from there
  void goTo(String node) {
    final route = state.route;
    if (route != null && !route.path.contains(node)) {
      final path = findRoute(
        node,
        route.to.node,
        mode: entry.mode,
        indoor: entry.indoor,
        blocked: _blocked,
      );
      if (path != null) {
        final here = spotById[node]!;
        state = state.copyWith(
          route: () => ActiveRoute(
            from: RouteEnd(id: node, node: node, label: here.title),
            to: route.to,
            path: path,
          ),
          node: node,
        );
        toast('경로를 다시 찾았어요');
      } else {
        state = state.copyWith(route: () => null, node: node);
      }
    } else {
      state = state.copyWith(node: node);
    }
    _speak(state);
  }

  void toggleMap() => state = state.copyWith(showMap: !state.showMap);

  void toggleMute() {
    final muted = !state.muted;
    state = state.copyWith(muted: muted);
    if (muted) {
      ref.read(guideVoiceProvider).stop();
    } else {
      _speak(state);
    }
  }

  void praise() => state = state.copyWith(praised: true);

  void _speak(NavigationState s) {
    final text = s.text;
    if (s.muted || text.isEmpty) return;
    ref.read(guideVoiceProvider).speak(text);
  }
}

final navigationProvider = NotifierProvider.autoDispose
    .family<NavigationController, NavigationState, NavigationEntry>(
      NavigationController.new,
    );

final guideVoiceProvider = Provider<GuideVoice>((ref) => TtsGuideVoice());

// Photos load from the storage bucket; tests swap in local images
final photoImageProvider = Provider<ImageProvider Function(String url)>(
  (ref) => NetworkImage.new,
);
