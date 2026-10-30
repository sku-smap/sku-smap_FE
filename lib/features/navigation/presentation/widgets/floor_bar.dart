import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/navigation_models.dart';
import '../navigation_tokens.dart';
import 'glass_box.dart';

class FloorBar extends StatelessWidget {
  const FloorBar({
    super.key,
    required this.building,
    required this.current,
    required this.floors,
    required this.onFloor,
  });

  static const _button = Size(42, 32);
  static const _gap = 3.0;

  final String building;
  final String? current;
  final List<FloorStop> floors;
  final ValueChanged<String> onFloor;

  @override
  Widget build(BuildContext context) {
    final top = floors.reversed.toList();
    final currentAt = top.indexWhere((f) => f.floor == current);
    final shown = math.min(top.length, NavLayout.floorBarVisible);
    final pitch = _button.height + _gap;
    return GlassBox(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(5, 6, 5, 6),
      child: SizedBox(
        width: _button.width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              building,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: NavText.floorBarName,
            ),
            const SizedBox(height: 4),
            // At most five floors show; the rest scroll, current one centered
            Flexible(
              child: SizedBox(
                height: shown * pitch - _gap,
                child: SingleChildScrollView(
                  controller: ScrollController(
                    initialScrollOffset: math.max(
                      0,
                      (currentAt - NavLayout.floorBarVisible ~/ 2) * pitch,
                    ),
                  ),
                  child: Column(
                    children: [
                      for (final (i, f) in top.indexed) ...[
                        if (i > 0) const SizedBox(height: _gap),
                        _FloorButton(
                          stop: f,
                          current: f.floor == current,
                          onTap: () => onFloor(f.node),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloorButton extends StatelessWidget {
  const _FloorButton({
    required this.stop,
    required this.current,
    required this.onTap,
  });

  final FloorStop stop;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: current,
      label: '${stop.floor}로 이동',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: current ? null : onTap,
        child: Container(
          width: FloorBar._button.width,
          height: FloorBar._button.height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: current ? NavColors.blue : NavColors.floorButton,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            stop.label,
            style: current
                ? NavText.floorButton.copyWith(color: NavColors.surface)
                : NavText.floorButton,
          ),
        ),
      ),
    );
  }
}
