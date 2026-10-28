import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../campus/data/campus_models.dart';
import '../../data/home_assets.dart';
import '../home_tokens.dart';
import 'home_sheet.dart';
import 'pressable.dart';

class BuildingSheet extends StatelessWidget {
  const BuildingSheet({
    super.key,
    required this.building,
    required this.onExplore,
    required this.onSetFrom,
    required this.onSetTo,
  });

  final CampusBuilding building;
  final void Function({String? floor}) onExplore;
  final ValueChanged<CampusPlace> onSetFrom;
  final ValueChanged<CampusPlace> onSetTo;

  @override
  Widget build(BuildContext context) {
    final b = building;
    final photo = b.photo;
    final departments = b.departments;

    // Close the sheet before running the chosen action
    void then(VoidCallback action) {
      Navigator.of(context).pop();
      action();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (photo != null) ...[
          _BuildingPhoto(asset: photo),
          const SizedBox(height: 13.9),
        ],
        Text(b.name, style: HomeText.sheetTitle),
        if (departments != null) ...[
          const SizedBox(height: 2.95),
          Text(departments, style: HomeText.sheetDepts),
        ],
        const SizedBox(height: 6.6),
        Text(b.description, style: HomeText.sheetBody),
        if (b.floors.length > 1) ...[
          const SizedBox(height: 16.75),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: b.floors.length,
              separatorBuilder: (_, _) => const SizedBox(width: 4),
              itemBuilder: (context, i) => _FloorButton(
                label: b.floors[i],
                onTap: () => then(() => onExplore(floor: b.floors[i])),
              ),
            ),
          ),
        ],
        if (b.places.isNotEmpty) ...[
          const SizedBox(height: 16),
          SheetPlaceChips(
            places: b.places,
            onTap: (p) => then(() => onSetTo(p)),
          ),
        ],
        if (b.roomCount > 0) ...[
          const SizedBox(height: 5.75),
          Text(
            '교수 연구실·강의실 ${b.roomCount}곳 — 검색창에 호수나 이름을 입력하세요',
            style: HomeText.sheetBody,
          ),
        ],
        const SizedBox(height: 22.75),
        Row(
          children: [
            _SheetButton(
              label: '거리뷰',
              icon: HomeAssets.eye,
              padding: 11,
              onTap: () => then(onExplore),
            ),
            const SizedBox(width: 8),
            _SheetButton(
              label: '여기서 출발',
              padding: 20.8,
              onTap: () => then(() => onSetFrom(b.main)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SheetButton(
                label: '여기로 길찾기',
                primary: true,
                onTap: () => then(() => onSetTo(b.main)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BuildingPhoto extends StatelessWidget {
  const _BuildingPhoto({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: HomeLayout.photoHeight,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(asset, fit: BoxFit.cover),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 22,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: HomeColors.caption,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('사진: 서경대학교 캠퍼스맵', style: HomeText.photoCaption),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloorButton extends StatelessWidget {
  const _FloorButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label 거리뷰',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 40),
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: HomeColors.blueSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label, style: HomeText.sheetFloor),
        ),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.padding = 0,
    this.primary = false,
  });

  final String label;
  final VoidCallback onTap;
  final String? icon;
  final double padding;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final asset = icon;
    return Pressable(
      onTap: onTap,
      label: label,
      builder: (context, pressed) => Container(
        height: 48,
        padding: EdgeInsets.symmetric(horizontal: padding),
        decoration: BoxDecoration(
          color: primary ? HomeColors.blue : HomeColors.surface,
          border: primary ? null : Border.all(color: HomeColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (asset != null) ...[
              SvgPicture.asset(asset, width: 18, height: 18),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: HomeText.tracked(
                  HomeText.sheetAction,
                  label,
                ).copyWith(color: primary ? HomeColors.surface : null),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
