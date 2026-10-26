import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/campus_buildings_mock.dart';
import '../../data/campus_facilities_mock.dart';
import '../../data/campus_models.dart';
import '../../data/home_assets.dart';
import '../../data/home_mock.dart';
import '../home_tokens.dart';
import 'home_segmented.dart';

class CampusMapCard extends StatelessWidget {
  const CampusMapCard({
    super.key,
    required this.level,
    required this.facility,
    required this.onLevel,
    required this.onFacility,
    required this.onBuilding,
    required this.onFacilitySpot,
  });

  final MapLevel level;
  final FacilityCategory? facility;
  final ValueChanged<MapLevel> onLevel;
  final ValueChanged<FacilityCategory?> onFacility;
  final ValueChanged<CampusBuilding> onBuilding;
  final ValueChanged<FacilitySpot> onFacilitySpot;

  @override
  Widget build(BuildContext context) {
    final category = facility;
    final spots = category == null
        ? const <FacilitySpot>[]
        : campusFacilities.where((s) => s.category == category).toList();
    final hiddenOther = spots.where((s) => s.level != level).length;
    final otherLevel = level == MapLevel.ground ? '지하' : '지상';
    final sub = category == null ? '건물을 눌러보세요' : '편의시설 핀을 눌러보세요';

    return Container(
      padding: const EdgeInsets.only(top: 19.25, bottom: 20),
      decoration: BoxDecoration(
        color: HomeColors.surface,
        borderRadius: BorderRadius.circular(HomeLayout.cardRadius),
        boxShadow: HomeShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('캠퍼스 지도', style: HomeText.cardTitle),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sub,
                    maxLines: 1,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: HomeText.tracked(HomeText.cardSub, sub),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12.75),
          _FacilityChips(selected: category, onSelect: onFacility),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _MapStage(
              level: level,
              spots: category == null ? null : spots,
              onLevel: onLevel,
              onBuilding: onBuilding,
              onFacilitySpot: onFacilitySpot,
            ),
          ),
          if (category != null && hiddenOther > 0)
            _MapNote('$otherLevel에 $hiddenOther곳 더 있어요 — 오른쪽 위 $otherLevel 버튼'),
          if (category != null) const _MapNote('핀을 누르면 그곳으로 길찾기를 시작해요.'),
          if (category == null && level == MapLevel.underground)
            const _MapNote(undergroundLinkNote, letterSpacing: -1.1407),
        ],
      ),
    );
  }
}

class _FacilityChips extends StatelessWidget {
  const _FacilityChips({required this.selected, required this.onSelect});

  final FacilityCategory? selected;
  final ValueChanged<FacilityCategory?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: HomeLayout.facChipHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _FacilityChip(
            label: '건물',
            icon: selected == null
                ? HomeAssets.buildingWhite
                : HomeAssets.buildingNavy,
            selected: selected == null,
            onTap: () => onSelect(null),
          ),
          for (final c in FacilityCategory.values) ...[
            const SizedBox(width: HomeLayout.facChipGap),
            _FacilityChip(
              label: c.label,
              icon: selected == c
                  ? HomeAssets.facilityWhite(c)
                  : HomeAssets.facilityNavy(c),
              selected: selected == c,
              onTap: () => onSelect(c),
            ),
          ],
        ],
      ),
    );
  }
}

class _FacilityChip extends StatelessWidget {
  const _FacilityChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: HomeLayout.facChipHeight,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: selected ? HomeColors.blue : HomeColors.surface,
            border: Border.all(
              color: selected ? HomeColors.blue : HomeColors.border,
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(icon, width: 14, height: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: HomeText.tracked(
                  HomeText.facChip,
                  label,
                ).copyWith(color: selected ? HomeColors.surface : null),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapStage extends StatelessWidget {
  const _MapStage({
    required this.level,
    required this.spots,
    required this.onLevel,
    required this.onBuilding,
    required this.onFacilitySpot,
  });

  final MapLevel level;
  final List<FacilitySpot>? spots;
  final ValueChanged<MapLevel> onLevel;
  final ValueChanged<CampusBuilding> onBuilding;
  final ValueChanged<FacilitySpot> onFacilitySpot;

  @override
  Widget build(BuildContext context) {
    final facilitySpots = spots;
    return AspectRatio(
      aspectRatio: HomeLayout.mapAspect,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(HomeLayout.stageRadius),
        child: ColoredBox(
          color: HomeColors.mapStage,
          child: LayoutBuilder(
            builder: (context, size) {
              final w = size.maxWidth;
              final h = size.maxHeight;
              return Stack(
                children: [
                  Positioned.fill(
                    child: SvgPicture.asset(
                      level == MapLevel.ground
                          ? HomeAssets.mapGround
                          : HomeAssets.mapUnderground,
                      fit: BoxFit.fill,
                    ),
                  ),
                  if (facilitySpots == null)
                    for (final b in campusBuildings)
                      _PinAt(
                        x: b.mapX / 100 * w,
                        y: b.mapY / 100 * h,
                        child: MapPin(
                          label: b.name,
                          icon: HomeAssets.buildingWhite,
                          onTap: () => onBuilding(b),
                        ),
                      )
                  else
                    for (final s in facilitySpots.where(
                      (s) => s.level == level,
                    ))
                      _PinAt(
                        x: s.mapX / 100 * w,
                        y: s.mapY / 100 * h,
                        child: MapPin(
                          label: s.pinLabel,
                          icon: HomeAssets.facilityWhite(s.category),
                          letterSpacing: -1.1846,
                          onTap: () => onFacilitySpot(s),
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
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PinAt extends StatelessWidget {
  const _PinAt({required this.x, required this.y, required this.child});

  final double x;
  final double y;
  final Widget child;

  // Anchor the pin's bottom center on the map point
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x,
      top: y,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -1),
        child: child,
      ),
    );
  }
}

class MapPin extends StatelessWidget {
  const MapPin({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.letterSpacing,
  });

  final String label;
  final String icon;
  final VoidCallback onTap;
  final double? letterSpacing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: HomeLayout.pinHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: HomeColors.navy,
            borderRadius: BorderRadius.circular(8),
            boxShadow: HomeShadows.pin,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(icon, width: 14, height: 14),
              const SizedBox(width: 3),
              Text(
                label,
                maxLines: 1,
                style: HomeText.pin.copyWith(letterSpacing: letterSpacing),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapNote extends StatelessWidget {
  const _MapNote(this.text, {this.letterSpacing});

  final String text;
  final double? letterSpacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Text(
        text,
        style: HomeText.mapNote.copyWith(letterSpacing: letterSpacing),
      ),
    );
  }
}
