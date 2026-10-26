import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home/presentation/screens/home_screen.dart';
import 'widgets/placeholder_page.dart';

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
        builder: (context, state) => const PlaceholderPage(title: '검색'),
      ),
      GoRoute(
        path: AppRoutes.navigation,
        builder: (context, state) => const PlaceholderPage(title: '길안내'),
      ),
      GoRoute(
        path: AppRoutes.explore,
        builder: (context, state) => const PlaceholderPage(title: '둘러보기'),
      ),
      GoRoute(
        path: AppRoutes.report,
        builder: (context, state) => const PlaceholderPage(title: '제보'),
      ),
      GoRoute(
        path: AppRoutes.myReports,
        builder: (context, state) => const PlaceholderPage(title: '내 제보 현황'),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
