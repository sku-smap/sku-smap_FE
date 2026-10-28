import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../campus/data/campus_models.dart';
import '../../../campus/state/campus_status_providers.dart';
import '../../../campus/state/place_providers.dart';
import '../../../campus/state/trip_controller.dart';
import '../../../report/presentation/widgets/applied_notice.dart';
import '../../state/home_controller.dart';
import '../home_routes.dart';
import '../home_tokens.dart';
import '../widgets/building_sheet.dart';
import '../widgets/campus_map_card.dart';
import '../widgets/closure_card.dart';
import '../widgets/facility_sheet.dart';
import '../widgets/home_hero.dart';
import '../widgets/home_sheet.dart';
import '../widgets/home_tab_bar.dart';
import '../widgets/quick_chips.dart';
import '../widgets/route_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // Hide sheet places the server list no longer has, once it has loaded
  static List<CampusPlace> _knownPlaces(WidgetRef ref, CampusBuilding b) {
    final server = ref.read(placeCatalogProvider).value;
    if (server == null) return b.places;
    final ids = {for (final p in server) p.id};
    return [
      for (final p in b.places)
        if (ids.contains(p.id)) p,
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(tripProvider);
    final tripController = ref.read(tripProvider.notifier);
    final home = ref.watch(homeControllerProvider);
    final controller = ref.read(homeControllerProvider.notifier);
    final closures = ref.watch(campusClosuresProvider).value ?? const [];
    final weather = ref.watch(campusWeatherProvider).value;

    void startRoute() => HomeRoutes.navigate(context, ref.read(tripProvider));

    // Pick a destination, then ask for the start or go straight to guidance
    void chooseTo(CampusPlace place) {
      tripController.setTo(place);
      if (ref.read(tripProvider).from != null) {
        startRoute();
      } else {
        HomeRoutes.pickFrom(context, to: place);
      }
    }

    void chooseFrom(CampusPlace place) {
      tripController.setFrom(place);
      if (ref.read(tripProvider).to != null) startRoute();
    }

    void openBuilding(CampusBuilding building) {
      showHomeSheet(
        context,
        child: BuildingSheet(
          building: building,
          places: _knownPlaces(ref, building),
          onExplore: ({floor}) =>
              HomeRoutes.explore(context, building: building.id, floor: floor),
          onSetFrom: chooseFrom,
          onSetTo: chooseTo,
        ),
      );
    }

    // A single facility starts routing; a shared spot asks which one
    void openFacility(FacilitySpot spot) {
      if (spot.places.length == 1) {
        chooseTo(spot.places.first);
        return;
      }
      showHomeSheet(
        context,
        child: FacilitySheet(spot: spot, onPick: chooseTo),
      );
    }

    return Scaffold(
      backgroundColor: HomeColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: HomeTabBar.heightOf(context) + HomeLayout.mapCardGap,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HomeHero(
                    onSearch: () => HomeRoutes.search(context),
                    routeCard: RouteCard(
                      trip: trip,
                      weather: weather ?? const CampusWeather(),
                      onPickFrom: () => HomeRoutes.pickFrom(context),
                      onPickTo: () => HomeRoutes.pickTo(context),
                      onSwap: tripController.swap,
                      onMode: tripController.setMode,
                      onGo: startRoute,
                      onIndoor: tripController.toggleIndoor,
                    ),
                  ),
                  if (closures.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        HomeLayout.screenH,
                        HomeLayout.sectionGap,
                        HomeLayout.screenH,
                        0,
                      ),
                      child: ClosureCard(closures: closures),
                    ),
                  const SizedBox(height: HomeLayout.sectionGap),
                  QuickChips(onSelect: chooseTo),
                  const SizedBox(height: 4 + HomeLayout.mapCardGap),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: HomeLayout.screenH,
                    ),
                    child: CampusMapCard(
                      level: home.level,
                      facility: home.facility,
                      onLevel: controller.setLevel,
                      onFacility: controller.setFacility,
                      onBuilding: openBuilding,
                      onFacilitySpot: openFacility,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: HomeTabBar(
              onMap: () => HomeRoutes.explore(context),
              onVoice: () => HomeRoutes.voice(context),
              onReport: () => HomeRoutes.report(context),
            ),
          ),
          const ReportAppliedNotice(),
        ],
      ),
    );
  }
}
