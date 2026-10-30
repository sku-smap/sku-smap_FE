import 'package:flutter/material.dart';

// One line of text that scrolls like a sign board when it does not fit;
// still when the system asks for reduced motion
class MarqueeText extends StatefulWidget {
  const MarqueeText(this.text, {super.key, required this.style});

  static const velocity = 40.0;
  static const gap = 48.0;
  static const pause = Duration(milliseconds: 1200);

  final String text;
  final TextStyle style;

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this);
  double? _travel;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Start or stop the loop when the overflow distance changes
  void _run(double? travel) {
    if (travel == _travel) return;
    _travel = travel;
    if (travel == null) {
      _controller.stop();
      return;
    }
    final move = travel / MarqueeText.velocity * 1000;
    _controller
      ..value = 0
      ..duration = MarqueeText.pause + Duration(milliseconds: move.round())
      ..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: 1,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();
        final width = painter.width;
        painter.dispose();
        final still =
            width <= box.maxWidth || MediaQuery.disableAnimationsOf(context);
        final travel = still ? null : width + MarqueeText.gap;
        if (travel != _travel) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _run(travel);
          });
        }
        final line = Text(
          widget.text,
          maxLines: 1,
          softWrap: false,
          overflow: still ? TextOverflow.ellipsis : TextOverflow.visible,
          style: widget.style,
        );
        if (still) return line;
        return Semantics(
          label: widget.text,
          excludeSemantics: true,
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final total = _controller.duration?.inMilliseconds;
                if (total == null) return child!;
                final wait = MarqueeText.pause.inMilliseconds;
                final t = _controller.value * total;
                final shift = t <= wait ? 0.0 : (t - wait) / (total - wait);
                return Transform.translate(
                  offset: Offset(-shift * (width + MarqueeText.gap), 0),
                  child: child,
                );
              },
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                maxWidth: double.infinity,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    line,
                    const SizedBox(width: MarqueeText.gap),
                    // The trailing copy fills the gap while the loop wraps
                    RichText(
                      text: TextSpan(text: widget.text, style: widget.style),
                      maxLines: 1,
                      textScaler: MediaQuery.textScalerOf(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
