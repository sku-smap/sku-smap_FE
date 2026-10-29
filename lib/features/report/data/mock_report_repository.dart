import 'report_mock.dart';
import 'report_models.dart';
import 'report_repository.dart';

// Stand-in for the report server; no network until the API is connected
class MockReportRepository implements ReportRepository {
  MockReportRepository({
    required this.online,
    this.delay = const Duration(milliseconds: 700),
  }) : _rows = online ? [...demoServerReports] : [];

  final bool online;
  final Duration delay;
  final List<MyReport> _rows;

  @override
  Future<bool> send(Report report) async {
    await Future<void>.delayed(delay);
    if (!online) return false;
    _rows.insert(
      0,
      MyReport(
        id: DateTime.now().millisecondsSinceEpoch,
        createdAt: DateTime.now(),
        kind: report.kind,
        node: report.node,
        type: report.type,
        memo: report.memo.isEmpty ? null : report.memo,
        until: report.until,
        fromNode: report.fromNode,
        toNode: report.toNode,
        tags: report.tags,
      ),
    );
    return true;
  }

  @override
  Future<List<MyReport>?> listMine() async => online ? [..._rows] : null;

  // Mock-only: the team moves a report along (received → applied)
  void setStatus(int id, ReportStatus status) {
    final i = _rows.indexWhere((r) => r.id == id);
    if (i >= 0) _rows[i] = _rows[i].copyWith(status: status);
  }
}
