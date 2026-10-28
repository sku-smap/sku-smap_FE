import 'package:flutter/material.dart';

import '../../../campus/data/campus_directory.dart';
import '../../../campus/data/campus_models.dart';
import '../../../search/presentation/widgets/pick_map.dart';
import '../../data/report_models.dart';
import '../report_tokens.dart';

// Campus map that picks the nearest photo spot and marks the chosen one
class ReportMap extends StatelessWidget {
  const ReportMap({
    super.key,
    required this.level,
    required this.current,
    required this.onLevel,
    required this.onPick,
  });

  final MapLevel level;
  final String? current;
  final ValueChanged<MapLevel> onLevel;
  final ValueChanged<ReportSpot> onPick;

  @override
  Widget build(BuildContext context) {
    final spot = spotById[current];
    return Stack(
      children: [
        PickMap(
          level: level,
          onLevel: onLevel,
          onPick: (n) => onPick((node: n.id, label: n.title)),
        ),
        if (spot != null && spot.level == level)
          Positioned.fill(
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (context, size) => Stack(
                  children: [
                    Positioned(
                      left:
                          size.maxWidth * spot.x / 100 - ReportLayout.meDot / 2,
                      top:
                          size.maxHeight * spot.y / 100 -
                          ReportLayout.meDot / 2,
                      child: Container(
                        width: ReportLayout.meDot,
                        height: ReportLayout.meDot,
                        decoration: BoxDecoration(
                          color: ReportColors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ReportColors.surface,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
