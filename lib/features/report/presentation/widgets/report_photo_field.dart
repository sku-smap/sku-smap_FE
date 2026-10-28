import 'dart:io';

import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/pressable.dart';
import '../report_tokens.dart';
import 'report_chip.dart';

class ReportPhotoField extends StatelessWidget {
  const ReportPhotoField({
    super.key,
    required this.photo,
    required this.onAdd,
    required this.onRemove,
  });

  final String? photo;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final path = photo;
    if (path != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(ReportLayout.fieldRadius),
            child: Image.file(
              File(path),
              width: ReportLayout.photoWidth,
              height: ReportLayout.photoHeight,
              fit: BoxFit.cover,
              semanticLabel: '첨부한 사진',
            ),
          ),
          const SizedBox(width: 8),
          ReportChip(label: '사진 빼기', onTap: onRemove),
        ],
      );
    }
    return Pressable(
      onTap: onAdd,
      builder: (context, pressed) => CustomPaint(
        painter: _DashedBorder(
          color: pressed ? ReportColors.blue : ReportColors.line,
        ),
        child: SizedBox(
          height: ReportLayout.photoAddHeight,
          child: Center(child: Text('📷 현장 사진 추가', style: ReportText.chip)),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  const _DashedBorder({required this.color});

  final Color color;

  static const _width = 1.5;
  static const _dash = 4.5;
  static const _gap = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(_width / 2),
      const Radius.circular(ReportLayout.fieldRadius),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _width;
    for (final metric in (Path()..addRRect(rect)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += _dash + _gap) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}
