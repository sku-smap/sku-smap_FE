import '../campus_models.dart';
import 'node_dto.dart';

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
    aliases: _aliasesOf(json['aliases']),
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
  final List<String>? aliases;
  final String? sub;

  // A string array; an older single string is split on | or ,
  static List<String> _aliasesOf(Object? raw) {
    final items = switch (raw) {
      final List<dynamic> list => list.whereType<String>(),
      final String text => text.split(RegExp('[|,]')),
      _ => const <String>[],
    };
    return {
      for (final a in items)
        if (a.trim().isNotEmpty) a.trim(),
    }.toList();
  }

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
      aliases: aliases ?? const [],
    );
  }

  // Building, floor and room when the server sends no sub
  String? _composedSub() {
    final room = _text(roomNo);
    final parts = [
      ?_text(building),
      ?NodeDto.floorOf(floorLabel),
      if (room != null) room.endsWith('호') ? room : '$room호',
    ];
    return parts.isEmpty ? null : parts.join(' ');
  }

  static List<SearchPlace> listFrom(Object? data) => [
    for (final item in data! as List)
      ?PlaceDto.fromJson(item as Map<String, dynamic>).toModel(),
  ];
}
