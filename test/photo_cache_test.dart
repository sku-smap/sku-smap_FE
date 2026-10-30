import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smap/features/navigation/data/photo_cache.dart';

final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

// Records each download; a test can hold one open or make it fail
class _Server {
  final asked = <String>[];
  final waiting = <String, Completer<Uint8List>>{};
  final failing = <String>{};
  var size = 10;
  var hold = false;

  Future<Uint8List> fetch(String url) {
    asked.add(url);
    if (failing.contains(url)) return Future.error(Exception('down'));
    if (!hold) return Future.value(Uint8List(size));
    return (waiting[url] = Completer<Uint8List>()).future;
  }
}

String _signed(String path, [String sig = 'a']) =>
    'https://s3.test/$path?X-Amz-Signature=$sig';

void main() {
  late _Server server;
  setUp(() => server = _Server());

  test('서명이 달라도 같은 파일이면 같은 키다', () {
    expect(
      PhotoCache.keyOf(_signed('pano/a.jpg', '1')),
      'https://s3.test/pano/a.jpg',
    );
    expect(
      PhotoCache.keyOf(_signed('pano/a.jpg', '1')),
      PhotoCache.keyOf(_signed('pano/a.jpg', '2')),
    );
    expect(PhotoCache.keyOf('assets/x.jpg'), 'assets/x.jpg');
  });

  test('다시 서명된 주소도 받아 둔 파일을 쓰고 동시 요청은 한 번만 받는다', () async {
    final cache = PhotoCache(server.fetch);
    await Future.wait([
      cache.fetch(_signed('a.jpg', '1')),
      cache.fetch(_signed('a.jpg', '1')),
    ]);
    await cache.fetch(_signed('a.jpg', '2'));
    expect(server.asked, [_signed('a.jpg', '1')]);
  });

  test('실패한 사진은 보관하지 않고 다음에 다시 받는다', () async {
    final cache = PhotoCache(server.fetch);
    server.failing.add(_signed('a.jpg'));
    await expectLater(cache.fetch(_signed('a.jpg')), throwsException);
    server.failing.clear();
    await cache.fetch(_signed('a.jpg'));
    expect(server.asked, hasLength(2));
    expect(cache.has(_signed('a.jpg')), isTrue);
  });

  test('미리 받기는 순서대로 하나씩, 실패는 건너뛴다', () async {
    final cache = PhotoCache(server.fetch);
    server.failing.add(_signed('b.jpg'));
    await cache.prefetch([
      _signed('a.jpg'),
      _signed('b.jpg'),
      _signed('c.jpg'),
    ]);
    expect(server.asked, [
      _signed('a.jpg'),
      _signed('b.jpg'),
      _signed('c.jpg'),
    ]);
    expect(cache.has(_signed('a.jpg')) && cache.has(_signed('c.jpg')), isTrue);
  });

  test('미리 받기는 앞으로 볼 사진을 밀어내지 않고 상한에서 멈춘다', () async {
    final cache = PhotoCache(server.fetch, maxBytes: 25);
    await cache.prefetch([
      _signed('a.jpg'),
      _signed('b.jpg'),
      _signed('c.jpg'),
    ]);
    expect(cache.has(_signed('a.jpg')) && cache.has(_signed('b.jpg')), isTrue);
    expect(cache.has(_signed('c.jpg')), isFalse);
    expect(cache.size, 20);

    // On screen, the oldest photo makes room
    await cache.fetch(_signed('c.jpg'));
    expect(cache.has(_signed('c.jpg')), isTrue);
    expect(cache.has(_signed('a.jpg')), isFalse);
    expect(cache.size, 20);
  });

  test('새 경로로 미리 받기를 시작하면 이전 목록은 멈춘다', () async {
    final cache = PhotoCache(server.fetch)..clear();
    server.hold = true;
    final first = cache.prefetch([_signed('a.jpg'), _signed('b.jpg')]);
    await Future<void>.delayed(Duration.zero);
    final second = cache.prefetch([_signed('x.jpg')]);
    server.waiting[_signed('a.jpg')]!.complete(Uint8List(10));
    await Future<void>.delayed(Duration.zero);
    server.waiting[_signed('x.jpg')]!.complete(Uint8List(10));
    await Future.wait([first, second]);
    expect(server.asked, isNot(contains(_signed('b.jpg'))));
  });

  testWidgets('같은 파일의 사진은 서명이 달라도 같은 이미지로 그린다', (tester) async {
    server.size = 0;
    final cache = PhotoCache((_) async => Uint8List.fromList(_png));
    final a = CachedPhoto(_signed('p.png', '1'), cache);
    final b = CachedPhoto(_signed('p.png', '2'), cache);
    expect(a, b);
    expect(a.hashCode, b.hashCode);

    final info = await tester.runAsync(() {
      final done = Completer<ImageInfo>();
      a
          .resolve(ImageConfiguration.empty)
          .addListener(ImageStreamListener((image, _) => done.complete(image)));
      return done.future;
    });
    expect(info!.image.width, 1);
  });
}
