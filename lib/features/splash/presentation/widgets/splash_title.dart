import 'package:flutter/material.dart';

import '../splash_motion.dart';
import '../splash_tokens.dart';

class SplashTitle extends StatelessWidget {
  const SplashTitle({super.key, required this.elapsedMs, required this.still});

  static const _letters = ['s', 'm', 'a', 'p'];

  final double elapsedMs;
  final bool still;

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: SplashLayout.titleSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < _letters.length; i++)
            Positioned(
              left: SplashLayout.letterOffsets[i],
              top: 0,
              child: _Letter(
                letter: _letters[i],
                progress: still
                    ? 1
                    : splashSegment(
                        elapsedMs,
                        SplashTiming.letterStart +
                            SplashTiming.letterStagger * i,
                        SplashTiming.letterPop,
                        SplashMotion.letterCurve,
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Letter extends StatelessWidget {
  const _Letter({required this.letter, required this.progress});

  final String letter;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final rest = 1 - progress;

    // Bounce each letter up from below with a slight tilt
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.translationValues(0, SplashMotion.letterRise * rest, 0)
        ..rotateZ(SplashMotion.letterTilt * rest),
      child: Opacity(
        opacity: progress.clamp(0.0, 1.0),
        child: Text(
          letter,
          style: SplashTextStyles.title,
          textScaler: TextScaler.noScaling,
        ),
      ),
    );
  }
}
