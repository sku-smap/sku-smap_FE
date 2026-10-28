import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/data/campus_models.dart';
import '../../../home/state/home_controller.dart';
import '../../data/search_models.dart';
import '../../state/search_flow_controller.dart';
import '../search_routes.dart';
import '../search_tokens.dart';
import '../widgets/place_picker.dart';
import '../widgets/search_toast.dart';
import '../widgets/voice_view.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.query = const {}});

  final Map<String, String> query;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final SearchEntry _entry;

  // ?pick=from|to, ?mode=voice, ?to= (destination already chosen on home)
  @override
  void initState() {
    super.initState();
    final query = widget.query;
    final from = query['pick'] == 'from';
    final to = ref.read(homeControllerProvider).to;
    _entry = (
      target: from ? PickTarget.from : PickTarget.to,
      voice: query['mode'] == 'voice',
      intro: from && query['to'] != null && to != null
          ? '${to.name}까지 안내할게요. 지금 계신 곳을 골라주세요'
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = searchFlowProvider(_entry);
    final flow = ref.watch(provider);
    final flowController = ref.read(provider.notifier);
    final home = ref.read(homeControllerProvider.notifier);

    void startRoute() {
      final s = ref.read(homeControllerProvider);
      final from = s.from;
      final to = s.to;
      if (from == null || to == null) return;
      SearchRoutes.navigate(
        context,
        from: from,
        to: to,
        mode: s.mode,
        indoor: s.indoor,
      );
    }

    // Destination first: guide now if the start is known, else ask for it
    void chooseTo(CampusPlace place) {
      home.setTo(place);
      if (ref.read(homeControllerProvider).from != null) {
        startRoute();
      } else {
        flowController.pick(PickTarget.from);
        flowController.toast('${place.name}까지 안내할게요. 지금 계신 곳을 골라주세요');
      }
    }

    void chooseFrom(CampusPlace place) {
      home.setFrom(place);
      if (ref.read(homeControllerProvider).to != null) {
        startRoute();
      } else {
        SearchRoutes.close(context);
      }
    }

    // Apply what was heard: set places, then guide or ask for the start
    void onVoiceResult(VoiceIntent intent) {
      final to = intent.to;
      if (to == null) return;
      final from = intent.from?.spot ?? ref.read(homeControllerProvider).from;
      home.setTo(to.spot);
      if (intent.from != null && from != null) home.setFrom(from);
      if (intent.avoidStairs) home.setMode(RouteMode.elevator);
      final reply = intent.reply;
      if (reply != null) flowController.toast(reply);
      if (from != null && from.id != to.id) {
        startRoute();
      } else {
        flowController.pick(PickTarget.from);
      }
    }

    return Scaffold(
      backgroundColor: SearchColors.surface,
      resizeToAvoidBottomInset: !flow.voice,
      body: Stack(
        children: [
          Positioned.fill(
            child: flow.voice
                ? VoiceView(
                    onClose: () => SearchRoutes.close(context),
                    onResult: onVoiceResult,
                  )
                : SafeArea(
                    bottom: false,
                    child: PlacePicker(
                      key: ValueKey(flow.target),
                      target: flow.target,
                      onPick: flow.target == PickTarget.from
                          ? chooseFrom
                          : chooseTo,
                      onClose: () => SearchRoutes.close(context),
                      onVoice: flowController.openVoice,
                    ),
                  ),
          ),
          SearchToast(message: flow.toast),
        ],
      ),
    );
  }
}
