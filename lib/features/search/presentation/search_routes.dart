import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router.dart';

abstract final class SearchRoutes {
  static void close<T>(BuildContext context, [T? result]) =>
      AppNav.close(context, result);

  // Leave search for the home route card, wherever search was opened from
  static void home(BuildContext context) =>
      GoRouter.maybeOf(context)?.go(AppRoutes.home);
}
