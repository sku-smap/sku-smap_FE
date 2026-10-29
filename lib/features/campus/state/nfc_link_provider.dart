import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/campus_directory.dart';
import 'launch_provider.dart';
import 'node_providers.dart';
import 'place_providers.dart';

// One tag link (?src=nfc&from=<place or node id>); seq tells repeat taps apart
class NfcTap {
  const NfcTap(this.id, {this.warm = false, this.seq = 0});

  final String id;

  // Arrived while the app was already running
  final bool warm;
  final int seq;
}

String? nfcIdOf(Map<String, String> query) {
  if (query['src'] != 'nfc') return null;
  final id = query['from']?.trim();
  return id == null || id.isEmpty ? null : id;
}

class NfcLinkController extends Notifier<NfcTap?> {
  @override
  NfcTap? build() {
    final id = nfcIdOf(ref.watch(launchQueryProvider));
    return id == null ? null : NfcTap(id);
  }

  // Links the platform hands over later; other in-app routes carry no src=nfc
  void receive(Uri uri) {
    final id = nfcIdOf(uri.queryParameters);
    if (id == null) return;
    state = NfcTap(id, warm: true, seq: (state?.seq ?? 0) + 1);
  }
}

final nfcLinkProvider = NotifierProvider<NfcLinkController, NfcTap?>(
  NfcLinkController.new,
);

typedef NfcMessage = ({int seq, String text});

const nfcUnknown = '태그한 위치를 찾지 못했어요. 출발지를 직접 골라 주세요';

// Toast for a tag: where a warm tap starts, or that the spot is unknown once
// every list that could name it has loaded
final nfcNoticeProvider = Provider<NfcMessage?>((ref) {
  final tap = ref.watch(nfcLinkProvider);
  if (tap == null) return null;
  final place = resolvePlace(tap.id);
  if (place != null) {
    return tap.warm
        ? (seq: tap.seq, text: '지금 계신 ${place.name}에서 시작할게요')
        : null;
  }
  final lists = [
    ref.watch(placeCatalogProvider),
    ref.watch(nodeCatalogProvider),
  ];
  if (lists.any((v) => v.isLoading)) return null;
  return resolvePlace(tap.id) == null ? (seq: tap.seq, text: nfcUnknown) : null;
});
