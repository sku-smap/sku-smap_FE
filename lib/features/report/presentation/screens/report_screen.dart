import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../home/state/home_controller.dart';
import '../../../search/data/search_models.dart';
import '../../../search/presentation/widgets/place_picker.dart';
import '../../data/report_models.dart';
import '../../state/report_controller.dart';
import '../../state/report_providers.dart';
import '../report_routes.dart';
import '../report_tokens.dart';
import '../widgets/report_form.dart';
import '../widgets/report_kind_list.dart';
import '../widgets/report_toast.dart';

// Report sheet over the screen it was opened from (?node=&step=&kind=)
class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key, this.query = const {}});

  final Map<String, String> query;

  // A see-through page so the opening screen stays behind the sheet
  static Page<void> page(GoRouterState state) => CustomTransitionPage<void>(
    key: state.pageKey,
    opaque: false,
    barrierColor: ReportColors.backdrop,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    child: ReportScreen(query: state.uri.queryParameters),
    transitionsBuilder: (context, animation, secondary, child) =>
        SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
  );

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  late final ReportEntry _entry;
  final _memo = TextEditingController();

  @override
  void initState() {
    super.initState();
    final q = widget.query;
    final node = q['node'];
    final from = ref.read(homeControllerProvider).from;
    _entry = (
      kind: ReportKind.values.where((k) => k.name == q['kind']).firstOrNull,
      node: node,
      step: int.tryParse(q['step'] ?? ''),
      // From home the current start is the default location
      near: node == null && from != null ? reportSpotFromPlace(from) : null,
    );
  }

  @override
  void dispose() {
    _memo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = reportControllerProvider(_entry);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final picking = state.picking;

    Future<void> send() async {
      final overlay = Overlay.of(context, rootOverlay: true);
      final thanks = await controller.send();
      if (thanks == null || !context.mounted) return;
      ReportRoutes.close(context);
      showReportToast(overlay, thanks);
    }

    Future<void> addPhoto() async {
      final path = await ref.read(photoPickerProvider)();
      if (path != null) controller.setPhoto(path);
    }

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => ReportRoutes.close(context),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _SheetFrame(
              child: state.kind == null
                  ? ReportKindList(
                      onKind: controller.setKind,
                      onOpenMine: () => ReportRoutes.mine(context),
                    )
                  : ReportForm(
                      state: state,
                      controller: controller,
                      fixedKind: _entry.kind != null,
                      memo: _memo,
                      onAddPhoto: addPhoto,
                      onSend: send,
                    ),
            ),
          ),
          if (picking != null)
            Positioned.fill(
              child: ColoredBox(
                color: ReportColors.surface,
                child: SafeArea(
                  bottom: false,
                  child: PlacePicker(
                    target: PickTarget.from,
                    title: switch (picking) {
                      ReportPick.loc => '어디인가요?',
                      ReportPick.from => '어디서 출발하는 길인가요?',
                      ReportPick.to => '어디까지 가는 길인가요?',
                    },
                    onPick: (place) =>
                        controller.picked(reportSpotFromPlace(place)),
                    onClose: () => controller.startPick(null),
                    onVoice: () => ReportRoutes.voice(context),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final bottom = math.max(20.0, media.padding.bottom);
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: double.infinity,
          maxHeight:
              (media.size.height - keyboard) * ReportLayout.sheetMaxHeight,
        ),
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: '제보하기',
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: ReportColors.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(ReportLayout.sheetRadius),
              ),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                ReportLayout.sheetSide,
                12,
                ReportLayout.sheetSide,
                keyboard > 0 ? 20 : bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: ReportLayout.gripWidth,
                      height: ReportLayout.gripHeight,
                      decoration: BoxDecoration(
                        color: ReportColors.line,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
