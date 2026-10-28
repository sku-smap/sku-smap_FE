import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_toast.dart';
import '../../../campus/data/campus_directory.dart';
import '../../../campus/state/launch_provider.dart';
import '../../../campus/state/trip_controller.dart';
import '../../../navigation/presentation/navigation_routes.dart';
import '../../../navigation/presentation/navigation_tokens.dart';
import '../../../navigation/presentation/widgets/viewer_stage.dart';
import '../../../navigation/state/link_yaw_controller.dart';
import '../../state/explore_controller.dart';
import '../explore_routes.dart';
import '../widgets/edit_panel.dart';
import '../widgets/explore_card.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key, this.query = const {}});

  final Map<String, String> query;

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  late final ExploreEntry _entry;

  // ?building=&floor= from the building sheet, ?edit=1 for the team's fix mode
  @override
  void initState() {
    super.initState();
    _entry = exploreEntryFor(
      widget.query,
      ref.read(tripProvider).from,
      edit: widget.query['edit'] == '1' || ref.read(launchEntryProvider).edit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = exploreProvider(_entry);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final here = spotById[state.node]!;
    final overrides = ref.watch(linkYawProvider).value ?? const {};

    // Set this spot as the start, then ask for the destination
    void startHere() {
      ref.read(tripProvider.notifier).setFrom(here.spot);
      ExploreRoutes.pickTo(context);
    }

    // Copy saved fixes as JSON for the data file
    Future<void> copyFixes() async {
      await Clipboard.setData(ClipboardData(text: jsonEncode(overrides)));
      controller.toast('보정값 ${overrides.length}개를 복사했어요');
    }

    return Scaffold(
      backgroundColor: NavColors.photoBg,
      body: ViewerStage(
        here: here,
        route: null,
        next: null,
        showMap: state.showMap,
        yawOverrides: overrides,
        onNavigate: controller.goTo,
        onMark: (m) {
          if (m.desc.isNotEmpty) controller.toast(m.desc);
        },
        onBack: () => NavigationRoutes.exit(context),
        onToggleMap: controller.toggleMap,
        onPhotoTap: _entry.edit ? controller.fixDirection : null,
        editPanel: _entry.edit
            ? EditPanel(
                links: [
                  for (final l in viewLinks(here.id, null, overrides))
                    (to: l.to, label: l.label, yaw: l.yaw),
                ],
                selected: state.editLink,
                fixes: overrides.length,
                onSelect: controller.selectEditLink,
                onCopy: copyFixes,
              )
            : null,
        bottom: ExploreCard(
          title: here.title,
          onStart: startHere,
          onReport: () => NavigationRoutes.report(context, node: here.id),
        ),
        overlays: [AppToast(message: state.toast)],
      ),
    );
  }
}
