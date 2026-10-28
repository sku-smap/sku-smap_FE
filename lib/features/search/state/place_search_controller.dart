import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_exception.dart';
import '../../campus/data/campus_directory.dart';
import '../../campus/data/campus_models.dart';
import '../../campus/state/place_providers.dart';

enum PlaceSearchStatus { idle, loading, done, failed }

class PlaceSearchState {
  const PlaceSearchState({
    this.query = '',
    this.status = PlaceSearchStatus.idle,
    this.results = const [],
    this.error,
  });

  final String query;
  final PlaceSearchStatus status;
  final List<SearchPlace> results;
  final String? error;

  bool get noResults => status == PlaceSearchStatus.done && results.isEmpty;
}

// Server keyword search for one picker; idle means show the start list
class PlaceSearchController extends Notifier<PlaceSearchState> {
  PlaceSearchController(this.key);

  static const debounce = Duration(milliseconds: 300);

  final Object key;
  Timer? _debounce;
  var _seq = 0;

  @override
  PlaceSearchState build() {
    ref.onDispose(() {
      _debounce?.cancel();
      _seq++;
    });
    return const PlaceSearchState();
  }

  // Wait for typing to pause; clearing the field restores the start list
  void setQuery(String text) {
    final query = text.trim();
    if (query == state.query) return;
    _debounce?.cancel();
    if (query.isEmpty) {
      _seq++;
      state = const PlaceSearchState();
      return;
    }
    state = PlaceSearchState(query: query, status: PlaceSearchStatus.loading);
    _debounce = Timer(debounce, () => _run(query));
  }

  void retry() {
    if (state.query.isNotEmpty) _run(state.query);
  }

  // Only the newest request may update the list
  Future<void> _run(String query) async {
    final seq = ++_seq;
    state = PlaceSearchState(query: query, status: PlaceSearchStatus.loading);
    try {
      final results = await ref.read(placeRepositoryProvider).search(query);
      if (seq != _seq) return;
      registerPlaces(results);
      state = PlaceSearchState(
        query: query,
        status: PlaceSearchStatus.done,
        results: results,
      );
    } on AppException catch (e) {
      if (seq != _seq) return;
      state = PlaceSearchState(
        query: query,
        status: PlaceSearchStatus.failed,
        error: e.message,
      );
    }
  }
}

final placeSearchProvider = NotifierProvider.autoDispose
    .family<PlaceSearchController, PlaceSearchState, Object>(
      PlaceSearchController.new,
    );
