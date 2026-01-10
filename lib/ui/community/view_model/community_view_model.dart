import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../../domain/models/community.dart';
import '../../../data/repositories/community_repository.dart';
import '../../../core/utils/debouncer.dart';

class CommunityViewModel extends ChangeNotifier {
  final CommunityRepository _repository;
  final Debouncer _searchDebouncer = Debouncer(milliseconds: 500);

  CommunityViewModel(this._repository);

  List<Community> _communities = [];
  List<Community> _searchResults = [];
  bool _loading = false;
  bool _searching = false;
  String? _error;
  String _searchQuery = '';
  StreamSubscription<List<Community>>? _searchSubscription;

  List<Community> get communities => _communities;
  List<Community> get searchResults => _searchResults;
  bool get loading => _loading;
  bool get searching => _searching;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  bool get hasSearchQuery => _searchQuery.isNotEmpty;

  void loadCommunities() {
    _repository.watchPublicCommunities().listen(
      (communities) {
        _communities = communities;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  void searchCommunities(String query) {
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
        .searchCommunities(query)
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

  Future<void> createCommunity({
    required String name,
    required String handle,
    required String description,
    required String createdBy,
    String? photoUrl,
    String? bannerUrl,
    List<String>? rules,
    List<String>? tags,
    CommunityVisibility visibility = CommunityVisibility.public,
  }) async {
    _loading = true;
    notifyListeners();

    try {
      await _repository.createCommunity(
        name: name,
        handle: handle,
        description: description,
        createdBy: createdBy,
        photoUrl: photoUrl,
        bannerUrl: bannerUrl,
        rules: rules,
        tags: tags,
        visibility: visibility,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> joinCommunity(String communityId, String userId) async {
    try {
      await _repository.joinCommunity(communityId, userId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> leaveCommunity(String communityId, String userId) async {
    try {
      await _repository.leaveCommunity(communityId, userId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateCommunity({
    required String communityId,
    required String name,
    required String description,
    String? photoUrl,
    String? bannerUrl,
    List<String>? tags,
    List<String>? rules,
    CommunityVisibility? visibility,
  }) async {
    _loading = true;
    notifyListeners();

    try {
      final updates = <String, dynamic>{
        'name': name.trim(),
        'description': description.trim(),
      };

      if (photoUrl != null) updates['photoUrl'] = photoUrl.trim();
      if (bannerUrl != null) updates['bannerUrl'] = bannerUrl.trim();
      if (tags != null) updates['tags'] = tags;
      if (rules != null) updates['rules'] = rules;
      if (visibility != null) {
        updates['visibility'] = visibility == CommunityVisibility.private
            ? 'private'
            : 'public';
      }

      await _repository.updateCommunity(communityId, updates);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCommunity(String communityId) async {
    _loading = true;
    notifyListeners();

    try {
      await _repository.deleteCommunity(communityId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
