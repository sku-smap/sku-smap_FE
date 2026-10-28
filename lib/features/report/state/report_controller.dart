import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../campus/data/campus_directory.dart';
import '../../campus/data/campus_models.dart';
import '../data/report_models.dart';
import '../data/report_options.dart';
import 'report_providers.dart';

// kind: start with this kind; node: the viewer spot; near: the home start
typedef ReportEntry = ({
  ReportKind? kind,
  String? node,
  int? step,
  ReportSpot? near,
});

enum ReportPick { loc, from, to }

ReportSpot? reportSpotOf(String? node) {
  final spot = spotById[node];
  return spot == null ? null : (node: spot.id, label: spot.title);
}

// A home place (building or spot id) as a report location
ReportSpot reportSpotFromPlace(CampusPlace place) =>
    (node: nodeOf(place.id) ?? place.id, label: place.name);

class ReportFormState {
  const ReportFormState({
    this.kind,
    this.loc,
    this.from,
    this.to,
    this.picking,
    this.mapOpen = false,
    this.level = MapLevel.ground,
    this.type,
    this.days = 0,
    this.tags = const [],
    this.memo = '',
    this.photo,
    this.sending = false,
  });

  final ReportKind? kind;
  final ReportSpot? loc;
  final ReportSpot? from;
  final ReportSpot? to;
  final ReportPick? picking;
  final bool mapOpen;
  final MapLevel level;
  final String? type;
  final int? days;
  final List<String> tags;
  final String memo;
  final String? photo;
  final bool sending;

  // Each kind's required inputs are filled
  bool get ready {
    final hasMemo = memo.trim().isNotEmpty;
    return switch (kind) {
      ReportKind.issue => type != null || hasMemo,
      ReportKind.closure => loc != null && type != null,
      ReportKind.course =>
        from != null &&
            to != null &&
            from!.node != to!.node &&
            (hasMemo || tags.isNotEmpty),
      ReportKind.praise => loc != null,
      null => false,
    };
  }

  ReportFormState copyWith({
    ReportKind? Function()? kind,
    ReportSpot? Function()? loc,
    ReportSpot? Function()? from,
    ReportSpot? Function()? to,
    ReportPick? Function()? picking,
    bool? mapOpen,
    MapLevel? level,
    String? Function()? type,
    int? Function()? days,
    List<String>? tags,
    String? memo,
    String? Function()? photo,
    bool? sending,
  }) {
    return ReportFormState(
      kind: kind != null ? kind() : this.kind,
      loc: loc != null ? loc() : this.loc,
      from: from != null ? from() : this.from,
      to: to != null ? to() : this.to,
      picking: picking != null ? picking() : this.picking,
      mapOpen: mapOpen ?? this.mapOpen,
      level: level ?? this.level,
      type: type != null ? type() : this.type,
      days: days != null ? days() : this.days,
      tags: tags ?? this.tags,
      memo: memo ?? this.memo,
      photo: photo != null ? photo() : this.photo,
      sending: sending ?? this.sending,
    );
  }
}

class ReportController extends Notifier<ReportFormState> {
  ReportController(this.entry);

  final ReportEntry entry;

  @override
  ReportFormState build() {
    final loc = reportSpotOf(entry.node) ?? entry.near;
    return ReportFormState(
      kind: entry.kind,
      loc: loc,
      from: entry.near,
      level: spotById[loc?.node]?.level ?? MapLevel.ground,
    );
  }

  void setKind(ReportKind? kind) => state = state.copyWith(kind: () => kind);

  void startPick(ReportPick? pick) =>
      state = state.copyWith(picking: () => pick);

  // Apply what was picked to the field that asked for it
  void picked(ReportSpot spot) {
    state = switch (state.picking) {
      ReportPick.loc => state.copyWith(loc: () => spot),
      ReportPick.from => state.copyWith(from: () => spot),
      ReportPick.to => state.copyWith(to: () => spot),
      null => state,
    };
    state = state.copyWith(picking: () => null);
  }

  void toggleMap() => state = state.copyWith(mapOpen: !state.mapOpen);

  void setLevel(MapLevel level) => state = state.copyWith(level: level);

  void mapPicked(ReportSpot spot) => state = state.copyWith(loc: () => spot);

  // Tapping the chosen type again clears it
  void toggleType(String type) =>
      state = state.copyWith(type: () => state.type == type ? null : type);

  void setDays(int? days) => state = state.copyWith(days: () => days);

  void toggleTag(String tag) => state = state.copyWith(
    tags: state.tags.contains(tag)
        ? state.tags.where((t) => t != tag).toList()
        : [...state.tags, tag],
  );

  void setMemo(String memo) => state = state.copyWith(memo: memo);

  void setPhoto(String? path) => state = state.copyWith(photo: () => path);

  // Send, or keep on this device when the server is unreachable; returns thanks
  Future<String?> send() async {
    final s = state;
    final kind = s.kind;
    if (kind == null || !s.ready || s.sending) return null;
    state = s.copyWith(sending: true);
    final course = kind == ReportKind.course;
    final report = Report(
      kind: kind,
      node: course ? s.from!.node : (s.loc?.node ?? reportHomeNode),
      step: entry.step,
      type: switch (kind) {
        ReportKind.issue || ReportKind.closure => s.type,
        ReportKind.course => s.tags.isEmpty ? null : s.tags.join(', '),
        ReportKind.praise => null,
      },
      memo: s.memo.trim(),
      until: kind == ReportKind.closure ? untilDate(s.days) : null,
      fromNode: course ? s.from!.node : null,
      toNode: course ? s.to!.node : null,
      tags: course ? s.tags : null,
      photoPath: kind == ReportKind.praise ? null : s.photo,
    );
    final ok = await ref.read(reportRepositoryProvider).send(report);
    if (!ok) await ref.read(reportStorageProvider).saveLocal(report);
    ref.invalidate(myReportsProvider);
    if (ref.mounted) state = state.copyWith(sending: false);
    return kind.thanks;
  }
}

final reportControllerProvider = NotifierProvider.autoDispose
    .family<ReportController, ReportFormState, ReportEntry>(
      ReportController.new,
    );
