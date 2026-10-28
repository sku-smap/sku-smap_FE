import 'report_models.dart';

// Report server: send a report and read back the ones from this device
abstract interface class ReportRepository {
  // False when the server is unreachable; the caller keeps it locally
  Future<bool> send(Report report);

  // Null when the server is not connected
  Future<List<MyReport>?> listMine();
}
