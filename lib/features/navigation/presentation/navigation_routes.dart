import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/router.dart';
import '../data/navigation_assets.dart';
import '../data/navigation_models.dart';

abstract final class NavigationRoutes {
  static void exit(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(AppRoutes.home);
    }
  }

  static void report(
    BuildContext context, {
    required String node,
    int? step,
    String? kind,
  }) {
    final uri = Uri(
      path: AppRoutes.report,
      queryParameters: {
        'node': node,
        if (step != null) 'step': '$step',
        'kind': ?kind,
      },
    );
    GoRouter.maybeOf(context)?.push(uri.toString());
  }

  // Open the OS share sheet with a link that starts the same route
  static Future<void> share(ActiveRoute route) {
    final uri = Uri.parse(NavigationAssets.shareBase)
        .replace(queryParameters: {'from': route.from.id, 'to': route.to.id});
    return SharePlus.instance.share(
      ShareParams(
        title: 'SMAP 길 안내',
        text: 'SMAP · ${route.from.label} → ${route.to.label} 길 안내\n$uri',
      ),
    );
  }
}
