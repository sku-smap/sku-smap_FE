import 'report_models.dart';

// Server rows shown with ?reports=demo (R-15)
final demoServerReports = [
  MyReport(
    id: 104,
    createdAt: DateTime(2026, 10, 9, 14, 20),
    kind: ReportKind.course,
    node: 'bus_stop',
    type: '짐 많을 때, 엘리베이터 위주',
    status: ReportStatus.applied,
    fromNode: 'bus_stop',
    toNode: 'gate_front',
    tags: const ['짐 많을 때', '엘리베이터 위주'],
  ),
  MyReport(
    id: 103,
    createdAt: DateTime(2026, 10, 8, 9, 5),
    kind: ReportKind.closure,
    node: 'road_bon_2way',
    type: '엘리베이터 고장',
    status: ReportStatus.checking,
    until: '2026-10-14',
  ),
  MyReport(
    id: 102,
    createdAt: DateTime(2026, 10, 7, 17, 40),
    kind: ReportKind.issue,
    node: 'road_yudam_3way',
    type: '이동 방향(화살표)이 틀려요',
  ),
  MyReport(
    id: 101,
    createdAt: DateTime(2026, 10, 5, 11, 0),
    kind: ReportKind.issue,
    node: reportHomeNode,
    type: '기타',
    memo: '지도 글씨가 작아요',
    status: ReportStatus.rejected,
  ),
];
