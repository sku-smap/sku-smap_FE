import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../campus/data/campus_models.dart';

// Campus map card choices that only the home screen uses
class HomeState {
  const HomeState({this.level = MapLevel.ground, this.facility});

  final MapLevel level;
  final FacilityCategory? facility;

  HomeState copyWith({
    MapLevel? level,
    FacilityCategory? Function()? facility,
  }) {
    return HomeState(
      level: level ?? this.level,
      facility: facility != null ? facility() : this.facility,
    );
  }
}

class HomeController extends Notifier<HomeState> {
  @override
  HomeState build() => const HomeState();

  void setLevel(MapLevel level) => state = state.copyWith(level: level);

  void setFacility(FacilityCategory? facility) =>
      state = state.copyWith(facility: () => facility);
}

final homeControllerProvider = NotifierProvider<HomeController, HomeState>(
  HomeController.new,
);
