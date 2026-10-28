import '../../campus/data/campus_directory.dart';
import '../../campus/data/campus_models.dart';
import '../../campus/data/mock/pano_spots_mock.dart';
import '../../campus/data/mock/search_places_mock.dart';
import 'search_models.dart';
import 'search_tasks_mock.dart';

const _popularIds = [
  'f-bus',
  'b-bonkwan',
  'b-yudam',
  'f-cafeteria',
  'f-gate',
  'b-bukak',
  'f-parking1',
  'b-hyein',
];

final popularPlaces = searchPlaces
    .where((p) => _popularIds.contains(p.id))
    .toList();

final _punct = RegExp(r'[\s·().,!?~]');

String norm(String s) => s.toLowerCase().replaceAll(_punct, '');

List<String> _termsOf(SearchPlace p) =>
    [p.name, ...p.aliases].map(norm).where((t) => t.isNotEmpty).toList();

// Names shared by several places are not used to pin down a mention
final _termOwners = () {
  final owners = <String, int>{};
  for (final p in searchPlaces) {
    for (final t in _termsOf(p).toSet()) {
      owners[t] = (owners[t] ?? 0) + 1;
    }
  }
  return owners;
}();

typedef TaskMatch = ({SearchTask task, SearchPlace to});

// Map an errand ("졸업증명서 떼려면") to its place
TaskMatch? findTask(String text) {
  final t = norm(text);
  for (final task in searchTasks) {
    if (!task.keywords.any((k) => t.contains(norm(k)))) continue;
    final to = placeById[task.place];
    if (to == null) continue;
    final dest = task.dest;
    return (task: task, to: dest == null ? to : to.copyWith(name: dest));
  }
  return null;
}

String taskReply(SearchTask task) =>
    task.reply + (task.checked ? '' : uncheckedNote);

// Score places: exact > prefix > contains, errand match first
List<SearchPlace> searchPlacesFor(String q, {int limit = 8}) {
  final k = norm(q);
  if (k.isEmpty) return const [];
  final scored = <(SearchPlace, int)>[];
  final task = findTask(q);
  if (task != null) {
    final sub = '${task.task.label} · ${task.to.sub ?? ''}'.replaceFirst(
      RegExp(r' · $'),
      '',
    );
    scored.add((task.to.copyWith(sub: sub), 200));
  }
  for (final p in searchPlaces) {
    var s = 0;
    for (final t in _termsOf(p)) {
      if (t == k) {
        s = s < 100 ? 100 : s;
      } else if (t.startsWith(k)) {
        s = s < 80 ? 80 : s;
      } else if (t.contains(k)) {
        s = s < 60 ? 60 : s;
      } else if (k.contains(t) && t.length >= 2) {
        s = s < 50 ? 50 : s;
      }
    }
    final sub = p.sub;
    if (s == 0 && sub != null && norm(sub).contains(k)) s = 30;
    if (s > 0 && p.id != task?.to.id) scored.add((p, s));
  }
  final order = [for (var i = 0; i < scored.length; i++) i]
    ..sort((a, b) {
      final diff = scored[b].$2 - scored[a].$2;
      return diff != 0 ? diff : a - b;
    });
  return [for (final i in order.take(limit)) scored[i].$1];
}

// Let a 360 photo spot be picked as the start
List<PanoSpot> searchSpots(String q, {int limit = 5}) {
  final k = norm(q);
  if (k.isEmpty) return const [];
  return panoSpots
      .where((n) => !n.hidden && norm(n.title).contains(k))
      .take(limit)
      .toList();
}

typedef _Mention = ({SearchPlace place, int at, int len});

// Places named in a sentence, in spoken order
List<_Mention> _mentions(String text) {
  final t = norm(text);
  final found = <_Mention>[];
  for (final p in searchPlaces) {
    _Mention? hit;
    for (final term in _termsOf(p)) {
      if (term.length < 2 || (_termOwners[term] ?? 0) > 1) continue;
      final at = t.indexOf(term);
      if (at >= 0 && (hit == null || term.length > hit.len)) {
        hit = (place: p, at: at, len: term.length);
      }
    }
    if (hit != null) found.add(hit);
  }
  // Keep the longer one when matches overlap ('은주1관' vs '은주')
  final byLength = [for (var i = 0; i < found.length; i++) i]
    ..sort((a, b) {
      final diff = found[b].len - found[a].len;
      return diff != 0 ? diff : a - b;
    });
  final kept = <_Mention>[];
  for (final i in byLength) {
    final f = found[i];
    if (!kept.any((k) => f.at < k.at + k.len && k.at < f.at + f.len)) {
      kept.add(f);
    }
  }
  return kept..sort((a, b) => a.at - b.at);
}

final _avoidStairs = RegExp(r'계단\s*(말고|없이|빼고|피해)|엘리베이터로|엘베로|휠체어|유모차|카트|짐이');
final _fromSuffix = RegExp(r'^(에서|부터)');
final _particle = RegExp(r'(이|가|은|는|을|를|에|에서|으로|로|어디|에요|예요|야|요)$');

// Read "A에서 B 가는 길" / "B 어디에요" as start and destination
VoiceIntent parseUtterance(String text) {
  final avoid = _avoidStairs.hasMatch(text);
  final m = _mentions(text);
  final t = norm(text);
  bool followedByFrom(_Mention x) {
    final start = x.at + x.len;
    final end = start + 3 > t.length ? t.length : start + 3;
    return _fromSuffix.hasMatch(t.substring(start, end));
  }

  final task = findTask(text);
  if (task != null) {
    return VoiceIntent(
      from: m.where(followedByFrom).firstOrNull?.place,
      to: task.to,
      avoidStairs: avoid,
      reply: taskReply(task.task),
    );
  }
  if (m.length >= 2) {
    final fromAt = m.indexWhere(followedByFrom);
    final from = fromAt >= 0 ? fromAt : 0;
    final to = m.lastIndexWhere((x) => x != m[from]);
    return VoiceIntent(
      from: m[from].place,
      to: m[to].place,
      avoidStairs: avoid,
    );
  }
  if (m.length == 1) return VoiceIntent(to: m.first.place, avoidStairs: avoid);

  final candidates = <String, SearchPlace>{};
  for (final w in text.split(RegExp(r'\s+'))) {
    for (final p in searchPlacesFor(w.replaceAll(_particle, ''), limit: 3)) {
      candidates[p.id] = p;
    }
  }
  return VoiceIntent(
    candidates: candidates.values.take(4).toList(),
    avoidStairs: avoid,
  );
}
