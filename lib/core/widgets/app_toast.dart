import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../theme.dart';

const appToastDuration = Duration(milliseconds: 3200);

abstract final class AppToastTokens {
  static const background = AppColors.navy;
  static const inset = 16.0;
  static const radius = 14.0;
  static const padding = EdgeInsets.symmetric(horizontal: 18, vertical: 12);
  static const shadow = [
    BoxShadow(color: Color(0x5900156A), offset: Offset(0, 8), blurRadius: 24),
  ];
  static const text = TextStyle(
    fontFamily: appFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation.weight(600)],
    height: 19.6 / 14,
    color: Colors.white,
  );
}

// Top notice shared by every screen; null hides it
class AppToast extends StatelessWidget {
  const AppToast({super.key, required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message;
    final top = math.max(
      AppToastTokens.inset,
      MediaQuery.paddingOf(context).top,
    );
    return Positioned(
      top: top,
      left: AppToastTokens.inset,
      right: AppToastTokens.inset,
      child: IgnorePointer(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: text == null
              ? const SizedBox.shrink()
              : Center(
                  key: ValueKey(text),
                  child: Semantics(
                    liveRegion: true,
                    child: Container(
                      padding: AppToastTokens.padding,
                      decoration: BoxDecoration(
                        color: AppToastTokens.background,
                        borderRadius: BorderRadius.circular(
                          AppToastTokens.radius,
                        ),
                        boxShadow: AppToastTokens.shadow,
                      ),
                      child: Text(
                        text,
                        textAlign: TextAlign.center,
                        style: AppToastTokens.text,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

// Toast that outlives the closing screen, on the screen underneath
void showOverlayToast(OverlayState overlay, String message) {
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ToastHost(message: message, onDone: entry.remove),
  );
  overlay.insert(entry);
}

class _ToastHost extends StatefulWidget {
  const _ToastHost({required this.message, required this.onDone});

  final String message;
  final VoidCallback onDone;

  @override
  State<_ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends State<_ToastHost> {
  String? _message;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _message = widget.message;
    _timer = Timer(appToastDuration, () {
      setState(() => _message = null);
      _timer = Timer(const Duration(milliseconds: 250), widget.onDone);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The overlay sits outside any Scaffold, so give the text a Material
    return Material(
      type: MaterialType.transparency,
      child: Stack(children: [AppToast(message: _message)]),
    );
  }
}
