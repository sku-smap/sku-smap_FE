import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_config.dart';
import '../../../core/network/app_exception.dart';
import '../../../core/network/data_source.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/state/toast_host.dart';
import '../../campus/data/campus_directory.dart';
import '../../campus/data/campus_models.dart';
import '../../campus/state/campus_status_providers.dart';
import '../../campus/state/node_providers.dart';
import '../../campus/state/place_providers.dart';
import '../data/api_route_repository.dart';
import '../data/guide_voice.dart';
import '../data/mock_route_repository.dart';
import '../data/navigation_assets.dart';
import '../data/navigation_models.dart';
import '../data/photo_cache.dart';
import '../data/route_graph.dart';
import '../data/route_plan.dart';
import '../data/route_repository.dart';

typedef NavigationEntry = ({
  String? from,
  String? to,
  RouteMode mode,
  bool indoor,
  RouteOption? option,
});

// The route API takes one option: the searched one, else a picked mode over
// indoor since stairs can rule a way out entirely
RouteOption routeOptionOf(NavigationEntry e) =>
    e.option ??
    switch (e.mode) {
      RouteMode.comfortable => RouteOption.comfortable,
      RouteMode.shortest => RouteOption.shortest,
      RouteMode.outdoor when e.indoor => RouteOption.indoorUndergroundFirst,
      RouteMode.outdoor => RouteOption.outdoorFirst,
    };

class NavigationState {
  const NavigationState({
    this.loading = false,
    this.error,
    this.route,
    this.node,
    this.showMap = true,
    this.muted = false,
    this.praised = false,
    this.toast,
  });

  final bool loading;
  final String? error;
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
    return to == null ? '' : instruction(here, to, r.legAt(stepIdx));
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
      error: error,
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

  static const noRoute = '아직 연결된 길 데이터가 없어요';
  static const closedOnRoute = '경로에 지금 못 가는 곳이 있어요';

  final NavigationEntry entry;
  Set<String> _blocked = const {};
  var _run = 0;
  RouteEnd? _from;
  RouteEnd? _to;

  RouteOption get option => routeOptionOf(entry);

  RouteRepository get _repo => ref.read(routeRepositoryProvider);

  @override
  NavigationState build() {
    bindToast();
    final voice = ref.read(guideVoiceProvider);
    final photos = ref.read(photoCacheProvider);
    ref.onDispose(() {
      _run++;
      voice.stop();
      photos.clear();
    });
    // Route once spots, places and closures are known
    final nodes = ref.watch(nodeCatalogProvider);
    final places = ref.watch(placeCatalogProvider);
    final closures = ref.watch(campusClosuresProvider);
    if ([nodes, places, closures].any((v) => v.isLoading)) {
      return const NavigationState(loading: true);
    }
    _blocked = {for (final c in closures.value ?? const <Closure>[]) c.node};
    _from = routeEndFor(entry.from);
    _to = routeEndFor(entry.to);
    if (_from == null || _to == null) {
      scheduleToastHide();
      return const NavigationState(toast: noRoute);
    }
    final run = _run;
    Future.microtask(() {
      if (run == _run) _load();
    });
    return const NavigationState(loading: true);
  }

  @override
  NavigationState withToast(NavigationState state, String? message) =>
      state.copyWith(toast: () => message);

  // Ask the route API; a failure keeps the screen and offers a retry
  Future<void> _load() async {
    final from = _from!;
    final to = _to!;
    final run = ++_run;
    final keep = state;
    state = NavigationState(
      loading: true,
      showMap: keep.showMap,
      muted: keep.muted,
    );
    try {
      final plan = await _repo.find(
        from: from.node,
        to: to.node,
        option: option,
      );
      if (run != _run) return;
      if (plan == null) {
        state = const NavigationState(toast: noRoute);
        scheduleToastHide();
        return;
      }
      _merge(plan);
      final route = ActiveRoute(
        from: from,
        to: to,
        path: plan.path,
        legs: plan.legs,
      );
      final notice = _notice(route);
      state = NavigationState(
        route: route,
        node: route.path.first,
        showMap: keep.showMap,
        muted: keep.muted,
        toast: notice,
      );
      if (notice != null) scheduleToastHide();
      _speak(state);
      _prefetchAhead();
    } on AppException catch (e) {
      if (run != _run) return;
      state = NavigationState(
        error: e.message,
        showMap: keep.showMap,
        muted: keep.muted,
      );
    }
  }

