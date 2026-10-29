import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/router.dart';
import '../data/navigation_assets.dart';
import '../data/navigation_models.dart';

abstract final class NavigationRoutes {
  static void exit(BuildContext context) => AppNav.close(context);

  static void report(
    BuildContext context, {
    required String node,
    int? step,
    String? kind,
  }) => AppNav.push(
    context,
    AppRoutes.reportUri(node: node, step: step, kind: kind),
  );

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
