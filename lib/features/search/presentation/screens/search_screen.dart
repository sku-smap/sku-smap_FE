import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_toast.dart';
import '../../../campus/data/campus_directory.dart';
import '../../../campus/data/campus_models.dart';
import '../../../campus/state/trip_controller.dart';
import '../../data/candidate_place.dart';
import '../../data/search_models.dart';
import '../../state/search_flow_controller.dart';
import '../../state/voice_controller.dart';
import '../search_routes.dart';
import '../search_tokens.dart';
import '../widgets/place_picker.dart';
import '../widgets/voice_view.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.query = const {}});

  final Map<String, String> query;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final SearchEntry _entry;
  late final bool _forReport;

  // ?pick=from|to, ?mode=voice, ?to= (destination already chosen on home),
  // ?for=report (voice answer goes back to the report sheet)
  @override
  void initState() {
    super.initState();
    final query = widget.query;
    final from = query['pick'] == 'from';
    final linkTo = resolvePlace(query['to']);
    final to = linkTo ?? ref.read(tripProvider).to;
    _forReport = query['for'] == 'report';
    _entry = (
      target: from ? PickTarget.from : PickTarget.to,
      voice: query['mode'] == 'voice',
      intro: from && query['to'] != null && to != null
          ? '${to.name}까지 안내할게요. 지금 계신 곳을 골라주세요'
          : null,
    );
    // A destination in the link wins over the one kept from before
    if (linkTo != null && linkTo.id != ref.read(tripProvider).to?.id) {
      Future.microtask(() => ref.read(tripProvider.notifier).setTo(linkTo));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = searchFlowProvider(_entry);
    final flow = ref.watch(provider);
    final flowController = ref.read(provider.notifier);
    final trip = ref.read(tripProvider.notifier);

    void startRoute() => SearchRoutes.navigate(context, ref.read(tripProvider));

    // Destination first: guide now if the start is known, else ask for it
    void chooseTo(CampusPlace place) {
      trip.setTo(place);
      if (ref.read(tripProvider).from != null) {
        startRoute();
      } else {
        flowController.pick(PickTarget.from);
        flowController.toast('${place.name}까지 안내할게요. 지금 계신 곳을 골라주세요');
      }
    }

    void chooseFrom(CampusPlace place) {
      trip.setFrom(place);
      if (ref.read(tripProvider).to != null) {
        startRoute();
      } else {
        SearchRoutes.close(context);
      }
    }

    // Apply the settled place: report location, start, or destination
    void onVoiceResult(VoiceOutcome outcome) {
      final place = placeOfCandidate(outcome.place);
      if (_forReport) {
        SearchRoutes.close(context, place);
        return;
      }
      final option = outcome.routeOption;
      if (option != null) trip.applyRouteOption(option);
      final reply = outcome.reply;
      if (reply != null) flowController.toast(reply);
      if (flow.target == PickTarget.from) {
        chooseFrom(place);
        return;
      }
      final origin = outcome.origin;
      if (origin != null) trip.setFrom(placeOfCandidate(origin));
      final from = ref.read(tripProvider).from;
      trip.setTo(place);
      if (from != null && from.id != place.id) {
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
                    target: flow.target == PickTarget.from
                        ? SearchTarget.origin
                        : SearchTarget.destination,
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
          AppToast(message: flow.toast),
        ],
      ),
    );
  }
}
