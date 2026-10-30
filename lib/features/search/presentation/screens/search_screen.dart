import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_toast.dart';
import '../../../campus/data/campus_directory.dart';
import '../../../campus/data/campus_models.dart';
import '../../../campus/state/trip_controller.dart';
import '../../data/candidate_place.dart';
import '../../data/search_models.dart';
import '../../state/search_flow_controller.dart';
import '../../../home/state/home_notice.dart';
import '../../state/voice_controller.dart';
import '../search_routes.dart';
import '../search_tokens.dart';
import '../widgets/place_picker.dart';
import '../widgets/voice_view.dart';

// Toast after a route sentence, by which ends it settled
String routeSearchNotice({required bool from, required bool to}) =>
    switch ((from, to)) {
      (true, true) => '경로 설정이 완료되었습니다.',
      (false, true) => '출발지를 인식하지 못했습니다. 출발지를 입력해주세요.',
      (true, false) => '도착지를 인식하지 못했습니다. 도착지를 입력해주세요.',
      (false, false) => '출발지·도착지를 인식하지 못했습니다. 다시 말하거나 입력해주세요.',
    };

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

    // Both ends set: back to the home route card, where 길찾기 starts guidance
    void toRouteCard() => SearchRoutes.home(context);

    // Destination first: ask for a missing start, else return to the card
    void chooseTo(CampusPlace place) {
      trip.setTo(place);
      if (ref.read(tripProvider).from != null) {
        toRouteCard();
      } else {
        flowController.pick(PickTarget.from);
        flowController.toast('${place.name}까지 안내할게요. 지금 계신 곳을 골라주세요');
      }
    }

    void chooseFrom(CampusPlace place) {
      trip.setFrom(place);
      if (ref.read(tripProvider).to != null) {
        toRouteCard();
      } else {
        SearchRoutes.close(context);
      }
    }

    // Apply the settled place: report location, start, or destination
    void onVoiceResult(VoiceOutcome outcome) {
      final named = outcome.place;
      final origin = outcome.origin;
      final place = named == null ? null : placeOfCandidate(named);
      if (_forReport) {
        SearchRoutes.close(
          context,
          place ?? (origin == null ? null : placeOfCandidate(origin)),
        );
        return;
      }
      final option = outcome.routeOption;
      if (option != null) trip.applyRouteOption(option);
      if (flow.target == PickTarget.from) {
        final reply = outcome.reply;
        if (reply != null) flowController.toast(reply);
        if (place != null) chooseFrom(place);
        return;
      }
      // A route sentence replaces both ends and says what it could not find
      final from = origin == null ? null : placeOfCandidate(origin);
      trip.setEnds(from: from, to: place);
      ref
          .read(homeNoticeProvider.notifier)
          .show(routeSearchNotice(from: from != null, to: place != null));
      toRouteCard();
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
