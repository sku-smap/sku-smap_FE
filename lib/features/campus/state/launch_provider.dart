import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router.dart';
import '../data/campus_directory.dart';
import '../data/campus_models.dart';

// Query of the link that opened the app (shared link, NFC tag, demo flags)
final launchQueryProvider = Provider<Map<String, String>>((ref) {
  return ref
      .watch(routerProvider)
      .routeInformationProvider
      .value
      .uri
      .queryParameters;
});

class LaunchEntry {
  const LaunchEntry({
    this.from,
    this.to,
    this.nfcPlace,
    this.wetKind,
    this.demoClosures = false,
    this.demoReports = false,
    this.onCampus = false,
    this.edit = false,
  });

  // ?src=nfc&from=, ?to=, ?weather=rain, ?closures=demo, ?reports=demo,
  // ?location=campus, ?edit=1
  factory LaunchEntry.fromQuery(Map<String, String> q) => LaunchEntry(
    from: q['from'],
    to: q['to'],
    nfcPlace: q['src'] == 'nfc' ? resolvePlace(q['from'])?.name : null,
    wetKind: WetKind.values.where((k) => k.name == q['weather']).firstOrNull,
    demoClosures: q['closures'] == 'demo',
    demoReports: q['reports'] == 'demo',
    onCampus: q['location'] == 'campus',
    edit: q['edit'] == '1',
  );

  final String? from;
  final String? to;
  final String? nfcPlace;
  final WetKind? wetKind;
  final bool demoClosures;
  final bool demoReports;
  final bool onCampus;
  final bool edit;
}

final launchEntryProvider = Provider<LaunchEntry>(
  (ref) => LaunchEntry.fromQuery(ref.watch(launchQueryProvider)),
);
