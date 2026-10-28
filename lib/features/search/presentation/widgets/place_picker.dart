import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/data/campus_models.dart';
import '../../data/mock_location.dart';
import '../../data/place_search.dart';
import '../../data/search_models.dart';
import '../../state/search_flow_controller.dart';
import '../search_tokens.dart';
import 'pick_map.dart';
import 'picker_header.dart';
import 'result_row.dart';

class PlacePicker extends ConsumerStatefulWidget {
  const PlacePicker({
    super.key,
    required this.target,
    required this.onPick,
    required this.onClose,
    required this.onVoice,
    this.title,
  });

  final PickTarget target;
  final String? title;
  final ValueChanged<CampusPlace> onPick;
  final VoidCallback onClose;
  final VoidCallback onVoice;

  @override
  ConsumerState<PlacePicker> createState() => _PlacePickerState();
}

class _PlacePickerState extends ConsumerState<PlacePicker> {
  final _query = TextEditingController();
  var _finding = false;
  LocateError? _locateError;
  var _mapOpen = false;
  var _level = MapLevel.ground;

  bool get _isFrom => widget.target == PickTarget.from;

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  // Use the nearest photo spot to the current location as the start
  Future<void> _findMe() async {
    setState(() {
      _finding = true;
      _locateError = null;
    });
    final result = await ref.read(locatorProvider).locate();
    if (!mounted) return;
    setState(() => _finding = false);
    final spot = result.spot;
    if (spot != null) {
      widget.onPick(spot);
    } else {
      setState(() => _locateError = result.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.text;
    final results = searchPlacesFor(q, limit: 12);
    final spots = _isFrom ? searchSpots(q, limit: 6) : const <PanoSpot>[];
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Column(
      children: [
        PickerHeader(
          controller: _query,
          hint: _isFrom ? '지금 있는 건물·장소' : '건물, 부서, 교수님 이름',
          onBack: widget.onClose,
          onVoice: widget.onVoice,
          onSubmit: () {
            if (results.isNotEmpty) widget.onPick(results.first.spot);
          },
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.only(bottom: 24 + bottom),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  widget.title ?? (_isFrom ? '어디에서 출발하나요?' : '어디로 갈까요?'),
                  style: SearchText.title,
                ),
              ),
              if (q.isEmpty && _isFrom) ..._hereOptions(),
              if (q.isEmpty) ...[
                const _Caption('자주 찾는 곳'),
                for (final p in popularPlaces) _placeRow(p),
              ] else ...[
                for (final p in results) _placeRow(p),
                for (final n in spots)
                  _Inset(
                    child: ResultRow(
                      icon: ResultIcon.spot,
                      title: n.title,
                      sub: '360 촬영 지점',
                      onTap: () => widget.onPick(n.spot),
                    ),
                  ),
                if (results.isEmpty && spots.isEmpty) _Empty(query: q),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _placeRow(SearchPlace p) => _Inset(
    child: ResultRow(
      icon: ResultIcon.pin,
      title: p.name,
      sub: p.detail,
      onTap: () => widget.onPick(p.spot),
    ),
  );

  List<Widget> _hereOptions() {
    final error = _locateError;
    return [
      const SizedBox(height: 4),
      _Inset(
        child: ResultRow(
          icon: ResultIcon.here,
          title: _finding ? '위치 찾는 중…' : '현재 위치로',
          sub: '가장 가까운 촬영 지점 · 실내에선 부정확할 수 있어요',
          highlighted: error != null,
          onTap: _finding ? null : _findMe,
        ),
      ),
      if (error != null) _LocateErrorBox(message: error.message),
      _Inset(
        child: ResultRow(
          icon: ResultIcon.pin,
          title: '지도에서 고르기',
          sub: '지도를 누르면 가장 가까운 촬영 지점',
          highlighted: _mapOpen,
          onTap: () => setState(() => _mapOpen = !_mapOpen),
        ),
      ),
      if (_mapOpen)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: PickMap(
            level: _level,
            onLevel: (level) => setState(() => _level = level),
            onPick: (n) => widget.onPick(n.spot),
          ),
        ),
    ];
  }
}

class _Inset extends StatelessWidget {
  const _Inset({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SearchLayout.listInset),
      child: child,
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(text, style: SearchText.caption),
    );
  }
}

class _LocateErrorBox extends StatelessWidget {
  const _LocateErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 9, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: SearchColors.errorBg,
          borderRadius: BorderRadius.circular(SearchLayout.rowRadius),
        ),
        child: Text(message, style: SearchText.error),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      child: Text(
        '‘$query’ 검색 결과가 없어요. 건물 이름이나 부서 이름으로 다시 찾아보세요.',
        textAlign: TextAlign.center,
        style: SearchText.empty,
      ),
    );
  }
}
