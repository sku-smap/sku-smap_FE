import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smap/core/network/api_client.dart';
import 'package:smap/core/network/app_config.dart';
import 'package:smap/core/network/app_exception.dart';
import 'package:smap/features/campus/data/campus_directory.dart';
import 'package:smap/features/campus/data/campus_models.dart';
import 'package:smap/features/campus/state/launch_provider.dart';
import 'package:smap/features/campus/state/trip_controller.dart';
import 'package:smap/features/search/data/api_search_repository.dart';
import 'package:smap/features/search/data/candidate_place.dart';
import 'package:smap/features/search/data/dto/search_dto.dart';
import 'package:smap/features/search/data/record_voice_recorder.dart';
import 'package:smap/features/search/data/search_models.dart';
import 'package:smap/features/search/data/voice_recorder.dart';
import 'package:smap/features/search/state/search_flow_controller.dart';

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

Map<String, Object?> _candidate({
  String? id = 'place:r-yudam-907',
  String? type = 'PLACE',
  String? placeId = 'r-yudam-907',
  String? nodeId = 's1013_105937',
  String? name = '로렐 카페 (907호)',
  String? kind = 'facility',
}) => {
  'candidateId': id,
  'type': type,
  'placeId': placeId,
  'nodeId': nodeId,
  'name': name,
  'displaySub': '유담관 9층 907호',
  'building': '유담관',
  'floorLabel': '9',
  'kind': kind,
  'reason': '근처 시설: 카페',
  'score': 0.93,
  'matchedBy': 'BOTH',
};

Map<String, Object?> _response({
  String status = 'CANDIDATES',
  String? routeOption = 'COMFORTABLE',
  List<Map<String, Object?>>? candidates,
  String? transcript,
}) => {
  'searchId': 12,
  'target': 'DESTINATION',
  'inputType': transcript == null ? 'TEXT' : 'VOICE',
  'transcript': transcript,
  'sttEngine': transcript == null ? null : 'WHISPER',
  'status': status,
  'message': '어디로 가실지 골라 주세요.',
  'routeOption': routeOption,
  'candidates': candidates ?? [_candidate()],
};

({ApiSearchRepository repo, _Adapter adapter}) _api(Object? data) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
  final adapter = _Adapter({
    'success': true,
    'code': 'OK',
    'message': '',
    'data': data,
  });
  dio.httpClientAdapter = adapter;
  return (repo: ApiSearchRepository(ApiClient(dio)), adapter: adapter);
}

