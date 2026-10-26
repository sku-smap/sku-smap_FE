import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router.dart';
import '../data/campus_models.dart';

abstract final class HomeRoutes {
  static void _push(
    BuildContext context,
    String path, [
    Map<String, String>? query,
  ]) {
    final uri = Uri(
      path: path,
      queryParameters: query == null || query.isEmpty ? null : query,
    );
    GoRouter.maybeOf(context)?.push(uri.toString());
  }

  static void search(BuildContext context) => _push(context, AppRoutes.search);

  static void pickFrom(BuildContext context, {CampusPlace? to}) =>
      _push(context, AppRoutes.search, {'pick': 'from', 'to': ?to?.id});

  static void pickTo(BuildContext context) =>
      _push(context, AppRoutes.search, {'pick': 'to'});

  static void voice(BuildContext context) =>
      _push(context, AppRoutes.search, {'mode': 'voice'});

  static void navigate(
    BuildContext context, {
    required CampusPlace from,
    required CampusPlace to,
    required RouteMode mode,
    required bool indoor,
  }) => _push(context, AppRoutes.navigation, {
    'from': from.id,
    'to': to.id,
    'mode': mode.name,
    if (indoor) 'indoor': '1',
  });

  static void explore(
    BuildContext context, {
    String? building,
    String? floor,
  }) => _push(context, AppRoutes.explore, {
    'building': ?building,
    'floor': ?floor,
  });

  static void report(BuildContext context) => _push(context, AppRoutes.report);
}
