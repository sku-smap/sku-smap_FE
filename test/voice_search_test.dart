import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smap/core/network/app_exception.dart';
import 'package:smap/features/campus/data/campus_models.dart';
import 'package:smap/features/search/data/search_models.dart';
import 'package:smap/features/search/data/search_repository.dart';
import 'package:smap/features/search/data/voice_recorder.dart';
import 'package:smap/features/search/state/search_flow_controller.dart';
import 'package:smap/features/search/state/voice_controller.dart';

SearchCandidate _c(String id, String name) => SearchCandidate(
  id: 'place:$id',
  type: CandidateType.place,
  nodeId: 'gate_front',
  name: name,
  placeId: id,
);

class _Recorder implements VoiceRecorder {
  _Recorder({this.allowed = true});

  final bool allowed;
  var starts = 0;

  @override
  Future<bool> start() async {
    starts++;
    return allowed;
  }

  @override
  Future<VoiceClip?> stop() async => VoiceClip(
    bytes: Uint8List.fromList([1]),
    duration: const Duration(seconds: 1),
  );

  @override
  Future<void> cancel() async {}

  @override
  Future<void> dispose() async {}
}

// Each request waits until the test answers it
class _Repo implements SearchRepository {
  final pending = <Completer<SearchResult>>[];
  final asked = <String>[];
  final selected = <String>[];

  // Answers each selection; succeeds at once unless a test swaps it
  Future<void> Function(int searchId, String candidateId) onSelect = (
    _,
    _,
  ) async {};

  Future<SearchResult> _wait(String what) {
    asked.add(what);
    final c = Completer<SearchResult>();
    pending.add(c);
    return c.future;
  }

  @override
  Future<SearchResult> searchText({
    required SearchTarget target,
    required String query,
  }) => _wait('text:${target.name}:$query');

  @override
  Future<SearchResult> searchVoice({
    required SearchTarget target,
    required VoiceClip clip,
  }) => _wait('voice:${target.name}');

  @override
  Future<SearchResult> searchRouteText(String query) =>
      _wait('route:text:$query');

  @override
  Future<SearchResult> searchRouteVoice(VoiceClip clip) => _wait('route:voice');

  @override
  Future<void> select({required int searchId, required String candidateId}) {
    selected.add('$searchId:$candidateId');
    return onSelect(searchId, candidateId);
  }
}

SearchResult _result(List<SearchCandidate> candidates, {String? heard}) =>
    SearchResult(
      target: SearchTarget.destination,
      searchId: 7,
      transcript: heard,
      message: candidates.length > 1 ? '어디로 가실지 골라 주세요.' : null,
      routeOption: RouteOption.comfortable,
      candidates: candidates,
    );

