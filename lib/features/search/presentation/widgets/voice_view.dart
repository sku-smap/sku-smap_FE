import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/search_assets.dart';
import '../../data/search_models.dart';
import '../../state/voice_controller.dart';
import '../search_tokens.dart';

const _examples = [
  '졸업증명서 떼려면 어디로 가요?',
  '전공책 어디서 사요?',
  '유담관이 어디에요?',
  '북악관에서 문예관 가는 길',
  '계단 말고 혜인관 가는 길',
];

class VoiceView extends ConsumerWidget {
  const VoiceView({
    super.key,
    required this.target,
    required this.onClose,
    required this.onResult,
  });

  final SearchTarget target;
  final VoidCallback onClose;
  final ValueChanged<VoiceOutcome> onResult;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = voiceControllerProvider(target);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    ref.listen(provider.select((s) => s.result), (_, result) {
      if (result != null) onResult(result);
    });

    final busy = state.busy != null;
    final candidates = state.candidates;
    final error = state.error;
    final padding = MediaQuery.paddingOf(context);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 0.5,
          colors: SearchColors.voiceStops,
          stops: [0, 0.25, 0.375, 0.5, 1],
          transform: _StretchToHeight(),
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              SearchLayout.voiceSide,
              padding.top + SearchLayout.voiceTop,
              SearchLayout.voiceSide,
              math.max(SearchLayout.voiceBottom, padding.bottom),
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Text(
                          state.hint,
                          textAlign: TextAlign.center,
                          style: SearchText.voiceHint,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          state.heard ?? '“유담관이 어디에요?”',
                          textAlign: TextAlign.center,
                          style: SearchText.voiceText,
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 22),
                          _ChipWrap(
                            caption: error,
                            captionStyle: SearchText.voiceSub,
                            children: [
                              if (error != VoiceController.micDenied)
                                _Chip(
                                  label: '다시 시도',
                                  light: true,
                                  onTap: controller.retry,
                                ),
                            ],
                          ),
                        ],
                        if (candidates != null) ...[
                          const SizedBox(height: 22),
                          _ChipWrap(
                            caption:
                                state.message ??
                                (candidates.isNotEmpty
                                    ? '혹시 이곳인가요?'
                                    : '등록된 장소를 찾지 못했어요. 건물 이름을 넣어 다시 말해 주세요.'),
                            captionStyle: SearchText.voiceSub,
                            children: [
                              for (final p in candidates)
                                _Chip(
                                  label: p.name,
                                  light: true,
                                  onTap: () => controller.choose(p),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                _MicButton(
                  listening: state.listening,
                  onTap: busy
                      ? null
                      : state.listening
                      ? controller.stop
                      : controller.start,
                ),
                const SizedBox(height: 26),
                _ChipWrap(
                  caption: '이렇게 말해 보세요',
                  captionStyle: SearchText.voiceCaption,
                  children: [
                    for (final e in _examples)
                      _Chip(
                        label: e,
                        onTap: busy ? null : () => controller.handle(e),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: padding.top + 12,
            right: 12,
            child: Semantics(
              button: true,
              label: '닫기',
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClose,
                child: SizedBox.square(
                  dimension: SearchLayout.iconButton,
                  child: Center(
                    child: SvgPicture.asset(
                      SearchAssets.close,
                      width: 22,
                      height: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Stretch the circular gradient into the screen-sized ellipse from Figma
class _StretchToHeight extends GradientTransform {
  const _StretchToHeight();

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final cx = bounds.center.dx;
    final cy = bounds.top;
    return Matrix4.identity()
      ..translateByDouble(cx, cy, 0, 1)
      ..scaleByDouble(1, bounds.height / bounds.width, 1, 1)
      ..translateByDouble(-cx, -cy, 0, 1);
  }
}

class _ChipWrap extends StatelessWidget {
  const _ChipWrap({
    required this.caption,
    required this.captionStyle,
    required this.children,
  });

  final String caption;
  final TextStyle captionStyle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: SearchLayout.chipGap,
      runSpacing: SearchLayout.chipGap,
      children: [
        SizedBox(
          width: double.infinity,
          child: Text(
            caption,
            textAlign: TextAlign.center,
            style: captionStyle,
          ),
        ),
        ...children,
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap, this.light = false});

  final String label;
  final VoidCallback? onTap;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: SearchLayout.chipHeight,
          padding: EdgeInsets.symmetric(horizontal: light ? 16 : 17),
          decoration: BoxDecoration(
            color: light ? SearchColors.surface : SearchColors.ghostChip,
            border: light ? Border.all(color: SearchColors.border) : null,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: light ? SearchText.chip : SearchText.ghostChip,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MicButton extends StatefulWidget {
  const _MicButton({required this.listening, required this.onTap});

  final bool listening;
  final VoidCallback? onTap;

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton>
    with SingleTickerProviderStateMixin {
  late final _ring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listening != widget.listening) _sync();
  }

  // Pulse the ring only while listening
  void _sync() {
    if (widget.listening) {
      _ring.repeat();
    } else {
      _ring
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.listening ? '그만 듣기' : '다시 말하기',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: SizedBox.square(
            dimension: SearchLayout.micSize,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (widget.listening)
                  AnimatedBuilder(
                    animation: _ring,
                    builder: (context, _) {
                      final t = Curves.easeOut.transform(_ring.value);
                      return Opacity(
                        opacity: 1 - t,
                        child: Transform.scale(
                          scale: 0.9 + 0.45 * t,
                          child: OverflowBox(
                            maxWidth: SearchLayout.micRing,
                            maxHeight: SearchLayout.micRing,
                            child: Container(
                              width: SearchLayout.micRing,
                              height: SearchLayout.micRing,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: SearchColors.surface,
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                Container(
                  width: SearchLayout.micSize,
                  height: SearchLayout.micSize,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: SearchColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: SearchShadows.mic,
                  ),
                  child: SvgPicture.asset(
                    SearchAssets.micBig,
                    width: 34,
                    height: 34,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
