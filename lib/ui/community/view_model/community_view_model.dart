import 'package:flutter/foundation.dart';
import '../../../domain/models/community.dart';
import '../../../data/repositories/community_repository.dart';

class CommunityViewModel extends ChangeNotifier {
  final CommunityRepository _repository;

  CommunityViewModel(this._repository);

  List<Community> _communities = [];
  bool _loading = false;
  String? _error;

  List<Community> get communities => _communities;
  bool get loading => _loading;
  String? get error => _error;

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
