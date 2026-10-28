import '../campus_models.dart';

// GET /api/v1/places item (PlaceResponseDTO)
class PlaceDto {
  const PlaceDto({
    this.placeId,
    this.name,
    this.kind,
    this.building,
    this.floorLabel,
    this.roomNo,
    this.arriveNodeId,
    this.arriveNodeTitle,
    this.doorPhoto,
    this.aliases,
    this.sub,
  });

  factory PlaceDto.fromJson(Map<String, dynamic> json) => PlaceDto(
    placeId: json['placeId'] as String?,
    name: json['name'] as String?,
    kind: json['kind'] as String?,
    building: json['building'] as String?,
    floorLabel: json['floorLabel'] as String?,
    roomNo: json['roomNo'] as String?,
    arriveNodeId: json['arriveNodeId'] as String?,
    arriveNodeTitle: json['arriveNodeTitle'] as String?,
    doorPhoto: json['doorPhoto'] as String?,
    aliases: json['aliases'] as String?,
    sub: json['sub'] as String?,
  );

  final String? placeId;
  final String? name;
  final String? kind;
  final String? building;
  final String? floorLabel;
  final String? roomNo;
  final String? arriveNodeId;
  final String? arriveNodeTitle;
  final String? doorPhoto;
  final String? aliases;
  final String? sub;

  static String? _text(String? s) {
    final t = s?.trim();
    return t == null || t.isEmpty ? null : t;
  }

  // App place, or null when id, name or arrival spot is missing
  SearchPlace? toModel() {
    final id = _text(placeId);
    final label = _text(name);
    final node = _text(arriveNodeId);
    if (id == null || label == null || node == null) return null;
    return SearchPlace(
      id: id,
      name: label,
      kind:
          PlaceKind.values.where((k) => k.name == kind).firstOrNull ??
          PlaceKind.facility,
      node: node,
      sub: _text(sub) ?? _composedSub(),
      aliases: [
        for (final a in (aliases ?? '').split(','))
          if (a.trim().isNotEmpty) a.trim(),
      ],
    );
  }

  // Building, floor and room when the server sends no sub
  String? _composedSub() {
    final floor = _text(floorLabel);
    final room = _text(roomNo);
    final parts = [
      ?_text(building),
      if (floor != null) '$floor층',
      if (room != null) '$room호',
    ];
    return parts.isEmpty ? null : parts.join(' ');
  }

  static List<SearchPlace> listFrom(Object? data) => [
    for (final item in data! as List)
      ?PlaceDto.fromJson(item as Map<String, dynamic>).toModel(),
  ];
}
