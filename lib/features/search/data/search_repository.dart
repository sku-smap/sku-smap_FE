import 'search_models.dart';
import 'voice_recorder.dart';

// AI place search from a sentence or a recording, one target at a time
abstract interface class SearchRepository {
  Future<SearchResult> searchText({
    required SearchTarget target,
    required String query,
  });

  Future<SearchResult> searchVoice({
    required SearchTarget target,
    required VoiceClip clip,
  });
}
