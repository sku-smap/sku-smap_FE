import 'package:flutter/widgets.dart';

import '../../../core/router.dart';

abstract final class ExploreRoutes {
  // Replace the viewer with destination search so back returns home
  static void pickTo(BuildContext context) =>
      AppNav.replace(context, AppRoutes.searchUri(pick: 'to'));
}
