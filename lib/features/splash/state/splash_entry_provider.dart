import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router.dart';
import '../data/nfc_places_mock.dart';

// Resolve the NFC tag place from the launch link (?src=nfc&from=<placeId>)
final splashNfcPlaceProvider = Provider<String?>((ref) {
  final uri = ref.watch(routerProvider).routeInformationProvider.value.uri;
  if (uri.queryParameters['src'] != 'nfc') return null;
  return nfcPlaceNames[uri.queryParameters['from']];
});
