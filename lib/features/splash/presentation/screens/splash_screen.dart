import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../splash_motion.dart';
import '../splash_tokens.dart';
import '../widgets/splash_caption.dart';
import '../widgets/splash_road.dart';
import '../widgets/splash_title.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.nfcPlace, required this.onDone});

  final String? nfcPlace;
  final VoidCallback onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  var _started = false;
  var _still = false;
  var _done = false;

  int get _totalMs => widget.nfcPlace == null
      ? SplashTiming.defaultTotal
      : SplashTiming.nfcTotal;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finish();
      });
  }

  // Run the full timeline, or hold the final frame when motion is reduced
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _still = MediaQuery.disableAnimationsOf(context);
    _controller.duration = Duration(
      milliseconds: _still ? SplashTiming.reducedTotal : _totalMs,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    if (_done) return;
    _done = true;
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.nfcPlace;

    return Semantics(
      liveRegion: true,
      label: place == null ? 'SMAP 서경대 캠퍼스 길찾기' : '지금 계신 $place에서 시작할게요',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _finish,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final elapsedMs = _controller.value * _totalMs;
            final exit = _still
                ? 0.0
                : splashSegment(
                    elapsedMs,
                    _totalMs - SplashTiming.exit,
                    SplashTiming.exit,
                    Curves.easeIn,
                  );

            // Fade out while growing slightly to reveal the home behind
            return Opacity(
              opacity: 1 - exit,
              child: Transform.scale(
                scale: 1 + SplashMotion.exitGrow * exit,
                child: _SplashFrame(
                  elapsedMs: elapsedMs,
                  still: _still,
                  nfcPlace: place,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SplashFrame extends StatelessWidget {
  const _SplashFrame({
    required this.elapsedMs,
    required this.still,
    this.nfcPlace,
  });

  final double elapsedMs;
  final bool still;
  final String? nfcPlace;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: SplashColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final roadHeight =
              SplashLayout.roadHeight * width / SplashLayout.frameWidth;

          // Lift the road on short screens so it never covers the text
          final roadTop = math.min(
            0.0,
            constraints.maxHeight - SplashLayout.textReserve - roadHeight,
          );

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                top: roadTop,
                left: 0,
                width: width,
                height: roadHeight,
                child: SplashRoad(elapsedMs: elapsedMs, still: still),
              ),
              Positioned(
                left: SplashLayout.textInset,
                right: SplashLayout.textInset,
                bottom: SplashLayout.textBottom + bottomInset,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SplashTitle(elapsedMs: elapsedMs, still: still),
                    const SizedBox(height: SplashLayout.titleGap),
                    SplashCaption(
                      elapsedMs: elapsedMs,
                      still: still,
                      nfcPlace: nfcPlace,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
