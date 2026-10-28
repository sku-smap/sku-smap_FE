import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'dto/search_dto.dart';
import 'search_models.dart';
import 'search_repository.dart';
import 'voice_recorder.dart';

class ApiSearchRepository implements SearchRepository {
  const ApiSearchRepository(this._api);

  static const _path = '/api/v1/searches';
  static const _limit = 5;
  static const _uploadTimeout = Duration(seconds: 30);

  final ApiClient _api;

  @override
  Future<SearchResult> searchText({
    required SearchTarget target,
    required String query,
  }) => _api.post(
    _path,
    body: {
      'target': SearchDto.targetName(target),
      'query': query,
      'limit': _limit,
    },
    decode: (data) => SearchDto.resultFrom(data, target),
  );

  @override
  Future<SearchResult> searchVoice({
    required SearchTarget target,
    required VoiceClip clip,
  }) => _api.postForm(
    _path,
    form: FormData.fromMap({
      'target': SearchDto.targetName(target),
      'durationMs': clip.duration.inMilliseconds,
      'limit': _limit,
      'audio': MultipartFile.fromBytes(
        clip.bytes,
        filename: 'voice.wav',
        contentType: DioMediaType('audio', 'wav'),
      ),
    }),
    sendTimeout: _uploadTimeout,
    decode: (data) => SearchDto.resultFrom(data, target),
  );
}
