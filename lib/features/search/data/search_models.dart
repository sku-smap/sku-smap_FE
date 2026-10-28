import '../../campus/data/campus_models.dart';

enum PickTarget { to, from }

class SearchTask {
  const SearchTask({
    required this.label,
    required this.keywords,
    required this.place,
    this.dest,
    required this.reply,
    required this.checked,
  });

  final String label;
  final List<String> keywords;
  final String place;
  final String? dest;
  final String reply;
  final bool checked;
}

class VoiceIntent {
  const VoiceIntent({
    this.from,
    this.to,
    this.candidates = const [],
    this.avoidStairs = false,
    this.reply,
  });

  final SearchPlace? from;
  final SearchPlace? to;
  final List<SearchPlace> candidates;
  final bool avoidStairs;
  final String? reply;
}
