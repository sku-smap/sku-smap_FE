import 'package:flutter/material.dart';

import '../../../campus/data/campus_models.dart';
import '../../data/home_mock.dart';
import '../home_tokens.dart';

class QuickChips extends StatelessWidget {
  const QuickChips({super.key, required this.onSelect});

  final ValueChanged<CampusPlace> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: HomeLayout.chipHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: HomeLayout.screenH),
        itemCount: quickPlaces.length,
        separatorBuilder: (_, _) => const SizedBox(width: HomeLayout.chipGap),
        itemBuilder: (context, i) {
          final quick = quickPlaces[i];
          return Semantics(
            button: true,
            child: GestureDetector(
              onTap: () => onSelect(quick.place),
              child: Container(
                height: HomeLayout.chipHeight,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: HomeColors.surface,
                  border: Border.all(color: HomeColors.border),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  quick.label,
                  style: HomeText.tracked(HomeText.quickChip, quick.label),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
