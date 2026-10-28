import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../report/presentation/widgets/applied_notice.dart';
import '../../data/campus_models.dart';
import '../../state/home_controller.dart';
import '../../state/home_entry_provider.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeControllerProvider);
    final controller = ref.read(homeControllerProvider.notifier);
    final closures = ref.watch(campusClosuresProvider);

    void startRoute() {
      final s = ref.read(homeControllerProvider);
      final from = s.from;
      final to = s.to;
      if (from == null || to == null) return;
      HomeRoutes.navigate(
        context,
        from: from,
        to: to,
        mode: s.mode,
        indoor: s.indoor,
      );
    }

    // Pick a destination, then ask for the start or go straight to guidance
    void chooseTo(CampusPlace place) {
      controller.setTo(place);
      if (ref.read(homeControllerProvider).from != null) {
        startRoute();
      } else {
        HomeRoutes.pickFrom(context, to: place);
      }
    }

    void chooseFrom(CampusPlace place) {
      controller.setFrom(place);
      if (ref.read(homeControllerProvider).to != null) startRoute();
    }

    void openBuilding(CampusBuilding building) {
      showHomeSheet(
        context,
        child: BuildingSheet(
          building: building,
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
                      state: state,
                      weather: ref.watch(campusWeatherProvider),
                      onPickFrom: () => HomeRoutes.pickFrom(context),
                      onPickTo: () => HomeRoutes.pickTo(context),
                      onSwap: controller.swap,
                      onMode: controller.setMode,
                      onGo: startRoute,
                      onIndoor: controller.toggleIndoor,
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
                      level: state.level,
                      facility: state.facility,
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
