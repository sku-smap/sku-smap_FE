import 'campus_models.dart';

// Street view photo spots
abstract interface class NodeRepository {
  Future<List<PanoSpot>> all();
}
