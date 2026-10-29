import '../campus_models.dart';
import '../mock/campus_floors_mock.dart';

final _buildingKeyOf = {
  for (final MapEntry(:key, :value) in buildingNames.entries) value: key,
  '야외': 'outdoor',
};

// Fixed building ids (GET /api/v1/buildings) to app building keys
const _buildingKeyOfId = {
  'BON': 'bonkwan',
  'BUKAK': 'bukak',
  'CHUNGWOON': 'chungwoon',
  'DAEIL': 'daeil',
  'EUNJU1': 'eunju1',
  'EUNJU2': 'eunju2',
  'HYEIN': 'hyein',
  'HANLIM': 'hanlim',
  'MOONYE': 'moonye',
  'SANGSEUNG': 'sangseung',
  'YUDAM': 'yudam',
  'SUIN': 'suin',
  'OUTDOOR_GROUND': 'outdoor',
  'OUTDOOR_UNDERGROUND': 'outdoor',
  'OUTDOOR_UNKNOWN': 'outdoor',
};

// Node item of /nodes, /campus-map and /routes
class NodeDto {
  const NodeDto({
    this.nodeId,
    this.buildingId,
    this.building,
    this.floorLabel,
    this.title,
    this.originalFilename,
    this.photoType,
  });

  factory NodeDto.fromJson(Map<String, dynamic> json) => NodeDto(
    nodeId: json['nodeId'] as String?,
    buildingId: json['buildingId'] as String?,
    building: json['building'] as String?,
    floorLabel: json['floorLabel'] as String?,
    title: json['title'] as String?,
    originalFilename: json['originalFilename'] as String?,
    photoType: json['photoType'] as String?,
  );

  final String? nodeId;
  final String? buildingId;
  final String? building;
  final String? floorLabel;
  final String? title;
  final String? originalFilename;

  // PANORAMA for a 360 photo; any other type shows as a flat photo
  final String? photoType;

  static String? _text(String? s) {
    final t = s?.trim();
    return t == null || t.isEmpty ? null : t;
  }

  static final _bareFloor = RegExp(r'^(\d+|L)$');
  static final _basement = RegExp(r'^B\d+');

  // '1'·'1층' → '1층', 'L' → 'L층', 'B1'·'B1층' → 'B1', 지상·지하·empty → none,
  // other labels such as '연결계단' stay
  static String? floorOf(String? label) {
    final f = _text(label);
    if (f == null || f == '지상' || f == '지하') return null;
    final basement = _basement.firstMatch(f);
    if (basement != null) return basement[0];
    return _bareFloor.hasMatch(f) ? '$f층' : f;
  }

  // Photo spot without map position, or null when id or title is missing
  PanoSpot? toModel() {
    final id = _text(nodeId);
    final name = _text(title);
    if (id == null || name == null) return null;
    final place = _text(building) ?? '야외';
    final floor = floorOf(floorLabel);
    final under =
        buildingId == 'OUTDOOR_UNDERGROUND' ||
        _text(floorLabel) == '지하' ||
        (floor != null && _basement.hasMatch(floor));
    return PanoSpot(
      id: id,
      title: name,
      building: _buildingKeyOfId[buildingId] ?? _buildingKeyOf[place] ?? place,
      floor: floor,
      level: under ? MapLevel.underground : MapLevel.ground,
      flat: photoType != null && photoType != 'PANORAMA',
    );
  }

  static List<PanoSpot> listFrom(Object? data) => [
    for (final item in data! as List)
      ?NodeDto.fromJson(item as Map<String, dynamic>).toModel(),
  ];
}
