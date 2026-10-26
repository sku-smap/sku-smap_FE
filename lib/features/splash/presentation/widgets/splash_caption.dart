import 'package:flutter/material.dart';

import '../splash_motion.dart';
import '../splash_tokens.dart';

class SplashCaption extends StatelessWidget {
  const SplashCaption({
    super.key,
    required this.elapsedMs,
    required this.still,
    this.nfcPlace,
  });

  final double elapsedMs;
  final bool still;
  final String? nfcPlace;

  @override
  Widget build(BuildContext context) {
    final progress = still
        ? 1.0
        : splashSegment(
            elapsedMs,
            SplashTiming.captionStart,
            SplashTiming.captionRise,
            Curves.easeOut,
          );
    final place = nfcPlace;

    return Transform.translate(
      offset: Offset(0, SplashMotion.captionRise * (1 - progress)),
      child: Opacity(
        opacity: progress,
        child: place == null ? const _Tagline() : _NfcMessage(place: place),
      ),
    );
  }
}

class _Tagline extends StatelessWidget {
  const _Tagline();

  @override
  Widget build(BuildContext context) {
    return const Opacity(
      opacity: SplashMotion.taglineOpacity,
      child: Text(
        '서경대 캠퍼스 길찾기',
        style: SplashTextStyles.tagline,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _NfcMessage extends StatelessWidget {
  const _NfcMessage({required this.place});

  final String place;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: SplashColors.chip,
            borderRadius: BorderRadius.circular(SplashLayout.chipRadius),
          ),
          child: const Padding(
            padding: SplashLayout.chipPadding,
            child: Text('NFC 태그', style: SplashTextStyles.chip),
          ),
        ),
        const SizedBox(height: SplashLayout.chipGap),
        Text('지금 계신 $place에서\n시작할게요', style: SplashTextStyles.nfcMessage),
      ],
    );
  }
}
