import 'package:flutter/material.dart';

import '../../data/campus_models.dart';
import '../home_tokens.dart';
import 'home_sheet.dart';

class FacilitySheet extends StatelessWidget {
  const FacilitySheet({super.key, required this.spot, required this.onPick});

  final FacilitySpot spot;
  final ValueChanged<CampusPlace> onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(spot.building, style: HomeText.sheetTitle),
        const SizedBox(height: 6.6),
        Text('어디로 갈까요?', style: HomeText.sheetBody),
        const SizedBox(height: 16),
        SheetPlaceChips(
          places: spot.places,
          onTap: (p) {
            Navigator.of(context).pop();
            onPick(p);
          },
        ),
      ],
    );
  }
}