void main() {
  tearDown(() {
    resetPlaces();
    resetSpots();
  });

  group('검색 응답 매핑', () {
    test('검색 ID·안내 문구·경로 옵션·후보를 읽는다', () {
      final r = SearchDto.resultFrom(_response(), SearchTarget.destination);
      expect(r.searchId, 12);
      expect(r.target, SearchTarget.destination);
      expect(r.message, '어디로 가실지 골라 주세요.');
      expect(r.routeOption, RouteOption.comfortable);
      final c = r.candidates.single;
      expect(c.id, 'place:r-yudam-907');
      expect(c.type, CandidateType.place);
      expect(c.nodeId, 's1013_105937');
      expect(c.sub, '유담관 9층 907호');
      expect(c.reason, '근처 시설: 카페');
      expect(c.kind, PlaceKind.facility);
      expect(c.score, 0.93);
    });

    test('후보가 없으면 빈 목록, 모르는 경로 옵션은 없음으로 본다', () {
      final r = SearchDto.resultFrom(
        _response(status: 'NOT_FOUND', routeOption: 'FLY', candidates: []),
        SearchTarget.origin,
      );
      expect(r.candidates, isEmpty);
      expect(r.routeOption, isNull);
    });

    test('사진 지점 후보와 빠진 값을 구분한다', () {
      final r = SearchDto.resultFrom(
        _response(
          candidates: [
            _candidate(
              id: 'node:gate_front',
              type: 'NODE',
              placeId: null,
              nodeId: 'gate_front',
            ),
            _candidate(kind: 'lab'),
            _candidate(id: null),
            _candidate(nodeId: ''),
            _candidate(name: null),
          ],
        ),
        SearchTarget.origin,
      );
      expect(r.candidates, hasLength(2));
      expect(r.candidates.first.type, CandidateType.node);
      expect(r.candidates.last.kind, PlaceKind.facility);
    });

    test('음성 검색은 들은 문장을 함께 준다', () {
      final r = SearchDto.resultFrom(
        _response(transcript: '나 지금 카페 앞이야'),
        SearchTarget.origin,
      );
      expect(r.transcript, '나 지금 카페 앞이야');
    });
  });

  group('검색 API 요청', () {
    test('텍스트는 JSON으로 대상·문장·개수를 보낸다', () async {
      final (:repo, :adapter) = _api(_response());
      await repo.searchText(target: SearchTarget.destination, query: '카페 어디야');
      final o = adapter.requests.single;
      expect(o.method, 'POST');
      expect(o.uri.path, '/api/v1/searches');
      expect(o.data, {'target': 'DESTINATION', 'query': '카페 어디야', 'limit': 5});
    });

    test('음성은 multipart로 WAV 파일과 녹음 길이를 보낸다', () async {
      final (:repo, :adapter) = _api(_response(transcript: '유담관'));
      await repo.searchVoice(
        target: SearchTarget.origin,
        clip: VoiceClip(
          bytes: Uint8List.fromList([1, 2, 3]),
          duration: const Duration(milliseconds: 3200),
        ),
      );
      final o = adapter.requests.single;
      expect(o.contentType, startsWith(Headers.multipartFormDataContentType));
      final form = o.data as FormData;
      expect(Map.fromEntries(form.fields), {
        'target': 'ORIGIN',
        'durationMs': '3200',
        'limit': '5',
      });
      final file = form.files.single;
      expect(file.key, 'audio');
      expect(file.value.filename, 'voice.wav');
      expect(file.value.contentType.toString(), 'audio/wav');
      expect(file.value.length, 3);
    });

    test('후보 선택은 검색 ID 경로에 후보 ID를 PUT으로 보낸다', () async {
      final (:repo, :adapter) = _api(null);
      await repo.select(searchId: 12, candidateId: 'place:r-yudam-907');
      final o = adapter.requests.single;
      expect(o.method, 'PUT');
      expect(o.uri.path, '/api/v1/searches/12/selection');
      expect(o.data, {'candidateId': 'place:r-yudam-907'});
    });

    test('오류는 공통 앱 오류로 바뀐다', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = _Adapter({
          'success': false,
          'code': 'SEARCH_400',
          'message': '문장을 1~200자로 입력해 주세요.',
          'data': null,
        }, 400);
      await expectLater(
        ApiSearchRepository(ApiClient(dio))
            .searchText(target: SearchTarget.destination, query: ''),
        throwsA(
          isA<ServerException>().having((e) => e.code, 'code', 'SEARCH_400'),
        ),
      );
    });

    test('USE_MOCK이 꺼지면 검색 API 구현을 주입받는다', () {
      final c = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(
              env: AppEnv.dev,
              baseUrl: 'https://x',
              useMock: false,
            ),
          ),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(searchRepositoryProvider), isA<ApiSearchRepository>());
    });
  });

  test('녹음은 16kHz 모노 WAV 헤더를 붙여 보낸다', () {
    final wav = wavOf(Uint8List(32000), sampleRate: 16000);
    final h = ByteData.sublistView(wav, 0, 44);
    expect(ascii.decode(wav.sublist(0, 4)), 'RIFF');
    expect(ascii.decode(wav.sublist(8, 12)), 'WAVE');
    expect(h.getUint32(4, Endian.little), 36 + 32000);
    expect(h.getUint16(22, Endian.little), 1);
    expect(h.getUint32(24, Endian.little), 16000);
    expect(h.getUint32(40, Endian.little), 32000);
    expect(wav.length, 44 + 32000);
  });

  group('고른 후보를 앱 장소로', () {
    test('서버에만 있는 장소는 등록해서 길안내에서 찾는다', () {
      final c = SearchDto.candidateFrom(
        _candidate(placeId: 'r-new-1', nodeId: 'gate_front'),
      )!;
      final place = placeOfCandidate(c);
      expect(place.id, 'r-new-1');
      expect(nodeOf('r-new-1'), 'gate_front');
    });

    test('사진 지점 후보는 노드 ID로 정하고 모르는 지점은 등록한다', () {
      final c = SearchDto.candidateFrom(
        _candidate(
          id: 'node:EJ9',
          type: 'NODE',
          placeId: null,
          nodeId: 'EJ9',
          name: '새 지점',
        ),
      )!;
      final place = placeOfCandidate(c);
      expect(place.id, 'EJ9');
      expect(spotById['EJ9']?.title, '새 지점');
      expect(spotById['EJ9']?.floor, '9층');
    });
  });

  group('경로 옵션 반영', () {
    ProviderContainer trip() {
      final c = ProviderContainer(
        overrides: [launchQueryProvider.overrideWithValue(const {})],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('편한 길은 엘리베이터 우선, 실내·지하는 실내 우선을 켠다', () {
      final c = trip();
      c.read(tripProvider.notifier).applyRouteOption(RouteOption.comfortable);
      expect(c.read(tripProvider).mode, RouteMode.elevator);
      expect(c.read(tripProvider).routeOption, RouteOption.comfortable);

      c
          .read(tripProvider.notifier)
          .applyRouteOption(RouteOption.indoorUndergroundFirst);
      expect(c.read(tripProvider).indoor, isTrue);
      expect(c.read(tripProvider).mode, RouteMode.elevator);
    });

    test('최단 경로는 앱 옵션을 그대로 두고 값만 저장한다', () {
      final c = trip();
      c.read(tripProvider.notifier).applyRouteOption(RouteOption.shortest);
      expect(c.read(tripProvider).mode, RouteMode.outdoor);
      expect(c.read(tripProvider).routeOption, RouteOption.shortest);
    });

    test('직접 이동 방식을 고르면 검색 옵션은 지운다', () {
      final c = trip();
      c.read(tripProvider.notifier)
        ..applyRouteOption(RouteOption.outdoorFirst)
        ..setMode(RouteMode.elevator);
      expect(c.read(tripProvider).routeOption, isNull);
    });
  });
}
