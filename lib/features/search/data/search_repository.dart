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

  // A sentence that may name both ends (POST /api/v1/route-searches); the
  // candidates are the destination's and the best start rides along
  Future<SearchResult> searchRouteText(String query);

  Future<SearchResult> searchRouteVoice(VoiceClip clip);

  // Record which candidate of that search the user settled on
  Future<void> select({required int searchId, required String candidateId});
}
