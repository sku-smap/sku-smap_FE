import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router.dart';
import '../../../campus/state/nfc_link_provider.dart';
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
  late final RouteInformationProvider _links;

  // Links that arrive while the app runs (NFC tag, App Link)
  @override
  void initState() {
    super.initState();
    _links = ref.read(routerProvider).routeInformationProvider;
    _links.addListener(_onLink);
  }

  void _onLink() =>
      ref.read(nfcLinkProvider.notifier).receive(_links.value.uri);

  @override
  void dispose() {
    _links.removeListener(_onLink);
    super.dispose();
  }

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
