import 'package:flutter/material.dart';

import '../../data/navigation_models.dart';
import '../navigation_tokens.dart';

// '홍길동 교수연구실' → '홍길동 교수님'; a bare room number shows nothing
String roomLabel(FloorRoom r) {
  final name = RegExp(r'\S\s*교수\s*연구실$').hasMatch(r.name)
      ? r.name.replaceFirst(RegExp(r'\s*교수\s*연구실$'), ' 교수님')
      : r.name;
  return name == '${r.no}호' ? '' : name;
}

class RoomOverlay extends StatefulWidget {
  const RoomOverlay({super.key, required this.floor, required this.rooms});

  final String floor;
  final List<FloorRoom> rooms;

  @override
  State<RoomOverlay> createState() => _RoomOverlayState();
}

class _RoomOverlayState extends State<RoomOverlay> {
  var _open = true;
  int? _full;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: ColoredBox(
        color: NavColors.overlay,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              button: true,
              expanded: _open,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _open = !_open),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(14, 12, 14, _open ? 8 : 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${widget.floor} · ${widget.rooms.length}곳',
                          style: NavText.overlayHead,
                        ),
                      ),
                      Text(_open ? '접기' : '펼치기', style: NavText.overlayToggle),
                    ],
                  ),
                ),
              ),
            ),
            if (_open)
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                  itemCount: widget.rooms.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 2),
                  itemBuilder: (context, i) {
                    final r = widget.rooms[i];
                    final full = _full == i;
                    return GestureDetector(
                      onTap: () => setState(() => _full = full ? null : i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: full ? NavColors.overlayRow : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 48,
                              child: Text(
                                r.no.isEmpty ? '' : '${r.no}호',
                                style: NavText.overlayRow.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontVariations: const [
                                    FontVariation.weight(700),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                roomLabel(r),
                                maxLines: full ? null : 1,
                                overflow: full ? null : TextOverflow.ellipsis,
                                style: NavText.overlayRow,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
