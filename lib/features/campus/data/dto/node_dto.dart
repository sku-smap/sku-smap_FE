import '../campus_models.dart';
import '../mock/campus_floors_mock.dart';

final _buildingKeyOf = {
  for (final MapEntry(:key, :value) in buildingNames.entries) value: key,
  '야외': 'outdoor',
};

// GET /api/v1/nodes item (NodeResponseDTO)
class NodeDto {
  const NodeDto({
    this.nodeId,
    this.building,
    this.floorLabel,
    this.title,
    this.originalFilename,
  });

  factory NodeDto.fromJson(Map<String, dynamic> json) => NodeDto(
    nodeId: json['nodeId'] as String?,
    building: json['building'] as String?,
    floorLabel: json['floorLabel'] as String?,
    title: json['title'] as String?,
    originalFilename: json['originalFilename'] as String?,
  );

  final String? nodeId;
  final String? building;
  final String? floorLabel;
  final String? title;
  final String? originalFilename;

  static String? _text(String? s) {
    final t = s?.trim();
    return t == null || t.isEmpty ? null : t;
  }

  // '1' → '1층', 'L' → 'L층', 'B1' stays, empty → none
  static String? floorOf(String? label) {
    final f = _text(label);
    if (f == null || f.startsWith('B') || f.endsWith('층')) return f;
    return '$f층';
  }

  // Photo spot without map position, or null when id or title is missing
  PanoSpot? toModel() {
    final id = _text(nodeId);
    final name = _text(title);
    if (id == null || name == null) return null;
    final place = _text(building) ?? '야외';
    final floor = floorOf(floorLabel);
    return PanoSpot(
      id: id,
      title: name,
      building: _buildingKeyOf[place] ?? place,
      floor: floor,
      level: floor != null && floor.startsWith('B')
          ? MapLevel.underground
          : MapLevel.ground,
    );
  }

  static List<PanoSpot> listFrom(Object? data) => [
    for (final item in data! as List)
      ?NodeDto.fromJson(item as Map<String, dynamic>).toModel(),
  ];
}
