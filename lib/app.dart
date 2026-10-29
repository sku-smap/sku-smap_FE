import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme.dart';
import 'features/splash/presentation/widgets/splash_gate.dart';

class SmapApp extends ConsumerWidget {
  const SmapApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'SMAP',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
      theme: buildTheme(),
      builder: (context, child) => SplashGate(child: child!),
    );
  }
}
