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
}

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.home,
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
  ref.onDispose(router.dispose);
  return router;
});
