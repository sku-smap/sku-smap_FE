import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/splash_entry_provider.dart';
import '../screens/splash_screen.dart';

class SplashGate extends ConsumerStatefulWidget {
  const SplashGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends ConsumerState<SplashGate> {
  var _visible = true;

  // Keep the app mounted underneath so the splash fades into home
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_visible)
          Positioned.fill(
            child: SplashScreen(
              nfcPlace: ref.watch(splashNfcPlaceProvider),
              onDone: () => setState(() => _visible = false),
            ),
          ),
      ],
    );
  }
}
