import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'report_models.dart';

// Reports kept on this device and the last status seen for each one
class ReportStorage {
  const ReportStorage();

  static const _localKey = 'smap.myReports';
  static const _seenKey = 'smap.reportSeen';
  static const _maxLocal = 50;

  Future<List<MyReport>> loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final list = jsonDecode(prefs.getString(_localKey) ?? '[]') as List;
      return [
        for (final r in list) MyReport.fromJson(r as Map<String, dynamic>),
      ];
    } on FormatException {
      return const [];
    }
  }

  // A report the server did not take shows as 'saved on this device'
  Future<void> saveLocal(Report r, {DateTime? now}) async {
    final at = now ?? DateTime.now();
    final all = await loadLocal();
    all.insert(
      0,
      MyReport(
        id: -at.millisecondsSinceEpoch,
        createdAt: at,
        kind: r.kind,
        node: r.node,
        type: r.type,
        memo: r.memo.isEmpty ? null : r.memo,
        until: r.until,
        fromNode: r.fromNode,
        toNode: r.toNode,
        tags: r.tags,
        local: true,
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _localKey,
      jsonEncode([for (final m in all.take(_maxLocal)) m.toJson()]),
    );
  }

  // Reports that became applied since the last check, for the thank-you notice
  Future<List<MyReport>> newlyApplied(List<MyReport> rows) async {
    final prefs = await SharedPreferences.getInstance();
    final seen = Map<String, dynamic>.from(
      jsonDecode(prefs.getString(_seenKey) ?? '{}') as Map,
    );
    final fresh = rows
        .where(
          (r) =>
              r.status == ReportStatus.applied &&
              seen['${r.id}'] != ReportStatus.applied.name,
        )
        .toList();
    for (final r in rows) {
      seen['${r.id}'] = r.status.name;
    }
    await prefs.setString(_seenKey, jsonEncode(seen));
    return fresh;
  }
}
