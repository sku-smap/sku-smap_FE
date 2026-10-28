import 'package:flutter/widgets.dart';

import '../../../core/router.dart';
import '../../campus/data/campus_models.dart';

abstract final class ReportRoutes {
  static void close(BuildContext context) => AppNav.close(context);

  // Swap the sheet for the status list so back returns to where it opened
  static void mine(BuildContext context) =>
      AppNav.replace(context, Uri(path: AppRoutes.myReports));

  // Ask by voice and bring the heard place back as the report location
  static Future<CampusPlace?> voice(BuildContext context) =>
      AppNav.pushForResult<CampusPlace>(
        context,
        AppRoutes.searchUri(voice: true, forReport: true),
      );
}
