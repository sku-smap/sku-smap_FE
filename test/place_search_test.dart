import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smap/core/network/app_exception.dart';
import 'package:smap/features/campus/data/campus_directory.dart';
import 'package:smap/features/campus/data/campus_models.dart';
import 'package:smap/features/campus/data/place_repository.dart';
import 'package:smap/features/campus/state/place_providers.dart';
import 'package:smap/features/search/data/search_models.dart';
import 'package:smap/features/search/presentation/widgets/place_picker.dart';
import 'package:smap/features/search/state/place_search_controller.dart';

SearchPlace _place(String id, String name) =>
    SearchPlace(id: id, name: name, kind: PlaceKind.room, node: 'gate_front');

// Each keyword answers when the test completes it, or fails on demand
class _FakeRepository implements PlaceRepository {
  final pending = <String, Completer<List<SearchPlace>>>{};
  final asked = <String>[];
  List<SearchPlace> catalog = [_place('b-bonkwan', '본관')];
  Object? catalogError;

  @override
  Future<List<SearchPlace>> all() async {
    final error = catalogError;
    if (error != null) throw error;
    return catalog;
  }

  @override
  Future<List<SearchPlace>> search(String keyword) {
    asked.add(keyword);
    return (pending[keyword] = Completer()).future;
  }

  void answer(String keyword, List<SearchPlace> places) =>
      pending[keyword]!.complete(places);

  void fail(String keyword, AppException error) =>
      pending[keyword]!.completeError(error);
}

