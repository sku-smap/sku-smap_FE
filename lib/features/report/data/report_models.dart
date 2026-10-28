enum ReportKind {
  issue(
    icon: '⚠️',
    title: '정보가 틀려요',
    sub: '사진·방향·층 안내가 현장과 달라요',
    thanks: '알려줘서 고마워요! 확인하고 반영할게요.',
    memoHint: '어디가 어떻게 달랐는지 적어주세요 (선택)',
  ),
  closure(
    icon: '🚧',
    title: '지금 못 가요',
    sub: '공사·통로 폐쇄·엘리베이터 고장',
    thanks: '고마워요! 확인되면 길안내가 이 지점을 피해 가요.',
    memoHint: '예) 북악관 지하 연결통로 셔터가 내려가 있어요 (선택)',
  ),
  course(
    icon: '🧭',
    title: '더 좋은 길 알려줄게요',
    sub: '짐 많을 때·언덕 피하는 길·지름길',
    thanks: '좋은 길 고마워요! 확인 후 코스로 추가할게요.',
    memoHint: '어떻게 가는 길인지 적어주세요. 예) 버정에서 혜인관 엘리베이터 → 스콘스퀘어',
  ),
  praise(
    icon: '👍',
    title: '안내가 정확해요',
    sub: '잘 맞았던 곳을 알려주세요',
    thanks: '고마워요! 이 안내를 검증됨으로 기록할게요.',
    memoHint: '어떤 점이 좋았나요? (선택)',
  );

  const ReportKind({
    required this.icon,
    required this.title,
    required this.sub,
    required this.thanks,
    required this.memoHint,
  });

  final String icon;
  final String title;
  final String sub;
  final String thanks;
  final String memoHint;
}

enum ReportStatus {
  received('받음'),
  checking('확인 중'),
  applied('반영됨'),
  rejected('반영 안 됨');

  const ReportStatus(this.label);

  final String label;
}

// A chosen report location: a 360 spot id and how it reads
typedef ReportSpot = ({String node, String label});

// Report not tied to one spot (sent from home without a location)
const reportHomeNode = 'home';

class Report {
  const Report({
    required this.kind,
    required this.node,
    this.step,
    this.type,
    this.memo = '',
    this.until,
    this.fromNode,
    this.toNode,
    this.tags,
    this.photoPath,
  });

  final ReportKind kind;
  final String node;
  final int? step;
  final String? type;
  final String memo;
  final String? until;
  final String? fromNode;
  final String? toNode;
  final List<String>? tags;
  final String? photoPath;
}

class MyReport {
  const MyReport({
    required this.id,
    required this.createdAt,
    required this.kind,
    required this.node,
    this.type,
    this.memo,
    this.status = ReportStatus.received,
    this.until,
    this.fromNode,
    this.toNode,
    this.tags,
    this.local = false,
  });

  final int id;
  final DateTime createdAt;
  final ReportKind kind;
  final String node;
  final String? type;
  final String? memo;
  final ReportStatus status;
  final String? until;
  final String? fromNode;
  final String? toNode;
  final List<String>? tags;
  final bool local;

  MyReport copyWith({ReportStatus? status}) => MyReport(
    id: id,
    createdAt: createdAt,
    kind: kind,
    node: node,
    type: type,
    memo: memo,
    status: status ?? this.status,
    until: until,
    fromNode: fromNode,
    toNode: toNode,
    tags: tags,
    local: local,
  );

  factory MyReport.fromJson(Map<String, dynamic> json) => MyReport(
    id: json['id'] as int,
    createdAt: DateTime.parse(json['created_at'] as String),
    kind: ReportKind.values.byName(json['kind'] as String),
    node: json['node'] as String,
    type: json['type'] as String?,
    memo: json['memo'] as String?,
    status: ReportStatus.values.byName(json['status'] as String),
    until: json['until'] as String?,
    fromNode: json['from_node'] as String?,
    toNode: json['to_node'] as String?,
    tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
    local: json['local'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'created_at': createdAt.toIso8601String(),
    'kind': kind.name,
    'node': node,
    'type': type,
    'memo': memo,
    'status': status.name,
    'until': until,
    'from_node': fromNode,
    'to_node': toNode,
    'tags': tags,
    'local': local,
  };
}
