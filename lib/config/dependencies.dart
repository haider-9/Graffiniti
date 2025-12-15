import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/services/firestore_service.dart';
import '../data/repositories/community_repository.dart';
import '../ui/community/view_model/community_view_model.dart';

class Dependencies {
  static List<SingleChildWidget> getProviders() {
    // Services
    final firestoreService = FirestoreService();

    // Repositories
    final communityRepository = CommunityRepository(firestoreService);

    return [
      // Services
      Provider<FirestoreService>.value(
        value: firestoreService,
      ),

      // Repositories
      Provider<CommunityRepository>.value(
        value: communityRepository,
      ),

      // ViewModels
      ChangeNotifierProvider<CommunityViewModel>(
        create: (_) => CommunityViewModel(communityRepository),
      ),
    ];
  }
}
