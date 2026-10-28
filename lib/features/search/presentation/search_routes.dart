import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router.dart';
import '../../home/data/campus_models.dart';

abstract final class SearchRoutes {
  static void close(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(AppRoutes.home);
    }
  }

  // Replace search with guidance so back returns home
  static void navigate(
    BuildContext context, {
    required CampusPlace from,
    required CampusPlace to,
    required RouteMode mode,
    required bool indoor,
  }) {
    final uri = Uri(
      path: AppRoutes.navigation,
      queryParameters: {
        'from': from.id,
        'to': to.id,
        'mode': mode.name,
        if (indoor) 'indoor': '1',
      },
    );
    GoRouter.maybeOf(context)?.pushReplacement(uri.toString());
  }
}
