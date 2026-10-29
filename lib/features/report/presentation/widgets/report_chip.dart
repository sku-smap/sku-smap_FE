import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/pressable.dart';
import '../report_tokens.dart';

enum ChipTone { plain, primary, ghost }

class ReportChip extends StatelessWidget {
  const ReportChip({
    super.key,
    required this.label,
    required this.onTap,
    this.tone = ChipTone.plain,
    this.small = false,
    this.selected,
  });

  final String label;
  final VoidCallback onTap;
  final ChipTone tone;
  final bool small;
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg) = switch (tone) {
      ChipTone.plain => (
        ReportColors.surface,
        ReportColors.line,
        ReportColors.navy,
      ),
      ChipTone.primary => (
        ReportColors.blue,
        ReportColors.blue,
        ReportColors.surface,
      ),
      ChipTone.ghost => (
        ReportColors.blueSoft,
        ReportColors.blueSoft,
        ReportColors.blue,
      ),
    };
    final style = small ? ReportText.smallChip : ReportText.chip;
    return Semantics(
      selected: selected,
      child: Pressable(
        onTap: onTap,
        builder: (context, pressed) => Container(
          height: small
              ? ReportLayout.smallChipHeight
              : ReportLayout.chipHeight,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: pressed ? ReportColors.blue : border),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, maxLines: 1, style: style.copyWith(color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

// Selectable chips: one pick (types) or several (course tags)
class ReportChipWrap extends StatelessWidget {
  const ReportChipWrap({
    super.key,
    required this.options,
    required this.isOn,
    required this.onTap,
  });

  final List<String> options;
  final bool Function(String) isOn;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: ReportLayout.chipGap,
      runSpacing: ReportLayout.chipGap,
      children: [
        for (final o in options)
          ReportChip(
            label: o,
            small: true,
            selected: isOn(o),
            tone: isOn(o) ? ChipTone.primary : ChipTone.plain,
            onTap: () => onTap(o),
          ),
      ],
    );
  }
}
