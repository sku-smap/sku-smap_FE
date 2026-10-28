import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/explore/presentation/screens/explore_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/navigation/presentation/screens/navigation_screen.dart';
import '../features/report/presentation/screens/my_reports_screen.dart';
import '../features/report/presentation/screens/report_screen.dart';
import '../features/search/presentation/screens/search_screen.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const search = '/search';
  static const navigation = '/navigation';
  static const explore = '/explore';
  static const report = '/report';
  static const myReports = '/report/mine';

  static Uri _uri(String path, Map<String, String> query) =>
      Uri(path: path, queryParameters: query.isEmpty ? null : query);

  // ?pick=from|to, ?to= chosen destination, ?mode=voice, ?for=report
  static Uri searchUri({
    String? pick,
    String? to,
    bool voice = false,
    bool forReport = false,
  }) => _uri(search, {
    'pick': ?pick,
    'to': ?to,
    if (voice) 'mode': 'voice',
    if (forReport) 'for': 'report',
  });

  // ?from=&to=&mode=outdoor|elevator&indoor=1
  static Uri navigationUri({
    required String from,
    required String to,
    required String mode,
    bool indoor = false,
  }) => _uri(navigation, {
    'from': from,
    'to': to,
    'mode': mode,
    if (indoor) 'indoor': '1',
  });

  // ?building=&floor= from the building sheet
  static Uri exploreUri({String? building, String? floor}) =>
      _uri(explore, {'building': ?building, 'floor': ?floor});

  // ?node=&step=&kind= from the viewer
  static Uri reportUri({String? node, int? step, String? kind}) => _uri(
    report,
    {'node': ?node, if (step != null) 'step': '$step', 'kind': ?kind},
  );
}

// Navigation that does nothing where no router exists (widget tests)
abstract final class AppNav {
  static void push(BuildContext context, Uri uri) =>
      GoRouter.maybeOf(context)?.push(uri.toString());

  static Future<T?> pushForResult<T>(BuildContext context, Uri uri) =>
      GoRouter.maybeOf(context)?.push<T>(uri.toString()) ?? Future.value();

  // Swap the current screen so back skips it
  static void replace(BuildContext context, Uri uri) =>
      GoRouter.maybeOf(context)?.pushReplacement(uri.toString());

  // Pop, or go home when the screen was opened directly by a link
  static void close<T>(BuildContext context, [T? result]) {
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    if (router.canPop()) {
      router.pop(result);
    } else {
      router.go(AppRoutes.home);
    }
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final router = buildRouter();
  ref.onDispose(router.dispose);
  return router;
});

// App routes; tests pass a launch link as the initial location
GoRouter buildRouter({String initialLocation = AppRoutes.home}) {
  return GoRouter(
    initialLocation: initialLocation,
    // Unknown links open home instead of an error page
    onException: (_, _, router) => router.go(AppRoutes.home),
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) =>
            SearchScreen(query: state.uri.queryParameters),
      ),
      GoRoute(
        path: AppRoutes.navigation,
        builder: (context, state) =>
            NavigationScreen(query: state.uri.queryParameters),
      ),
      GoRoute(
        path: AppRoutes.explore,
        builder: (context, state) =>
            ExploreScreen(query: state.uri.queryParameters),
      ),
      GoRoute(
        path: AppRoutes.report,
        pageBuilder: (context, state) => ReportScreen.page(state),
      ),
      GoRoute(
        path: AppRoutes.myReports,
        builder: (context, state) => const MyReportsScreen(),
      ),
    ],
  );
}
