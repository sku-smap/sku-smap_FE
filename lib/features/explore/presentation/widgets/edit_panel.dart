import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/pressable.dart';
import '../../../navigation/presentation/navigation_tokens.dart';
import '../explore_tokens.dart';

typedef EditLink = ({String to, String label, double yaw});

// Team-only panel: pick a link, then tap where it shows in the photo
class EditPanel extends StatelessWidget {
  const EditPanel({
    super.key,
    required this.links,
    required this.selected,
    required this.fixes,
    required this.onSelect,
    required this.onCopy,
  });

  final List<EditLink> links;
  final String? selected;
  final int fixes;
  final ValueChanged<String> onSelect;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ExploreLayout.editWidth,
      padding: const EdgeInsets.all(ExploreLayout.editPadding),
      decoration: BoxDecoration(
        color: ExploreColors.editBg,
        borderRadius: BorderRadius.circular(ExploreLayout.editRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '방향 보정 모드 — 길을 고른 뒤, 사진에서 그 길이 보이는 곳을 탭하세요.',
            style: ExploreText.editHint,
          ),
          const SizedBox(height: ExploreLayout.editGap),
          Wrap(
            spacing: ExploreLayout.editChipGap,
            runSpacing: ExploreLayout.editChipGap,
            children: [
              for (final l in links)
                _LinkChip(
                  label: '${l.label} ${l.yaw.round()}°',
                  selected: l.to == selected,
                  onTap: () => onSelect(l.to),
                ),
            ],
          ),
          const SizedBox(height: ExploreLayout.editGap),
          Pressable(
            onTap: onCopy,
            label: '보정값 복사',
            builder: (context, pressed) => Container(
              height: ExploreLayout.editButtonHeight,
              padding: const EdgeInsets.symmetric(
                horizontal: ExploreLayout.editSide,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: NavColors.navy,
                borderRadius: BorderRadius.circular(
                  ExploreLayout.editButtonRadius,
                ),
              ),
              child: Text('보정값 복사 ($fixes)', style: ExploreText.editButton),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
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
          height: ExploreLayout.editChipHeight,
          padding: const EdgeInsets.symmetric(
            horizontal: ExploreLayout.editSide,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? NavColors.blue : NavColors.surface,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ExploreText.editChip.copyWith(
              color: selected ? NavColors.surface : null,
            ),
          ),
        ),
      ),
    );
  }
}
