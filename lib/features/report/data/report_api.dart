import 'report_mock.dart';
import 'report_models.dart';

// Stand-in for the report server; no network until the API is connected
class MockReportApi {
  MockReportApi({
    required this.online,
    this.delay = const Duration(milliseconds: 700),
  }) : _rows = online ? [...demoServerReports] : [];

  final bool online;
  final Duration delay;
  final List<MyReport> _rows;

  // False means the server is unreachable and the caller keeps it locally
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

  // Null when the server is not connected
  Future<List<MyReport>?> listMine() async => online ? [..._rows] : null;
}
