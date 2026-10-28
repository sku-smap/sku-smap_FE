import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/data/campus_models.dart';
import '../../../home/state/home_controller.dart';
import '../../../navigation/data/route_graph.dart';
import '../../../navigation/presentation/navigation_routes.dart';
import '../../../navigation/presentation/navigation_tokens.dart';
import '../../../navigation/presentation/widgets/viewer_stage.dart';
import '../../../search/presentation/widgets/search_toast.dart';
import '../../state/explore_controller.dart';
import '../explore_routes.dart';
import '../widgets/explore_card.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key, this.query = const {}});

  final Map<String, String> query;

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  late final ExploreEntry _entry;

  // ?building=&floor= from the building sheet; otherwise the home start
  @override
  void initState() {
    super.initState();
    _entry = exploreEntryFor(
      widget.query,
      ref.read(homeControllerProvider).from,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = exploreProvider(_entry);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final here = spotById[state.node]!;

    // Set this spot as the start, then ask for the destination
    void startHere() {
      ref
          .read(homeControllerProvider.notifier)
          .setFrom(CampusPlace(id: here.id, name: here.title));
      ExploreRoutes.pickTo(context);
    }

    return Scaffold(
      backgroundColor: NavColors.photoBg,
      body: ViewerStage(
        here: here,
        route: null,
        next: null,
        showMap: state.showMap,
        onNavigate: controller.goTo,
        onMark: (m) {
          if (m.desc.isNotEmpty) controller.toast(m.desc);
        },
        onBack: () => NavigationRoutes.exit(context),
        onToggleMap: controller.toggleMap,
        bottom: ExploreCard(
          title: here.title,
          onStart: startHere,
          onReport: () => NavigationRoutes.report(context, node: here.id),
        ),
        overlays: [SearchToast(message: state.toast)],
      ),
    );
  }
}
