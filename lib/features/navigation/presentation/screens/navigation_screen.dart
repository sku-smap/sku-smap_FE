import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/data/campus_models.dart';
import '../../../home/presentation/widgets/home_sheet.dart';
import '../../../search/presentation/widgets/search_toast.dart';
import '../../data/campus_floors_mock.dart';
import '../../data/navigation_models.dart';
import '../../data/route_graph.dart';
import '../../state/navigation_controller.dart';
import '../navigation_routes.dart';
import '../navigation_tokens.dart';
import '../widgets/floor_bar.dart';
import '../widgets/floor_sheet.dart';
import '../widgets/link_arrow.dart';
import '../widgets/mini_map.dart';
import '../widgets/pano_view.dart';
import '../widgets/room_overlay.dart';
import '../widgets/route_overview.dart';
import '../widgets/step_card.dart';
import '../widgets/viewer_top_bar.dart';

class NavigationScreen extends ConsumerStatefulWidget {
  const NavigationScreen({super.key, this.query = const {}});

  final Map<String, String> query;

  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen> {
  late final NavigationEntry _entry;
  var _showSteps = false;

  // ?from=&to=&mode=outdoor|elevator&indoor=1
  @override
  void initState() {
    super.initState();
    final q = widget.query;
    _entry = (
      from: q['from'],
      to: q['to'],
      mode:
          RouteMode.values.where((m) => m.name == q['mode']).firstOrNull ??
          RouteMode.outdoor,
      indoor: q['indoor'] == '1',
    );
  }

  // Arrows for every link here; the next step's arrow glows
  List<ViewLink> _links(String node, String? next) {
    final elevator = next == null ? null : elevatorLinkTo(node, next);
    return [
      for (final l in linksOf(node))
        () {
          final viaElevator = elevator != null && l.to == elevator.to;
          final to = viaElevator ? next! : l.to;
          final target = spotById[to]!;
          final floor = target.floor ?? '';
          return ViewLink(
            to: to,
            yaw: linkYawOf(node, l.to),
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

  @override
  Widget build(BuildContext context) {
    final provider = navigationProvider(_entry);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final node = state.node;
    final here = node == null ? null : spotById[node];
    final padding = MediaQuery.paddingOf(context);
    final top = math.max(NavLayout.edge, padding.top);

    if (here == null) {
      return Scaffold(
        backgroundColor: NavColors.photoBg,
        body: Stack(
          children: [
            Center(
              child: TextButton(
                onPressed: () => NavigationRoutes.exit(context),
                child: Text(
                  '돌아가기',
                  style: NavText.button.copyWith(color: NavColors.surface),
                ),
              ),
            ),
            SearchToast(message: state.toast),
          ],
        ),
      );
    }

    final route = state.route;
    final floor = here.outdoor ? null : here.floor;
    final floors = floorsOf(here.building);
    final rooms = floor == null
        ? const <FloorRoom>[]
        : roomsOn(here.building, floor);
    final showRooms = rooms.isNotEmpty && (here.roomList ?? here.center);
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.sizeOf(context).height;

    void openFloorSheet() {
      if (floor == null) return;
      showHomeSheet(
        context,
        child: FloorSheet(
          building: buildingNames[here.building] ?? '',
          floor: floor,
          rooms: rooms,
        ),
      );
    }

    return PopScope(
      canPop: !_showSteps,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _showSteps = false);
      },
      child: Scaffold(
        backgroundColor: NavColors.photoBg,
        body: Stack(
          children: [
            Positioned.fill(
              child: PanoView(
                key: ValueKey(here.id),
                node: here,
                links: _links(here.id, state.next),
                marks: panoMarks[here.id] ?? const [],
                onNavigate: controller.goTo,
                onMark: (m) {
                  if (m.desc.isNotEmpty) controller.toast(m.desc);
                },
              ),
            ),
            Positioned(
              left: NavLayout.edge,
              right: NavLayout.edge,
              top: top,
              child: ViewerTopBar(
                here: here,
                showMap: state.showMap,
                onBack: () => NavigationRoutes.exit(context),
                onToggleMap: controller.toggleMap,
              ),
            ),
            if (state.showMap || floor != null)
              Positioned(
                top: top + NavLayout.mapTop,
                right: NavLayout.edge,
                width: math.min(
                  width * NavLayout.mapWidth,
                  NavLayout.mapMaxWidth,
                ),
                child: MiniMap(
                  here: here,
                  route: route,
                  showMap: state.showMap,
                  onFloorSheet: openFloorSheet,
                ),
              ),
            if (showRooms && floor != null)
              Positioned(
                top: top + NavLayout.floorBarTop,
                right: NavLayout.edge,
                width: math.min(width * NavLayout.mapWidth, 196),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: math.max(
                      80,
                      height - top - NavLayout.floorBarTop - 210,
                    ),
                  ),
                  child: RoomOverlay(
                    key: ValueKey('${here.building}|$floor'),
                    floor: floor,
                    rooms: rooms,
                  ),
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
                    building: buildingNames[here.building] ?? '',
                    current: here.floor,
                    floors: floors,
                    onFloor: controller.goTo,
                  ),
                ),
              ),
            if (route != null)
              Positioned(
                left: NavLayout.cardInset,
                right: NavLayout.cardInset,
                bottom: math.max(NavLayout.cardInset, padding.bottom),
                child: StepCard(
                  state: state,
                  onToggleMute: controller.toggleMute,
                  onShowSteps: () => setState(() => _showSteps = true),
                  onShare: () => NavigationRoutes.share(route),
                  onNavigate: controller.goTo,
                  onExit: () => NavigationRoutes.exit(context),
                  onReport: ({kind}) => NavigationRoutes.report(
                    context,
                    node: here.id,
                    step: state.stepIdx,
                    kind: kind,
                  ),
                  onPraise: controller.praise,
                ),
              ),
            if (_showSteps && route != null)
              Positioned.fill(
                child: RouteOverview(
                  route: route,
                  stepIdx: state.stepIdx,
                  onStep: (id) {
                    controller.goTo(id);
                    setState(() => _showSteps = false);
                  },
                  onClose: () => setState(() => _showSteps = false),
                ),
              ),
            SearchToast(message: state.toast),
          ],
        ),
      ),
    );
  }
}
