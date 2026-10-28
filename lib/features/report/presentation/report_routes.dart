import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router.dart';

abstract final class ReportRoutes {
  static void close(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(AppRoutes.home);
    }
  }

  // Swap the sheet for the status list so back returns to where it opened
  static void mine(BuildContext context) =>
      GoRouter.maybeOf(context)?.pushReplacement(AppRoutes.myReports);

  static void voice(BuildContext context) {
    final uri = Uri(path: AppRoutes.search, queryParameters: {'mode': 'voice'});
    GoRouter.maybeOf(context)?.push(uri.toString());
  }
}
