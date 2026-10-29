import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smap/features/campus/data/campus_models.dart';
import 'package:smap/features/campus/data/mock/mock_place_repository.dart';
import 'package:smap/features/campus/data/recent_places_storage.dart';
import 'package:smap/features/campus/state/launch_provider.dart';
import 'package:smap/features/campus/state/place_providers.dart';
import 'package:smap/features/campus/state/recent_places_provider.dart';
import 'package:smap/features/campus/state/trip_controller.dart';

// In-memory stand-in for the device storage
class _Storage implements RecentPlacesStorage {
  _Storage([this.saved = const []]);

  List<String> saved;

  @override
  Future<List<String>> load() async => saved;

  @override
  Future<void> save(List<String> ids) async => saved = ids;
}

Future<ProviderContainer> _container(_Storage storage) async {
  final c = ProviderContainer(
    overrides: [
      launchQueryProvider.overrideWithValue(const {}),
      recentPlacesStorageProvider.overrideWithValue(storage),
      placeRepositoryProvider.overrideWithValue(const MockPlaceRepository()),
    ],
  );
  addTearDown(c.dispose);
  c.listen(recentPlacesProvider, (_, _) {});
  await c.read(placeCatalogProvider.future);
  await pumpEventQueue();
  return c;
}

List<String> _ids(ProviderContainer c) =>
    c.read(popularPlacesProvider).value!.map((p) => p.id).toList();

void main() {
  test('기록이 없으면 기본 목록 그대로다', () async {
    final c = await _container(_Storage());
    expect(_ids(c), popularPlaceIds);
  });

  test('저장된 최근 목적지가 앞에 오고 남은 칸을 기본 목록이 채운다', () async {
    final c = await _container(_Storage(['r-bukak-954', 'nope', 'b-yudam']));
    final ids = _ids(c);
    expect(ids.take(2), ['r-bukak-954', 'b-yudam']);
    expect(ids, hasLength(popularPlaceIds.length));
    expect(ids.where((id) => id == 'b-yudam'), hasLength(1));
    expect(ids, isNot(contains('nope')), reason: 'unknown ids drop out');
  });

  test('도착지를 고르면 맨 앞에 기록하고 8개까지만 기기에 저장한다', () async {
    final storage = _Storage([for (var i = 0; i < 8; i++) 'old-$i']);
    final c = await _container(storage);
    c
        .read(tripProvider.notifier)
        .setTo(const CampusPlace(id: 'r-bukak-954', name: 'GS25 편의점'));

    expect(_ids(c).first, 'r-bukak-954');
    expect(storage.saved.first, 'r-bukak-954');
    expect(storage.saved, hasLength(RecentPlacesController.max));
    expect(storage.saved, isNot(contains('old-7')));

    c
        .read(tripProvider.notifier)
        .setTo(const CampusPlace(id: 'b-yudam', name: '유담관'));
    c
        .read(tripProvider.notifier)
        .setTo(const CampusPlace(id: 'r-bukak-954', name: 'GS25 편의점'));
    expect(storage.saved.take(2), ['r-bukak-954', 'b-yudam']);
  });

  test('저장소를 못 써도 목록은 기본값으로 보인다', () async {
    final c = ProviderContainer(
      overrides: [
        launchQueryProvider.overrideWithValue(const {}),
        placeRepositoryProvider.overrideWithValue(const MockPlaceRepository()),
      ],
    );
    addTearDown(c.dispose);
    await c.read(placeCatalogProvider.future);
    await pumpEventQueue();
    expect(_ids(c), popularPlaceIds);
  });
}