  void retry() {
    if (state.error != null) _load();
  }

  // Route nodes and segments join the graph so photos and arrows resolve
  void _merge(RoutePlan plan) {
    registerSpots(plan.spots);
    // A merged multi-floor elevator segment is not a real edge between photos
    registerLinks([
      for (final link in plan.links)
        if (link.$2.via != Via.elevator) link,
    ]);
    if (plan.path.any((id) => !spotById.containsKey(id))) {
      throw const ParseException('경로에 모르는 지점이 있어요.');
    }
  }

  // The server cannot avoid closures yet, so a closed spot only warns
  String? _notice(ActiveRoute route) {
    if (route.path.any(_blocked.contains)) return closedOnRoute;
    if (option == RouteOption.comfortable &&
        route.legs.any((l) => l.via == Via.stairs)) {
      return '엘리베이터로만 가는 길이 없어서 계단이 조금 포함돼요';
    }
    return null;
  }

  // Move to a spot; off the route, search again from there
  void goTo(String node) {
    final route = state.route;
    state = state.copyWith(node: node);
    if (route != null && !route.path.contains(node)) {
      _reroute(node, route);
    } else {
      _speak(state);
      _prefetchAhead();
    }
  }

  // Download the photos from the next step to the goal in order, so 다음
  // shows one already fetched
  void _prefetchAhead() {
    final route = state.route;
    final i = state.stepIdx;
    if (route == null || i < 0) return;
    ref.read(photoPrefetchProvider)([
      for (final id in route.path.skip(i + 1))
        spotById[id]?.imageUrl ?? NavigationAssets.pano(id),
    ]);
  }

  // The old route stays until the new one arrives for this same spot
  Future<void> _reroute(String node, ActiveRoute route) async {
    final run = ++_run;
    try {
      final plan = await _repo.find(
        from: node,
        to: route.to.node,
        option: option,
      );
      if (run != _run || state.node != node) return;
      if (plan == null) {
        state = state.copyWith(route: () => null);
        return;
      }
      _merge(plan);
      state = state.copyWith(
        route: () => ActiveRoute(
          from: RouteEnd(id: node, node: node, label: spotById[node]!.title),
          to: route.to,
          path: plan.path,
          legs: plan.legs,
        ),
      );
      toast(_notice(state.route!) ?? '경로를 다시 찾았어요');
      _speak(state);
      _prefetchAhead();
    } on AppException catch (e) {
      if (run != _run || state.node != node) return;
      toast(e.message);
    }
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

// Mock mode walks the bundled graph around the demo closures
final routeRepositoryProvider = Provider<RouteRepository>(
  (ref) => selectDataSource(
    ref.watch(appConfigProvider),
    mock: () => MockRouteRepository(
      blocked: () => {
        for (final c in ref.read(campusClosuresProvider).value ?? const [])
          c.node,
      },
    ),
    api: () => ApiRouteRepository(ref.watch(apiClientProvider)),
  ),
);

final guideVoiceProvider = Provider<GuideVoice>((ref) => TtsGuideVoice());

// Photos load from the storage bucket; tests swap in local images
// Photo files over plain HTTPS; signed URLs carry their own access
final photoFetchProvider = Provider<PhotoFetch>((ref) {
  final dio = Dio(
    BaseOptions(
      responseType: ResponseType.bytes,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );
  ref.onDispose(dio.close);
  return (url) async =>
      Uint8List.fromList((await dio.get<List<int>>(url)).data ?? const []);
});

final photoCacheProvider = Provider<PhotoCache>(
  (ref) => PhotoCache(ref.watch(photoFetchProvider)),
);

// Tests swap this out so guidance never downloads in the background
final photoPrefetchProvider = Provider<void Function(List<String> urls)>(
  (ref) =>
      (urls) => ref.read(photoCacheProvider).prefetch(urls).ignore(),
);

// Photos come through the cache; tests swap in local images
final photoImageProvider = Provider<ImageProvider Function(String url)>((ref) {
  final cache = ref.watch(photoCacheProvider);
  return (url) => CachedPhoto(url, cache);
});
