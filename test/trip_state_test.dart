import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smap/features/campus/data/campus_models.dart';
import 'package:smap/features/campus/state/campus_status_providers.dart';
import 'package:smap/features/campus/state/launch_provider.dart';
import 'package:smap/features/campus/state/trip_controller.dart';
import 'package:smap/features/splash/state/splash_entry_provider.dart';

ProviderContainer _container([Map<String, String> launch = const {}]) {
  final container = ProviderContainer(
    overrides: [launchQueryProvider.overrideWithValue(launch)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('실행 링크의 플래그를 읽는다', () {
    final launch = LaunchEntry.fromQuery(const {
      'src': 'nfc',
      'from': 'bus_stop',
      'to': 'b-bonkwan',
      'weather': 'snow',
      'closures': 'demo',
      'reports': 'demo',
      'location': 'campus',
      'edit': '1',
    });
    expect(launch.nfcPlace, '버스정류장');
    expect(launch.wetKind, WetKind.snow);
    expect(launch.demoClosures && launch.demoReports, isTrue);
    expect(launch.onCampus && launch.edit, isTrue);

    final plain = LaunchEntry.fromQuery(const {'from': 'bus_stop'});
    expect(plain.nfcPlace, isNull);
    expect(plain.wetKind, isNull);
  });

  test('NFC로 열면 출발지와 스플래시 문구가 같은 장소다', () {
    final c = _container(const {'src': 'nfc', 'from': 'bus_stop'});
    expect(c.read(tripProvider).from?.id, 'bus_stop');
    expect(c.read(tripProvider).from?.name, c.read(splashNfcPlaceProvider));
    expect(c.read(tripProvider).to, isNull);
  });

  test('잘못된 장소 ID는 비워 둔다', () {
    final c = _container(const {'from': 'nope', 'to': 'b-bonkwan'});
    expect(c.read(tripProvider).from, isNull);
    expect(c.read(tripProvider).to?.name, '본관');
    expect(c.read(tripProvider).canRoute, isFalse);
  });

  test('출발·도착·이동 방식을 명시적인 메서드로만 바꾼다', () {
    final c = _container();
    final trip = c.read(tripProvider.notifier);
    trip
      ..setFrom(const CampusPlace(id: 'bus_stop', name: '버스정류장'))
      ..setTo(const CampusPlace(id: 'b-hyein', name: '혜인관'))
      ..setMode(RouteMode.comfortable)
      ..swap();
    final s = c.read(tripProvider);
    expect(s.from?.id, 'b-hyein');
    expect(s.to?.id, 'bus_stop');
    expect(s.mode, RouteMode.comfortable);
    expect(s.canRoute, isTrue);
  });

  test('비가 와도 실내 우선은 직접 켤 때만 켜진다', () async {
    final c = _container(const {'weather': 'rain'});
    c.read(tripProvider);
    await c.read(campusWeatherProvider.future);
    expect(c.read(tripProvider).indoor, isFalse);

    c.read(tripProvider.notifier).toggleIndoor();
    expect(c.read(tripProvider).indoor, isTrue);
  });

  test('맑은 날은 실내 우선이 꺼져 있다', () async {
    final c = _container();
    c.read(tripProvider);
    await c.read(campusWeatherProvider.future);
    expect(c.read(tripProvider).indoor, isFalse);
  });

  test('통행 불가 지점은 데모 플래그가 있을 때만 받는다', () async {
    expect(await _container().read(campusClosuresProvider.future), isEmpty);
    final demo = await _container(const {'closures': 'demo'})
        .read(campusClosuresProvider.future);
    expect(demo.map((c) => c.node), ['road_bon_2way', 'bukak_b1_elev']);
  });
}
