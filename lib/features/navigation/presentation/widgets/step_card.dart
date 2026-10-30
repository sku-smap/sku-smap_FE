import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../home/presentation/widgets/pressable.dart';
import '../../data/navigation_assets.dart';
import '../../state/navigation_controller.dart';
import '../navigation_tokens.dart';
import 'marquee_text.dart';

class StepCard extends StatelessWidget {
  const StepCard({
    super.key,
    required this.state,
    required this.onToggleMute,
    required this.onShowSteps,
    required this.onShare,
    required this.onNavigate,
    required this.onExit,
    required this.onReport,
    required this.onPraise,
  });

  final NavigationState state;
  final VoidCallback onToggleMute;
  final VoidCallback onShowSteps;
  final VoidCallback onShare;
  final ValueChanged<String> onNavigate;
  final VoidCallback onExit;
  final void Function({String? kind}) onReport;
  final VoidCallback onPraise;

  @override
  Widget build(BuildContext context) {
    final route = state.route!;
    final step = state.stepIdx;
    final arrived = state.arrived;
    final next = state.next;
    final note = route.legAt(step)?.note;

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: NavColors.surface,
          borderRadius: BorderRadius.circular(NavLayout.cardRadius),
          boxShadow: NavShadows.card,
        ),
        // Drawn over the card so the arrival border does not change its size
        foregroundDecoration: arrived
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(NavLayout.cardRadius),
                border: Border.all(color: NavColors.blue, width: 3),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: arrived ? NavColors.blue : NavColors.blueSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    arrived ? '도착' : '${step + 1} / ${route.last}단계',
                    style: arrived
                        ? NavText.stepCount.copyWith(color: NavColors.surface)
                        : NavText.stepCount,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '→ ${route.to.label}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: NavText.stepDest,
                  ),
                ),
                const SizedBox(width: 8),
                _Tool(
                  icon: state.muted
                      ? NavigationAssets.soundOff
                      : NavigationAssets.soundOn,
                  label: state.muted ? '음성 안내 켜기' : '음성 안내 끄기',
                  onTap: onToggleMute,
                ),
                _Tool(
                  icon: NavigationAssets.list,
                  label: '전체 단계 보기',
                  onTap: onShowSteps,
                ),
                Transform.translate(
                  offset: const Offset(8, 0),
                  child: _Tool(
                    icon: NavigationAssets.share,
                    label: '경로 공유',
                    onTap: onShare,
                  ),
                ),
              ],
            ),
            Container(
              height: 4,
              margin: const EdgeInsets.fromLTRB(0, 10, 0, 12),
              decoration: BoxDecoration(
                color: NavColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
              alignment: Alignment.centerLeft,
              child: AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 300),
                widthFactor: route.last == 0
                    ? 1
                    : (step < 0 ? 0 : step) / route.last,
                child: Container(
                  decoration: BoxDecoration(
                    color: NavColors.blue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // Every line keeps one row's height so the card never resizes
            SizedBox(
              height: NavLayout.stepTextLine,
              child: MarqueeText(
                arrived ? '${route.to.label}에 도착했어요' : state.text,
                style: NavText.stepText,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: NavLayout.stepNoteLine + 8 + NavLayout.stepHintLine,
              child: arrived
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: _Rate(
                        praised: state.praised,
                        onPraise: onPraise,
                        onConfused: () => onReport(kind: 'issue'),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: NavLayout.stepNoteLine,
                          child: note == null
                              ? null
                              : MarqueeText(note, style: NavText.stepNote),
                        ),
                        const SizedBox(height: 8),
                        const SizedBox(
                          height: NavLayout.stepHintLine,
                          child: _Hint(),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _Button(
                    label: '이전',
                    onTap: step > 0
                        ? () => onNavigate(route.path[step - 1])
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _Button(
                    label: arrived ? '안내 종료' : '다음',
                    primary: true,
                    onTap: arrived
                        ? onExit
                        : next == null
                        ? null
                        : () => onNavigate(next),
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  container: true,
                  child: Pressable(
                    onTap: () => onReport(),
                    label: '제보하기 (헷갈려요·못 가요)',
                    builder: (context, pressed) => Container(
                      width: NavLayout.buttonHeight,
                      height: NavLayout.buttonHeight,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: pressed ? NavColors.field : null,
                        border: Border.all(color: NavColors.line, width: 1.5),
                        borderRadius: BorderRadius.circular(
                          NavLayout.buttonRadius,
                        ),
                      ),
                      child: SvgPicture.asset(
                        NavigationAssets.flag,
                        width: 22,
                        height: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool({required this.icon, required this.label, required this.onTap});

  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: Pressable(
        onTap: onTap,
        label: label,
        builder: (context, pressed) => Container(
          width: NavLayout.toolButton,
          height: NavLayout.toolButton,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: pressed ? NavColors.glassOff : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SvgPicture.asset(icon, width: 22, height: 22),
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint();

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      TextSpan(
        text: '사진 속 ',
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: NavColors.blue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: NavColors.blue.withValues(alpha: 0.25),
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),
          ),
          const TextSpan(text: ' 파랗게 빛나는 화살표를 누르거나 ‘다음’을 누르세요'),
        ],
      ),
      style: NavText.stepHint,
    );
  }
}

class _Rate extends StatelessWidget {
  const _Rate({
    required this.praised,
    required this.onPraise,
    required this.onConfused,
  });

  final bool praised;
  final VoidCallback onPraise;
  final VoidCallback onConfused;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            '안내가 정확했나요?',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: NavText.stepHint,
          ),
        ),
        const SizedBox(width: 6),
        if (praised)
          Text('고마워요! 👍', style: NavText.rateDone)
        else ...[
          _RateChip(label: '👍 정확했어요', onTap: onPraise),
          const SizedBox(width: 6),
          _RateChip(label: '헷갈렸어요', onTap: onConfused),
        ],
      ],
    );
  }
}

class _RateChip extends StatelessWidget {
  const _RateChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      builder: (context, pressed) => Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: pressed ? NavColors.field : NavColors.surface,
          border: Border.all(color: NavColors.line),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: NavText.rateChip),
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      builder: (context, pressed) => Opacity(
        opacity: onTap == null ? 0.4 : 1,
        child: Container(
          height: NavLayout.buttonHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: primary
                ? (pressed ? NavColors.pressed : NavColors.blue)
                : (pressed ? NavColors.field : NavColors.surface),
            border: primary
                ? null
                : Border.all(color: NavColors.line, width: 1.5),
            borderRadius: BorderRadius.circular(NavLayout.buttonRadius),
          ),
          child: Text(
            label,
            style: primary
                ? NavText.button.copyWith(color: NavColors.surface)
                : NavText.button,
          ),
        ),
      ),
    );
  }
}
