import 'package:flutter/widgets.dart';

import '../../../core/router.dart';
import '../../campus/state/trip_controller.dart';

abstract final class SearchRoutes {
  static void close<T>(BuildContext context, [T? result]) =>
      AppNav.close(context, result);

  // Replace search with guidance so back returns home
  static void navigate(BuildContext context, TripState trip) {
    final from = trip.from;
    final to = trip.to;
    if (from == null || to == null) return;
    AppNav.replace(
      context,
      AppRoutes.navigationUri(
        from: from.id,
        to: to.id,
        mode: trip.mode.name,
        indoor: trip.indoor,
      ),
    );
  }
}
