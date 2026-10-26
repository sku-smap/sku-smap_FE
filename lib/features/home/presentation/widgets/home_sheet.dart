import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/campus_models.dart';
import '../home_tokens.dart';
import 'pressable.dart';

Future<void> showHomeSheet(BuildContext context, {required Widget child}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: HomeColors.backdrop,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * HomeLayout.sheetMaxHeight,
    ),
    builder: (context) => _SheetFrame(child: child),
  );
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottom = math.max(20.0, MediaQuery.paddingOf(context).bottom);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: HomeColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(HomeLayout.sheetRadius),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: HomeColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class SheetPlaceChips extends StatelessWidget {
  const SheetPlaceChips({super.key, required this.places, required this.onTap});

  final List<CampusPlace> places;
  final ValueChanged<CampusPlace> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final p in places)
          Pressable(
            onTap: () => onTap(p),
            builder: (context, pressed) => Container(
              height: HomeLayout.chipHeight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: HomeColors.blueSoft,
                border: Border.all(
                  color: pressed ? HomeColors.blue : HomeColors.blueSoft,
                ),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HomeText.sheetChip,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
