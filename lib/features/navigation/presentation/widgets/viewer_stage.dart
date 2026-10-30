import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../campus/data/campus_directory.dart';
import '../../../campus/data/campus_models.dart';
import '../../../campus/data/mock/campus_floors_mock.dart';
import '../../../home/presentation/widgets/home_sheet.dart';
import '../../data/navigation_models.dart';
import '../../data/route_graph.dart';
import '../navigation_tokens.dart';
import 'floor_bar.dart';
import 'floor_sheet.dart';
import 'link_arrow.dart';
import 'mini_map.dart';
import 'pano_view.dart';
import 'viewer_top_bar.dart';

// Arrows for every link here; the next step's arrow glows
List<ViewLink> viewLinks(
  String node,
  String? next, [
  Map<String, double> yawOverrides = const {},
]) {
  final elevator = next == null ? null : elevatorLinkTo(node, next);
  return [
    for (final l in linksOf(node))
      () {
        final viaElevator = elevator != null && l.to == elevator.to;
        final to = viaElevator ? next! : l.to;
        final target = spotById[to]!;
        final floor = target.floor ?? '';
        final yaw = linkYawOf(node, l.to, yawOverrides);
        return ViewLink(
          to: to,
          yaw: yaw,
          label: viaElevator ? '엘리베이터 → $floor' : target.title,
          sub: viaElevator
              ? target.title
              : l.via == Via.walk
              ? null
              : l.via == Via.elevator || l.via == Via.stairs
              ? '${l.via.label} → $floor'
              : l.via.label,
          primary: to == next,
        );
      }(),
  ];
}

// 360 photo with top bar, mini map and floor UI, shared by guide and explore
class ViewerStage extends StatelessWidget {
  const ViewerStage({
    super.key,
    required this.here,
    required this.route,
    required this.next,
    required this.showMap,
    required this.onNavigate,
    required this.onMark,
    required this.onBack,
    required this.onToggleMap,
    required this.bottom,
    this.overlays = const [],
    this.yawOverrides = const {},
    this.onPhotoTap,
    this.editPanel,
  });

  final PanoSpot here;
  final ActiveRoute? route;
  final String? next;
  final bool showMap;
  final ValueChanged<String> onNavigate;
  final ValueChanged<PanoMark> onMark;
  final VoidCallback onBack;
  final VoidCallback onToggleMap;
  final Widget? bottom;
  final List<Widget> overlays;
  final Map<String, double> yawOverrides;
  final ValueChanged<double>? onPhotoTap;
  final Widget? editPanel;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final top = math.max(NavLayout.edge, padding.top);
    final floor = here.outdoor ? null : here.floor;
    final floors = floorsOf(here.building);
    final rooms = floor == null
        ? const <FloorRoom>[]
        : roomsOn(here.building, floor);
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.sizeOf(context).height;
    final card = bottom;

    void openFloorSheet() {
      if (floor == null) return;
      showHomeSheet(
        context,
        child: FloorSheet(
          building: buildingNameOf(here.building),
          floor: floor,
          rooms: rooms,
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: PanoView(
            key: ValueKey(here.id),
            node: here,
            links: viewLinks(here.id, next, yawOverrides),
            marks: panoMarks[here.id] ?? const [],
            onNavigate: onNavigate,
            onMark: onMark,
            onPhotoTap: onPhotoTap,
          ),
        ),
        Positioned(
          left: NavLayout.edge,
          right: NavLayout.edge,
          top: top,
          child: ViewerTopBar(
            here: here,
            showMap: showMap,
            onBack: onBack,
            onToggleMap: onToggleMap,
          ),
        ),
        if (showMap || floor != null)
          Positioned(
            top: top + NavLayout.mapTop,
            right: NavLayout.edge,
            width: math.min(width * NavLayout.mapWidth, NavLayout.mapMaxWidth),
            child: MiniMap(
              here: here,
              route: route,
              showMap: showMap,
              onFloorSheet: openFloorSheet,
            ),
          ),
        if (floors.length > 1)
          Positioned(
            top: top + NavLayout.floorBarTop,
            left: NavLayout.edge,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: math.max(
                  80,
                  height - top - NavLayout.floorBarTop - 250,
                ),
              ),
              child: FloorBar(
                building: buildingNameOf(here.building),
                current: here.floor,
                floors: floors,
                onFloor: onNavigate,
              ),
            ),
          ),
        if (editPanel case final panel?)
          Positioned(
            top: top + NavLayout.mapTop,
            left: NavLayout.editInset,
            right: NavLayout.editInset,
            child: Align(alignment: Alignment.topLeft, child: panel),
          ),
        if (card != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: math.max(NavLayout.cardInset, padding.bottom),
            child: Center(
              child: SizedBox(
                width: math.min(
                  NavLayout.cardWidth,
                  width - NavLayout.cardInset * 2,
                ),
                child: card,
              ),
            ),
          ),
        ...overlays,
      ],
    );
  }
}
