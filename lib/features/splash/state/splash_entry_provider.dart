import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../campus/state/launch_provider.dart';

// NFC tag place from the launch link (?src=nfc&from=<placeId>)
final splashNfcPlaceProvider = Provider<String?>(
  (ref) => ref.watch(launchEntryProvider).nfcPlace,
);
