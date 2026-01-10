import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../data/repositories/graffiti_repository.dart';
import '../../core/utils/debouncer.dart';

class DiscoverViewModel extends ChangeNotifier {
  final GraffitiRepository _repository;
  final Debouncer _searchDebouncer = Debouncer(milliseconds: 500);

  DiscoverViewModel(this._repository);

  List<Map<String, dynamic>> _nearbyGraffiti = [];
  List<Map<String, dynamic>> _trendingGraffiti = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _loading = false;
  bool _searching = false;
  String? _error;
  String _searchQuery = '';
  StreamSubscription<List<Map<String, dynamic>>>? _searchSubscription;

  List<Map<String, dynamic>> get nearbyGraffiti => _nearbyGraffiti;
  List<Map<String, dynamic>> get trendingGraffiti => _trendingGraffiti;
  List<Map<String, dynamic>> get searchResults => _searchResults;
  bool get loading => _loading;
  bool get searching => _searching;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  bool get hasSearchQuery => _searchQuery.isNotEmpty;

  void loadNearbyGraffiti() {
    _repository.watchNearbyGraffiti().listen(
      (graffiti) {
        _nearbyGraffiti = graffiti;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  void loadTrendingGraffiti() {
    _repository.watchTrendingGraffiti().listen(
      (graffiti) {
        _trendingGraffiti = graffiti;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  void searchGraffiti(String query) {
    _searchQuery = query;

    if (query.trim().isEmpty) {
      _clearSearch();
      return;
    }

    _searching = true;
    notifyListeners();

    _searchDebouncer.run(() {
      _performSearch(query.trim());
    });
  }

  void _performSearch(String query) {
    _searchSubscription?.cancel();

    _searchSubscription = _repository
        .searchGraffiti(query)
        .listen(
          (results) {
            _searchResults = results;
            _searching = false;
            _error = null;
            notifyListeners();
          },
          onError: (error) {
            _error = error.toString();
            _searching = false;
            notifyListeners();
          },
        );
  }

  void _clearSearch() {
    _searchSubscription?.cancel();
    _searchResults = [];
    _searching = false;
    _searchQuery = '';
    notifyListeners();
  }

  void clearSearch() {
    _clearSearch();
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    _searchSubscription?.cancel();
    super.dispose();
  }
}
