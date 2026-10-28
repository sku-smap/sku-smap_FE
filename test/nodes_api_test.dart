import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smap/core/network/api_client.dart';
import 'package:smap/core/network/app_exception.dart';
import 'package:smap/features/campus/data/api_node_repository.dart';
import 'package:smap/features/campus/data/campus_directory.dart';
import 'package:smap/features/campus/data/campus_models.dart';
import 'package:smap/features/campus/data/dto/node_dto.dart';
import 'package:smap/features/navigation/data/route_graph.dart';
import 'package:smap/features/search/data/place_search.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.body, [this.status = 200]);

  final Object body;
  final int status;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, Object?> _node({
  String? nodeId = 'EJ1_02_E',
  String? building = '은주1관',
  String? floorLabel = '2',
  String? title = '은주1관 2층 동쪽',
}) => {
  'nodeId': nodeId,
  'building': building,
  'floorLabel': floorLabel,
  'title': title,
  'originalFilename': '은주1관_2층_동쪽.jpg',
};

Map<String, Object?> _ok(Object? data) => {
  'success': true,
  'code': 'COMMON_200_OK',
  'message': '성공',
  'data': data,
};

PanoSpot _spot(Map<String, Object?> json) => NodeDto.fromJson(json).toModel()!;

void main() {
  tearDown(resetSpots);

  group('노드 DTO 매핑', () {
    test('건물 이름을 앱 건물 키로, 층 표기를 앱 형식으로 바꾼다', () {
      final s = _spot(_node());
      expect(s.id, 'EJ1_02_E');
      expect(s.title, '은주1관 2층 동쪽');
      expect(s.building, 'eunju1');
      expect(s.floor, '2층');
      expect(s.level, MapLevel.ground);
      expect(s.onMap, isFalse);
      expect(s.flat, isFalse);
    });

    test('야외·L층·지하·층 없음을 구분한다', () {
      final outdoor = _spot(_node(building: '야외', floorLabel: ''));
      expect(outdoor.outdoor, isTrue);
      expect(outdoor.floor, isNull);
      expect(_spot(_node(floorLabel: 'L')).floor, 'L층');
      final under = _spot(_node(floorLabel: 'B1'));
      expect(under.floor, 'B1');
      expect(under.level, MapLevel.underground);
    });

    test('이름표에 없는 건물은 이름 그대로 별도 건물로 둔다', () {
      final s = _spot(_node(building: '문예관-북악관 연결구간'));
      expect(s.building, '문예관-북악관 연결구간');
      expect(buildingNameOf(s.building), '문예관-북악관 연결구간');
      expect(buildingNameOf('bukak'), '북악관');
    });

    test('ID나 이름이 없으면 버린다', () {
      expect(NodeDto.fromJson(_node(nodeId: null)).toModel(), isNull);
      expect(NodeDto.fromJson(_node(title: ' ')).toModel(), isNull);
    });
  });

  group('노드 API', () {
    test('전체 노드를 조회한다', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
      final adapter = _Adapter(_ok([_node(), _node(nodeId: '')]));
      dio.httpClientAdapter = adapter;
      final spots = await ApiNodeRepository(ApiClient(dio)).all();
      expect(spots.map((s) => s.id), ['EJ1_02_E']);
      expect(adapter.requests.single.uri.path, '/api/v1/nodes');
    });

    test('오류 응답은 공통 앱 오류로 바뀐다', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = _Adapter({
          'success': false,
          'code': 'COMMON_404_NOT_FOUND',
          'message': '없음',
          'data': null,
        }, 404);
      await expectLater(
        ApiNodeRepository(ApiClient(dio)).all(),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('서버 노드 병합', () {
    test('같은 ID는 서버 이름·층을 쓰고 지도 좌표·사진 유형은 유지한다', () {
      final before = spotById['gate_front']!;
      registerSpots([
        _spot(
          _node(
            nodeId: 'gate_front',
            building: '야외',
            floorLabel: '',
            title: '정문(서버)',
          ),
        ),
        _spot(_node()),
      ]);

      final merged = spotById['gate_front']!;
      expect(merged.title, '정문(서버)');
      expect((merged.x, merged.y), (before.x, before.y));
      expect(merged.estimated, before.estimated);
      expect(spotById['EJ1_02_E']!.onMap, isFalse);
    });

    test('지도 좌표가 없는 노드는 지도 선택에서 빠지고 검색·경로 계산은 된다', () {
      registerSpots([
        _spot(_node(title: '은주1관 정문 안쪽', building: '야외', floorLabel: '')),
      ]);

      expect(searchSpots('은주1관 정문 안쪽').single.id, 'EJ1_02_E');
      final spot = spotById['EJ1_02_E']!;
      expect(nearestSpot(spot.x ?? 0, spot.y ?? 0)?.id, isNot('EJ1_02_E'));
      expect(routeStats(['gate_front', 'EJ1_02_E']).meters, greaterThan(0));
    });
  });
}
