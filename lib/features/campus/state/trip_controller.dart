import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/campus_directory.dart';
import '../data/campus_models.dart';
import 'campus_status_providers.dart';
import 'launch_provider.dart';
import 'place_providers.dart';

// Start, destination and route options shared by every screen
class TripState {
  const TripState({
    this.from,
    this.to,
    this.mode = RouteMode.outdoor,
    this.indoor = false,
    this.routeOption,
  });

  final CampusPlace? from;
  final CampusPlace? to;
  final RouteMode mode;
  final bool indoor;

  // Preference the search understood, kept for the route API
  final RouteOption? routeOption;

  bool get canRoute => from != null && to != null;

  TripState copyWith({
    CampusPlace? Function()? from,
    CampusPlace? Function()? to,
    RouteMode? mode,
    bool? indoor,
    RouteOption? Function()? routeOption,
  }) {
    return TripState(
      from: from != null ? from() : this.from,
      to: to != null ? to() : this.to,
      mode: mode ?? this.mode,
      indoor: indoor ?? this.indoor,
      routeOption: routeOption != null ? routeOption() : this.routeOption,
    );
  }
}

class TripController extends Notifier<TripState> {
  var _indoorTouched = false;

  @override
  TripState build() {
    final launch = ref.read(launchEntryProvider);
    // Rain turns indoor routing on until the user changes it
    ref.listen(campusWeatherProvider, (_, next) {
      final wet = next.value?.isWet;
      if (wet != null && !_indoorTouched) {
        state = state.copyWith(indoor: wet);
      }
    });
    // Link ids only the server knows resolve once the place list arrives
    ref.listen(placeCatalogProvider, (_, next) {
      if (!next.hasValue) return;
      state = state.copyWith(
        from: () => state.from ?? resolvePlace(launch.from),
        to: () => state.to ?? resolvePlace(launch.to),
      );
    });
    return TripState(
      from: resolvePlace(launch.from),
      to: resolvePlace(launch.to),
      indoor: ref.read(campusWeatherProvider).value?.isWet ?? false,
    );
  }

  void setFrom(CampusPlace place) => state = state.copyWith(from: () => place);

  void setTo(CampusPlace place) => state = state.copyWith(to: () => place);

  void swap() =>
      state = state.copyWith(from: () => state.to, to: () => state.from);

  // A manual choice replaces what the search understood
  void setMode(RouteMode mode) =>
      state = state.copyWith(mode: mode, routeOption: () => null);

  // Shortest has no app option, so only the stored value changes
  void applyRouteOption(RouteOption option) {
    if (option == RouteOption.indoorUndergroundFirst) _indoorTouched = true;
    state = state.copyWith(
      routeOption: () => option,
      mode: switch (option) {
        RouteOption.comfortable => RouteMode.elevator,
        RouteOption.outdoorFirst => RouteMode.outdoor,
        _ => null,
      },
      indoor: option == RouteOption.indoorUndergroundFirst ? true : null,
    );
  }

  void toggleIndoor() {
    _indoorTouched = true;
    state = state.copyWith(indoor: !state.indoor);
  }
}

final tripProvider = NotifierProvider<TripController, TripState>(
  TripController.new,
);
