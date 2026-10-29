import 'package:flutter/material.dart';

import '../../../campus/data/campus_directory.dart';
import '../../data/report_models.dart';
import '../report_tokens.dart';

const _steps = [
  ReportStatus.received,
  ReportStatus.checking,
  ReportStatus.applied,
];

String _title(String? node) => spotById[node]?.title ?? node ?? '?';

// Where the report points: a course, no location, or one spot
String reportWhere(MyReport r) => switch (r) {
  MyReport(kind: ReportKind.course) =>
    '${_title(r.fromNode)} → ${_title(r.toNode)}',
  MyReport(node: reportHomeNode) => '위치 없이 보낸 제보',
  _ => _title(r.node),
};

class MineCard extends StatelessWidget {
  const MineCard({super.key, required this.report});

  final MyReport report;

  @override
  Widget build(BuildContext context) {
    final r = report;
    final applied = r.status == ReportStatus.applied;
    final detail = [r.type, r.memo].whereType<String>().join(' — ');
    return Container(
      padding: const EdgeInsets.all(ReportLayout.cardPadding),
      decoration: BoxDecoration(
        color: ReportColors.surface,
        borderRadius: BorderRadius.circular(ReportLayout.cardRadius),
        boxShadow: ReportShadows.card,
      ),
      foregroundDecoration: applied
          ? BoxDecoration(
              border: Border.all(color: ReportColors.blue, width: 2),
              borderRadius: BorderRadius.circular(ReportLayout.cardRadius),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: Text(r.kind.icon, style: ReportText.cardIcon),
              ),
              const SizedBox(width: 6),
              Expanded(child: Text(r.kind.title, style: ReportText.cardTitle)),
              const SizedBox(width: 6),
              Text(
                '${r.createdAt.month}월 ${r.createdAt.day}일',
                style: ReportText.cardDate,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(reportWhere(r), style: ReportText.cardWhere),
          if (detail.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(detail, style: ReportText.cardMemo),
          ],
          if (r.local) ...[
            const SizedBox(height: 10),
            Text('이 기기에만 저장됨 · 서버가 연결되면 다시 보내 주세요', style: ReportText.local),
          ] else if (r.status == ReportStatus.rejected) ...[
            const SizedBox(height: 10),
            Text('이번엔 반영하지 못했어요. 알려줘서 고마워요!', style: ReportText.rejected),
          ] else ...[
            const SizedBox(height: 12),
            _Steps(status: r.status),
          ],
          if (applied) ...[
            const SizedBox(height: 10),
            Text('🎉 반영됐어요. 덕분에 길안내가 더 정확해졌어요!', style: ReportText.thanks),
          ],
        ],
      ),
    );
  }
}

// 받음 → 확인 중 → 반영됨, done steps in blue
class _Steps extends StatelessWidget {
  const _Steps({required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final done = _steps.indexOf(status);
    return Semantics(
      container: true,
      label: '처리 상태: ${status.label}',
      excludeSemantics: true,
      child: Column(
        children: [
          SizedBox(
            height: ReportLayout.stepDot,
            width: double.infinity,
            child: CustomPaint(painter: _StepsPainter(done: done)),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final (i, s) in _steps.indexed)
                Expanded(
                  child: Text(
                    s.label,
                    textAlign: TextAlign.center,
                    style: i <= done
                        ? ReportText.step.copyWith(color: ReportColors.blue)
                        : ReportText.step,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepsPainter extends CustomPainter {
  const _StepsPainter({required this.done});

  final int done;

  @override
  void paint(Canvas canvas, Size size) {
    final third = size.width / _steps.length;
    final y = size.height / 2;
    Color color(int i) => i <= done ? ReportColors.blue : ReportColors.line;
    for (var i = 1; i < _steps.length; i++) {
      canvas.drawRect(
        Rect.fromLTRB(
          third * (i - 0.5),
          y - ReportLayout.stepLine / 2,
          third * (i + 0.5),
          y + ReportLayout.stepLine / 2,
        ),
        Paint()..color = color(i),
      );
    }
    for (var i = 0; i < _steps.length; i++) {
      canvas.drawCircle(
        Offset(third * (i + 0.5), y),
        ReportLayout.stepDot / 2,
        Paint()..color = color(i),
      );
    }
  }

  @override
  bool shouldRepaint(_StepsPainter old) => old.done != done;
}
