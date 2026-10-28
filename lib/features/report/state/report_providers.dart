import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../home/state/home_entry_provider.dart';
import '../data/report_api.dart';
import '../data/report_models.dart';
import '../data/report_storage.dart';

// Mock server: ?reports=demo acts connected, otherwise reports stay on device
final reportApiProvider = Provider<MockReportApi>((ref) {
  final demo = ref.watch(homeLaunchQueryProvider)['reports'] == 'demo';
  return MockReportApi(online: demo);
});

final reportStorageProvider = Provider<ReportStorage>(
  (ref) => const ReportStorage(),
);

// Take a site photo; falls back to the library where there is no camera
final photoPickerProvider = Provider<Future<String?> Function()>((ref) {
  return () async {
    final picker = ImagePicker();
    try {
      final shot = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        imageQuality: 80,
      );
      return shot?.path;
    } on PlatformException {
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 80,
      );
      return file?.path;
    }
  };
});

typedef MyReports = ({List<MyReport> rows, bool online});

// Device reports plus server reports, newest first
final myReportsProvider = FutureProvider.autoDispose<MyReports>((ref) async {
  final server = await ref.watch(reportApiProvider).listMine();
  final local = await ref.watch(reportStorageProvider).loadLocal();
  final rows = [...local, ...?server]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return (rows: rows, online: server != null);
});

// Thank-you notice when a report was applied since the last launch
final appliedNoticeProvider = FutureProvider<String?>((ref) async {
  final rows = await ref.watch(reportApiProvider).listMine();
  if (rows == null) return null;
  final fresh = await ref.watch(reportStorageProvider).newlyApplied(rows);
  if (fresh.isEmpty) return null;
  final more = fresh.length > 1 ? ' 외 ${fresh.length - 1}건' : '';
  return "🎉 제보하신 '${fresh.first.kind.title}'$more이 반영됐어요. 고마워요!";
});
