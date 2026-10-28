import 'package:flutter/widgets.dart';

import '../../../core/router.dart';
import '../../campus/data/campus_models.dart';
import '../../campus/state/trip_controller.dart';

abstract final class HomeRoutes {
  static void search(BuildContext context) =>
      AppNav.push(context, AppRoutes.searchUri());

  static void pickFrom(BuildContext context, {CampusPlace? to}) =>
      AppNav.push(context, AppRoutes.searchUri(pick: 'from', to: to?.id));

  static void pickTo(BuildContext context) =>
      AppNav.push(context, AppRoutes.searchUri(pick: 'to'));

  static void voice(BuildContext context) =>
      AppNav.push(context, AppRoutes.searchUri(voice: true));

  static void navigate(BuildContext context, TripState trip) {
    final from = trip.from;
    final to = trip.to;
    if (from == null || to == null) return;
    AppNav.push(
      context,
      AppRoutes.navigationUri(
        from: from.id,
        to: to.id,
        mode: trip.mode.name,
        indoor: trip.indoor,
      ),
    );
  }

  static void explore(
    BuildContext context, {
    String? building,
    String? floor,
  }) => AppNav.push(
    context,
    AppRoutes.exploreUri(building: building, floor: floor),
  );

  static void report(BuildContext context) =>
      AppNav.push(context, AppRoutes.reportUri());
}
