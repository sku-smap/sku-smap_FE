import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/data/campus_models.dart';
import '../../../search/presentation/widgets/search_toast.dart';
import '../../data/route_graph.dart';
import '../../state/navigation_controller.dart';
import '../navigation_routes.dart';
import '../navigation_tokens.dart';
import '../widgets/route_overview.dart';
import '../widgets/step_card.dart';
import '../widgets/viewer_stage.dart';

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

  @override
  Widget build(BuildContext context) {
    final provider = navigationProvider(_entry);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final node = state.node;
    final here = node == null ? null : spotById[node];

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

    return PopScope(
      canPop: !_showSteps,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _showSteps = false);
      },
      child: Scaffold(
        backgroundColor: NavColors.photoBg,
        body: ViewerStage(
          here: here,
          route: route,
          next: state.next,
          showMap: state.showMap,
          onNavigate: controller.goTo,
          onMark: (m) {
            if (m.desc.isNotEmpty) controller.toast(m.desc);
          },
          onBack: () => NavigationRoutes.exit(context),
          onToggleMap: controller.toggleMap,
          bottom: route == null
              ? null
              : StepCard(
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
          overlays: [
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
