import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router.dart';

abstract final class ExploreRoutes {
  // Replace the viewer with destination search so back returns home
  static void pickTo(BuildContext context) {
    final uri = Uri(path: AppRoutes.search, queryParameters: {'pick': 'to'});
    GoRouter.maybeOf(context)?.pushReplacement(uri.toString());
  }
}
