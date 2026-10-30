import '../../campus/data/campus_models.dart';
import 'place_search.dart';
import 'search_models.dart';
import 'search_repository.dart';
import 'voice_recorder.dart';

// The bundled sentence rules shaped like server results until USE_MOCK is off
class MockSearchRepository implements SearchRepository {
  const MockSearchRepository({this.transcript = '학생 어디야'});

  static const voiceDelay = Duration(milliseconds: 900);
  static const textDelay = Duration(milliseconds: 600);

  // What the stand-in speech-to-text always hears
  final String transcript;

  @override
  Future<SearchResult> searchText({
    required SearchTarget target,
    required String query,
  }) async {
    await Future<void>.delayed(textDelay);
    return _resultOf(target, query);
  }

  @override
  Future<SearchResult> searchVoice({
    required SearchTarget target,
    required VoiceClip clip,
  }) async {
    await Future<void>.delayed(voiceDelay);
    return _resultOf(target, transcript, heard: transcript);
  }

  @override
  Future<SearchResult> searchRouteText(String query) =>
      searchText(target: SearchTarget.destination, query: query);

  @override
  Future<SearchResult> searchRouteVoice(VoiceClip clip) =>
      searchVoice(target: SearchTarget.destination, clip: clip);

  // Bundled searches have no id, so nothing is ever recorded
  @override
  Future<void> select({
    required int searchId,
    required String candidateId,
  }) async {}

  SearchResult _resultOf(SearchTarget target, String text, {String? heard}) {
    final intent = parseUtterance(text);
    final to = intent.to;
    return SearchResult(
      target: target,
      transcript: heard,
      message: intent.reply,
      routeOption: intent.avoidStairs ? RouteOption.comfortable : null,
      candidates: [
        for (final p in to != null ? [to] : intent.candidates) _candidate(p),
      ],
      origin: intent.from == null ? null : _candidate(intent.from!),
    );
  }

  SearchCandidate _candidate(SearchPlace p) => SearchCandidate(
    id: 'place:${p.id}',
    type: CandidateType.place,
    nodeId: p.node,
    name: p.name,
    placeId: p.id,
    sub: p.sub,
    kind: p.kind,
  );
}