void main() {
  tearDown(resetPlaces);

  group('검색 상태', () {
    late _FakeRepository repo;
    late ProviderContainer c;
    final key = Object();
    PlaceSearchState read() => c.read(placeSearchProvider(key));
    PlaceSearchController notifier() =>
        c.read(placeSearchProvider(key).notifier);

    setUp(() {
      repo = _FakeRepository();
      c = ProviderContainer(
        overrides: [placeRepositoryProvider.overrideWithValue(repo)],
      );
      c.listen(placeSearchProvider(key), (_, _) {});
    });
    tearDown(() => c.dispose());

    testWidgets('입력이 멈춘 뒤 마지막 검색어로만 요청한다', (tester) async {
      notifier()
        ..setQuery('유')
        ..setQuery('유담');
      expect(read().status, PlaceSearchStatus.loading);
      await tester.pump(const Duration(milliseconds: 299));
      expect(repo.asked, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      expect(repo.asked, ['유담']);

      repo.answer('유담', [_place('b-yudam', '유담관')]);
      await tester.pump();
      expect(read().status, PlaceSearchStatus.done);
      expect(read().results.single.name, '유담관');
      expect(resolvePlace('b-yudam')?.name, '유담관');
    });

    testWidgets('늦게 도착한 이전 응답은 무시한다', (tester) async {
      notifier().setQuery('본');
      await tester.pump(PlaceSearchController.debounce);
      notifier().setQuery('본관');
      await tester.pump(PlaceSearchController.debounce);

      repo.answer('본관', [_place('b-bonkwan', '본관')]);
      await tester.pump();
      repo.answer('본', [_place('x', '본부 옛 결과')]);
      await tester.pump();

      expect(read().query, '본관');
      expect(read().results.single.name, '본관');
    });

    testWidgets('검색어를 지우면 기본 목록 상태로 돌아가고 진행 중 응답도 버린다', (tester) async {
      notifier().setQuery('본관');
      await tester.pump(PlaceSearchController.debounce);
      notifier().setQuery('  ');
      expect(read().status, PlaceSearchStatus.idle);

      repo.answer('본관', [_place('b-bonkwan', '본관')]);
      await tester.pump();
      expect(read().status, PlaceSearchStatus.idle);
      expect(read().results, isEmpty);
    });

    testWidgets('결과가 없으면 결과 없음 상태다', (tester) async {
      notifier().setQuery('ㅁㄴㅇ');
      await tester.pump(PlaceSearchController.debounce);
      repo.answer('ㅁㄴㅇ', []);
      await tester.pump();
      expect(read().noResults, isTrue);
    });

    testWidgets('오류가 나면 메시지를 담고 다시 시도하면 결과를 받는다', (tester) async {
      notifier().setQuery('본관');
      await tester.pump(PlaceSearchController.debounce);
      repo.fail('본관', const NetworkException());
      await tester.pump();
      expect(read().status, PlaceSearchStatus.failed);
      expect(read().error, '인터넷 연결을 확인해 주세요.');

      notifier().retry();
      expect(read().status, PlaceSearchStatus.loading);
      repo.answer('본관', [_place('b-bonkwan', '본관')]);
      await tester.pump();
      expect(read().status, PlaceSearchStatus.done);
      expect(repo.asked, ['본관', '본관']);
    });
  });

  group('검색 화면 상태', () {
    Future<_FakeRepository> pump(
      WidgetTester tester, {
      required ValueChanged<CampusPlace> onPick,
      Object? catalogError,
    }) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = _FakeRepository()..catalogError = catalogError;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [placeRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            home: Scaffold(
              body: PlacePicker(
                target: PickTarget.to,
                onPick: onPick,
                onClose: () {},
                onVoice: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      return repo;
    }

    Future<void> type(WidgetTester tester, String text) async {
      await tester.enterText(find.byType(TextField), text);
      await tester.pump(PlaceSearchController.debounce);
    }

    testWidgets('찾는 중·결과·선택으로 이어진다', (tester) async {
      CampusPlace? picked;
      final repo = await pump(tester, onPick: (p) => picked = p);
      expect(find.text('본관'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '실습');
      await tester.pump();
      expect(find.text('찾는 중…'), findsOneWidget);
      expect(find.text('자주 찾는 곳'), findsNothing);
      await tester.pump(PlaceSearchController.debounce);
      repo.answer('실습', [_place('r-lab', '도시공학과 실습실')]);
      await tester.pump();
      await tester.pump();

      expect(find.text('찾는 중…'), findsNothing);
      await tester.tap(find.text('도시공학과 실습실'));
      expect(picked?.id, 'r-lab');
    });

    testWidgets('결과가 없으면 안내 문구를 보여준다', (tester) async {
      final repo = await pump(tester, onPick: (_) {});
      await type(tester, 'ㅁㄴㅇ');
      repo.answer('ㅁㄴㅇ', []);
      await tester.pump();
      expect(find.textContaining('‘ㅁㄴㅇ’ 검색 결과가 없어요'), findsOneWidget);
    });

    testWidgets('오류를 누르면 다시 검색한다', (tester) async {
      final repo = await pump(tester, onPick: (_) {});
      await type(tester, '본관');
      repo.fail('본관', const RequestTimeoutException());
      await tester.pump();

      final error = find.textContaining('응답이 늦어지고 있어요');
      expect(error, findsOneWidget);
      await tester.tap(error);
      await tester.pump();
      repo.answer('본관', [_place('b-bonkwan', '본관 (서버)')]);
      await tester.pump();
      expect(find.text('본관 (서버)'), findsOneWidget);
    });

    testWidgets('검색어를 지우면 자주 찾는 곳이 다시 보인다', (tester) async {
      final repo = await pump(tester, onPick: (_) {});
      await type(tester, '유담');
      repo.answer('유담', [_place('b-yudam', '유담관')]);
      await tester.pump();
      expect(find.text('유담관'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      expect(find.text('자주 찾는 곳'), findsOneWidget);
      expect(find.text('본관'), findsOneWidget);
      expect(find.text('유담관'), findsNothing);
    });

    testWidgets('전체 장소를 못 불러오면 눌러서 다시 불러온다', (tester) async {
      final repo = await pump(
        tester,
        onPick: (_) {},
        catalogError: const NetworkException(),
      );
      await tester.pump();
      final error = find.textContaining('인터넷 연결을 확인해 주세요.');
      expect(error, findsOneWidget);

      repo.catalogError = null;
      await tester.tap(error);
      await tester.pump();
      await tester.pump();
      expect(find.text('본관'), findsOneWidget);
    });
  });
}
