import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/pressable.dart';
import '../../data/report_models.dart';
import '../report_tokens.dart';

class ReportKindList extends StatelessWidget {
  const ReportKindList({
    super.key,
    required this.onKind,
    required this.onOpenMine,
  });

  final ValueChanged<ReportKind> onKind;
  final VoidCallback onOpenMine;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('무엇을 알려주실래요?', style: ReportText.sheetTitle),
        const SizedBox(height: 6),
        Text('보내주신 제보는 AI가 분류하고, 팀이 확인해 반영해요.', style: ReportText.sheetSub),
        const SizedBox(height: ReportLayout.fieldGap),
        for (final k in ReportKind.values) ...[
          if (k != ReportKind.values.first)
            const SizedBox(height: ReportLayout.kindGap),
          _KindButton(kind: k, onTap: () => onKind(k)),
        ],
        const SizedBox(height: 14),
        Center(
          child: Pressable(
            onTap: onOpenMine,
            builder: (context, pressed) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                '내 제보 현황 보기 ›',
                style: ReportText.mineLink.copyWith(
                  color: pressed ? ReportColors.pressed : null,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _KindButton extends StatelessWidget {
  const _KindButton({required this.kind, required this.onTap});

  final ReportKind kind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final base = kind == ReportKind.closure
        ? ReportColors.closure
        : ReportColors.field;
    return Pressable(
      onTap: onTap,
      builder: (context, pressed) => Container(
        padding: const EdgeInsets.all(ReportLayout.kindPadding),
        decoration: BoxDecoration(
          color: pressed ? ReportColors.blueSoft : base,
          borderRadius: BorderRadius.circular(ReportLayout.kindRadius),
        ),
        child: Row(
          children: [
            Container(
              width: ReportLayout.kindIcon,
              height: ReportLayout.kindIcon,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ReportColors.surface,
                borderRadius: BorderRadius.circular(
                  ReportLayout.kindIconRadius,
                ),
              ),
              child: ExcludeSemantics(
                child: Text(kind.icon, style: ReportText.kindIcon),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(kind.title, style: ReportText.kindTitle),
                  const SizedBox(height: 2),
                  Text(kind.sub, style: ReportText.kindSub),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