void main() {
  late _Repo repo;
  late ProviderContainer c;
  final provider = voiceControllerProvider(SearchTarget.destination);
  VoiceState read() => c.read(provider);
  VoiceController voice() => c.read(provider.notifier);

  void setUpWith(_Recorder recorder) {
    repo = _Repo();
    c = ProviderContainer(
      overrides: [
        searchRepositoryProvider.overrideWithValue(repo),
        voiceRecorderProvider.overrideWithValue(recorder),
      ],
    );
    addTearDown(c.dispose);
    c.listen(provider, (_, _) {});
  }

  testWidgets('후보가 하나면 바로 정하고 검색 ID와 경로 옵션을 넘긴다', (tester) async {
    setUpWith(_Recorder());
    await tester.pump();

    unawaited(voice().handle('유담관이 어디에요?'));
    expect(read().busy, VoiceBusy.finding);
    await tester.pump();
    expect(repo.asked.single, 'route:text:유담관이 어디에요?');

    repo.pending.single.complete(_result([_c('b-yudam', '유담관')]));
    await tester.pump();
    final outcome = read().result!;
    expect(outcome.place!.placeId, 'b-yudam');
    expect(outcome.routeOption, RouteOption.comfortable);
    expect(read().searchId, 7);
  });

  testWidgets('후보가 여럿이면 안내 문구와 칩을 보여주고 고르면 정한다', (tester) async {
    setUpWith(_Recorder());
    await tester.pump();

    unawaited(voice().stop());
    await tester.pump();
    expect(read().busy, VoiceBusy.hearing);
    repo.pending.single.complete(
      _result([_c('a', '학생식당'), _c('b', '학생회관')], heard: '학생 어디야'),
    );
    await tester.pump();

    expect(read().heard, '학생 어디야');
    expect(read().message, isNull);
    expect(read().candidates, hasLength(2));
    expect(read().result, isNull);

    await voice().choose(read().candidates!.last);
    expect(read().result!.place!.name, '학생회관');
    expect(read().result!.routeOption, RouteOption.comfortable);
  });

  testWidgets('검색 중에는 다른 문장을 보내지 않는다', (tester) async {
    setUpWith(_Recorder());
    await tester.pump();

    unawaited(voice().handle('유담관'));
    unawaited(voice().handle('북악관'));
    await tester.pump();
    expect(repo.asked, ['route:text:유담관']);
    repo.pending.single.complete(_result([]));
    await tester.pump();
  });

  testWidgets('다시 녹음을 시작하면 이전 응답은 버린다', (tester) async {
    setUpWith(_Recorder());
    await tester.pump();

    unawaited(voice().handle('유담관'));
    unawaited(voice().start());
    await tester.pump();
    repo.pending.single.complete(_result([_c('b-yudam', '유담관')]));
    await tester.pump();

    expect(read().listening, isTrue);
    expect(read().result, isNull);
    c.dispose();
  });

  testWidgets('오류가 나면 메시지를 보여주고 같은 요청을 다시 보낸다', (tester) async {
    setUpWith(_Recorder());
    await tester.pump();

    unawaited(voice().handle('유담관'));
    await tester.pump();
    repo.pending.single.completeError(const NetworkException());
    await tester.pump();
    expect(read().error, '인터넷 연결을 확인해 주세요.');
    expect(read().heard, '유담관');

    unawaited(voice().retry());
    expect(read().busy, VoiceBusy.finding);
    await tester.pump();
    expect(repo.asked, ['route:text:유담관', 'route:text:유담관']);
    repo.pending.last.complete(_result([_c('b-yudam', '유담관')]));
    await tester.pump();
    expect(read().result, isNotNull);
  });

  testWidgets('문장 길찾기에서 아무것도 못 찾아도 결과를 넘겨 화면이 비우게 한다', (tester) async {
    setUpWith(_Recorder());
    await tester.pump();

    unawaited(voice().handle('ㅁㄴㅇ'));
    await tester.pump();
    repo.pending.single.complete(_result([]));
    await tester.pump();
    expect(read().result, isNotNull);
    expect(read().result!.place, isNull);
    expect(read().result!.origin, isNull);
    expect(repo.selected, isEmpty);
  });

  testWidgets('마이크를 못 쓰면 안내하고 예시 문장은 쓸 수 있다', (tester) async {
    setUpWith(_Recorder(allowed: false));
    await tester.pump();

    expect(read().error, VoiceController.micDenied);
    expect(read().listening, isFalse);
    unawaited(voice().handle('유담관'));
    await tester.pump();
    expect(repo.asked, ['route:text:유담관']);
    repo.pending.single.complete(_result([]));
    await tester.pump();
  });

  group('문장 길찾기', () {
    testWidgets('도착지 음성은 문장 길찾기로 보내고 출발지도 함께 넘긴다', (tester) async {
      setUpWith(_Recorder());
      await tester.pump();

      unawaited(voice().stop());
      await tester.pump();
      expect(repo.asked.single, 'route:voice');
      repo.pending.single.complete(
        SearchResult(
          target: SearchTarget.destination,
          searchId: 7,
          origin: _c('b-yudam', '유담관'),
          candidates: [_c('a', '북악관'), _c('b', '북악관 별관')],
        ),
      );
      await tester.pump();
      await voice().choose(read().candidates!.first);
      expect(read().result!.place!.name, '북악관');
      expect(read().result!.origin?.name, '유담관');
    });

    testWidgets('출발지만 말하면 출발지만 넘기고 도착지는 비운다', (tester) async {
      setUpWith(_Recorder());
      await tester.pump();

      unawaited(voice().handle('나 유담관이야'));
      await tester.pump();
      repo.pending.single.complete(
        SearchResult(
          target: SearchTarget.destination,
          message: '어디로 갈지 알려 주세요.',
          origin: _c('b-yudam', '유담관'),
        ),
      );
      await tester.pump();
      expect(read().result!.place, isNull);
      expect(read().result!.origin?.name, '유담관');
      expect(repo.selected, isEmpty);
    });

    testWidgets('출발지 찾기 음성은 기존 장소 검색을 쓴다', (tester) async {
      repo = _Repo();
      final c = ProviderContainer(
        overrides: [
          searchRepositoryProvider.overrideWithValue(repo),
          voiceRecorderProvider.overrideWithValue(_Recorder()),
        ],
      );
      addTearDown(c.dispose);
      final origin = voiceControllerProvider(SearchTarget.origin);
      c.listen(origin, (_, _) {});
      await tester.pump();
      unawaited(c.read(origin.notifier).handle('유담관'));
      await tester.pump();
      expect(repo.asked.single, 'text:origin:유담관');
      repo.pending.single.complete(_result([]));
      await tester.pump();
    });
  });

  testWidgets('도착지 후보가 여럿이면 자체 안내 문구로 칩을 보여주고 고르면 출발지와 함께 넘긴다', (tester) async {
    setUpWith(_Recorder());
    await tester.pump();

    unawaited(voice().handle('유담관에서 학생 쪽'));
    await tester.pump();
    repo.pending.single.complete(
      SearchResult(
        target: SearchTarget.destination,
        searchId: 7,
        message: '출발지와 목적지를 골라 주세요.',
        origin: _c('b-yudam', '유담관'),
        candidates: [_c('a', '학생식당'), _c('b', '학생회관')],
      ),
    );
    await tester.pump();
    expect(read().result, isNull);
    expect(read().candidates, hasLength(2));
    expect(read().message, isNull, reason: 'server text asks for the start');

    await voice().choose(read().candidates!.last);
    expect(read().result!.place!.name, '학생회관');
    expect(read().result!.origin?.name, '유담관');
  });

  group('후보 확정', () {
    Future<void> showTwo(WidgetTester tester, {int? searchId = 7}) async {
      unawaited(voice().handle('학생'));
      await tester.pump();
      repo.pending.last.complete(
        SearchResult(
          target: SearchTarget.destination,
          searchId: searchId,
          candidates: [_c('a', '학생식당'), _c('b', '학생회관')],
        ),
      );
      await tester.pump();
    }

    testWidgets('고른 후보는 기록을 기다리지 않고 바로 넘긴다', (tester) async {
      setUpWith(_Recorder());
      await tester.pump();
      await showTwo(tester);
      repo.onSelect = (_, _) => Completer<void>().future;

      await voice().choose(read().candidates!.first);
      expect(read().result!.place!.name, '학생식당');
      expect(repo.selected, ['7:place:a']);
    });

    testWidgets('자동으로 고른 후보도 기록한다', (tester) async {
      setUpWith(_Recorder());
      await tester.pump();

      unawaited(voice().handle('유담관'));
      await tester.pump();
      repo.pending.single.complete(_result([_c('b-yudam', '유담관')]));
      await tester.pump();
      expect(repo.selected, ['7:place:b-yudam']);
      expect(read().result, isNotNull);
    });

    testWidgets('정한 뒤에는 다른 후보를 다시 고르지 않는다', (tester) async {
      setUpWith(_Recorder());
      await tester.pump();
      await showTwo(tester);
      final candidates = read().candidates!;

      await voice().choose(candidates.first);
      await voice().choose(candidates.last);
      expect(repo.selected, ['7:place:a']);
      expect(read().result!.place!.name, '학생식당');
    });

    testWidgets('이전 검색의 후보는 고를 수 없다', (tester) async {
      setUpWith(_Recorder());
      await tester.pump();
      await showTwo(tester);
      final old = read().candidates!.first;

      unawaited(voice().start());
      await tester.pump();
      await voice().choose(old);
      expect(read().result, isNull);
      expect(repo.selected, isEmpty);
      c.dispose();
    });

    testWidgets('기록이 실패해도 오류 없이 넘어간다', (tester) async {
      setUpWith(_Recorder());
      await tester.pump();
      await showTwo(tester);
      repo.onSelect = (_, _) async => throw const ServerException(
        '없는 검색',
        code: 'SEARCH_404',
        statusCode: 404,
      );

      await voice().choose(read().candidates!.last);
      await tester.pump();
      expect(read().result!.place!.name, '학생회관');
      expect(read().error, isNull);
    });

    testWidgets('검색 ID가 없으면 기록 없이 확정한다', (tester) async {
      setUpWith(_Recorder());
      await tester.pump();
      await showTwo(tester, searchId: null);

      await voice().choose(read().candidates!.first);
      expect(repo.selected, isEmpty);
      expect(read().result!.place!.name, '학생식당');
    });
  });
}
