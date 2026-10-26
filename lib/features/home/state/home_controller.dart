import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/campus_models.dart';
import 'home_entry_provider.dart';

class HomeState {
  const HomeState({
    this.from,
    this.to,
    this.mode = RouteMode.outdoor,
    this.indoor = false,
    this.level = MapLevel.ground,
    this.facility,
  });

  final CampusPlace? from;
  final CampusPlace? to;
  final RouteMode mode;
  final bool indoor;
  final MapLevel level;
  final FacilityCategory? facility;

  bool get canRoute => from != null && to != null;

  HomeState copyWith({
    CampusPlace? Function()? from,
    CampusPlace? Function()? to,
    RouteMode? mode,
    bool? indoor,
    MapLevel? level,
    FacilityCategory? Function()? facility,
  }) {
    return HomeState(
      from: from != null ? from() : this.from,
      to: to != null ? to() : this.to,
      mode: mode ?? this.mode,
      indoor: indoor ?? this.indoor,
      level: level ?? this.level,
      facility: facility != null ? facility() : this.facility,
    );
  }
}

class HomeController extends Notifier<HomeState> {
  @override
  HomeState build() {
    final query = ref.watch(homeLaunchQueryProvider);
    return HomeState(
      from: placeFromId(query['from']),
      to: placeFromId(query['to']),
      indoor: ref.watch(campusWeatherProvider).isWet,
    );
  }

  void setFrom(CampusPlace place) => state = state.copyWith(from: () => place);

  void setTo(CampusPlace place) => state = state.copyWith(to: () => place);

  void swap() =>
      state = state.copyWith(from: () => state.to, to: () => state.from);

  void setMode(RouteMode mode) => state = state.copyWith(mode: mode);

  void toggleIndoor() => state = state.copyWith(indoor: !state.indoor);

  void setLevel(MapLevel level) => state = state.copyWith(level: level);

  void setFacility(FacilityCategory? facility) =>
      state = state.copyWith(facility: () => facility);
}

final homeControllerProvider = NotifierProvider<HomeController, HomeState>(
  HomeController.new,
);
