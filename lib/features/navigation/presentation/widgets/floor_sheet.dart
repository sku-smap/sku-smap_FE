import 'package:flutter/material.dart';

import '../../data/navigation_models.dart';
import '../navigation_tokens.dart';

// Rooms fall into the first group they match, top to bottom
final _groups = <(String, bool Function(FloorRoom))>[
  (
    '강의실·실습실',
    (r) => RegExp(
      r'강의|실습|연습|스튜디오|Studio|실기',
      caseSensitive: false,
    ).hasMatch(r.use + r.name),
  ),
  ('교수연구실', (r) => r.use == '교수연구실' || r.name.contains('교수')),
  ('사무실·학과', (r) => RegExp(r'사무|본부|학과|학부|센터|처$|과$').hasMatch(r.use + r.name)),
  ('편의·기타', (_) => true),
];

class FloorSheet extends StatelessWidget {
  const FloorSheet({
    super.key,
    required this.building,
    required this.floor,
    required this.rooms,
  });

  final String building;
  final String floor;
  final List<FloorRoom> rooms;

  @override
  Widget build(BuildContext context) {
    final group = [for (final r in rooms) _groups.indexWhere((g) => g.$2(r))];
    final groups = [
      for (final (gi, (label, _)) in _groups.indexed)
        (
          label,
          [
            for (final (i, r) in rooms.indexed)
              if (group[i] == gi) r,
          ],
        ),
    ].where((g) => g.$2.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$building $floor', style: NavText.sheetTitle),
        const SizedBox(height: 6),
        Text(
          rooms.isEmpty ? '이 층의 호실 정보가 아직 없어요' : '이 층에 ${rooms.length}곳이 있어요',
          style: NavText.sheetSub,
        ),
        for (final (label, list) in groups) ...[
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              text: '$label ',
              children: [
                TextSpan(text: '${list.length}', style: NavText.groupCount),
              ],
            ),
            style: NavText.groupTitle,
          ),
          const SizedBox(height: 6),
          const Divider(height: 1, thickness: 1, color: NavColors.line),
          for (final r in list) _RoomRow(room: r),
        ],
      ],
    );
  }
}

class _RoomRow extends StatelessWidget {
  const _RoomRow({required this.room});

  final FloorRoom room;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 46),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: NavColors.line)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(room.no.isEmpty ? '—' : room.no, style: NavText.roomNo),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: room.name,
                children: [
                  if (room.field)
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: NavColors.estimatedBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '현장 확인',
                          style: NavText.estimated.copyWith(fontSize: 11),
                        ),
                      ),
                    ),
                ],
              ),
              style: NavText.roomName,
            ),
          ),
        ],
      ),
    );
  }
}
