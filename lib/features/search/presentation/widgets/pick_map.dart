import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../campus/data/campus_directory.dart';
import '../../../campus/data/campus_models.dart';
import '../../../home/data/home_assets.dart';
import '../../../home/presentation/home_tokens.dart';
import '../../../home/presentation/widgets/home_segmented.dart';

class PickMap extends StatelessWidget {
  const PickMap({
    super.key,
    required this.level,
    required this.onLevel,
    required this.onPick,
  });

  final MapLevel level;
  final ValueChanged<MapLevel> onLevel;
  final ValueChanged<PanoSpot> onPick;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: HomeLayout.mapAspect,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(HomeLayout.stageRadius),
        child: ColoredBox(
          color: HomeColors.mapStage,
          child: LayoutBuilder(
            builder: (context, size) => Stack(
              children: [
                Positioned.fill(
                  child: Semantics(
                    button: true,
                    label: '지도에서 출발 지점 고르기',
                    child: GestureDetector(
                      // Tap picks the nearest photo spot on this level
                      onTapUp: (d) {
                        final spot = nearestSpot(
                          d.localPosition.dx / size.maxWidth * 100,
                          d.localPosition.dy / size.maxHeight * 100,
                          level,
                        );
                        if (spot != null) onPick(spot);
                      },
                      child: SvgPicture.asset(
                        level == MapLevel.ground
                            ? HomeAssets.mapGround
                            : HomeAssets.mapUnderground,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: HomeSegmented<MapLevel>(
                    options: const [
                      (MapLevel.ground, '지상'),
                      (MapLevel.underground, '지하'),
                    ],
                    selected: level,
                    onChanged: onLevel,
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
