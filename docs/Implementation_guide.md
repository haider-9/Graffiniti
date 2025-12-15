# Flutter Official Architecture (Google's Compass App Pattern)

## Folder Structure

```
lib/
├── ui/
│   ├── core/
│   │   ├── ui/
│   │   │   ├── app_button.dart
│   │   │   ├── loading_indicator.dart
│   │   │   └── error_message.dart
│   │   └── themes/
│   │       ├── app_theme.dart
│   │       └── colors.dart
│   │
│   ├── community/
│   │   ├── view_model/
│   │   │   └── community_view_model.dart
│   │   └── widgets/
│   │       ├── communities_screen.dart
│   │       ├── community_detail_screen.dart
│   │       └── community_card.dart
│   │
│   ├── graffiti/
│   │   ├── view_model/
│   │   │   └── graffiti_view_model.dart
│   │   └── widgets/
│   │       ├── graffiti_feed_screen.dart
│   │       ├── create_graffiti_screen.dart
│   │       └── graffiti_card.dart
│   │
│   └── profile/
│       ├── view_model/
│       │   └── profile_view_model.dart
│       └── widgets/
│           └── profile_screen.dart
│
├── domain/
│   └── models/
│       ├── community.dart
│       ├── graffiti.dart
│       ├── user.dart
│       └── member.dart
│
├── data/
│   ├── repositories/
│   │   ├── community_repository.dart
│   │   ├── graffiti_repository.dart
│   │   └── user_repository.dart
│   │
│   ├── services/
│   │   ├── firestore_service.dart
│   │   ├── storage_service.dart
│   │   └── auth_service.dart
│   │
│   └── model/
│       ├── community_api_model.dart
│       ├── graffiti_api_model.dart
│       └── user_api_model.dart
│
├── config/
│   ├── firebase_config.dart
│   └── app_config.dart
│
├── utils/
│   ├── validators.dart
│   ├── formatters.dart
│   └── constants.dart
│
├── routing/
│   └── app_router.dart
│
├── main.dart
├── main_development.dart
└── main_staging.dart

test/
├── data/
│   └── repositories/
├── domain/
│   └── models/
├── ui/
│   └── community/
└── utils/

testing/
├── fakes/
│   └── fake_firestore_service.dart
└── models/
    └── test_data.dart
```

---

## Layer Breakdown

### 1️⃣ **UI Layer** (`ui/`)
**Organized by feature** - each feature gets its own folder

#### `ui/core/`
Shared widgets and themes used across features
- Custom buttons, loading indicators, dialogs
- Brand colors, text styles, theme data

#### `ui/{feature_name}/`
Each feature has:
- **view_model/** - State management (ChangeNotifier)
- **widgets/** - Screens and feature-specific widgets

**Rule:** One screen = One view model

---

### 2️⃣ **Domain Layer** (`domain/`)
**Pure business objects** - no Firebase, no JSON

```dart
// domain/models/community.dart
class Community {
  final String id;
  final String name;
  final String description;
  final int memberCount;
  
  Community({
    required this.id,
    required this.name,
    required this.description,
    required this.memberCount,
  });
}
```

**Why separate from API models?**
- Domain models = what your app cares about
- API models = what Firebase sends/receives
- Keeps business logic clean

---

### 3️⃣ **Data Layer** (`data/`)
**Organized by type** (not feature) - shared across app

#### `data/services/`
Talk to external systems
```dart
// data/services/firestore_service.dart
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  Future<DocumentSnapshot> getDocument(String collection, String id) {
    return _db.collection(collection).doc(id).get();
  }
  
  Stream<QuerySnapshot> streamCollection(String collection) {
    return _db.collection(collection).snapshots();
  }
}
```

#### `data/repositories/`
Convert API data to domain models, handle business logic
```dart
// data/repositories/community_repository.dart
class CommunityRepository {
  final FirestoreService _firestoreService;
  final StorageService _storageService;
  
  CommunityRepository(this._firestoreService, this._storageService);
  
  Future<Community> getCommunity(String id) async {
    final doc = await _firestoreService.getDocument('communities', id);
    final apiModel = CommunityApiModel.fromFirestore(doc);
    return apiModel.toDomain(); // Convert to domain model
  }
  
  Stream<List<Community>> watchCommunities() {
    return _firestoreService.streamCollection('communities').map(
      (snapshot) => snapshot.docs
        .map((doc) => CommunityApiModel.fromFirestore(doc).toDomain())
        .toList(),
    );
  }
}
```

#### `data/model/`
API-specific models (knows about Firestore types)
```dart
// data/model/community_api_model.dart
class CommunityApiModel {
  final String id;
  final String name;
  final String description;
  final int memberCount;
  final Timestamp createdAt; // Firebase-specific type
  
  factory CommunityApiModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityApiModel(
      id: doc.id,
      name: data['name'],
      description: data['description'],
      memberCount: data['memberCount'],
      createdAt: data['createdAt'],
    );
  }
  
  Map<String, dynamic> toMap() { ... }
  
  // Convert to domain model
  Community toDomain() {
    return Community(
      id: id,
      name: name,
      description: description,
      memberCount: memberCount,
    );
  }
}
```

---

## Implementation Flow

### Example: Building Community Feature

#### Step 1: Domain Model
```dart
// domain/models/community.dart
class Community {
  final String id;
  final String name;
  // Pure Dart, no Firebase
}
```

#### Step 2: API Model
```dart
// data/model/community_api_model.dart
class CommunityApiModel {
  final String id;
  final String name;
  final Timestamp createdAt; // Firebase type OK here
  
  factory CommunityApiModel.fromFirestore(DocumentSnapshot doc) { }
  Community toDomain() { } // Convert to domain
}
```

#### Step 3: Service (if needed)
```dart
// data/services/firestore_service.dart
// Generic Firestore operations shared across features
```

#### Step 4: Repository
```dart
// data/repositories/community_repository.dart
class CommunityRepository {
  final FirestoreService _service;
  
  Future<Community> create(String name, String description) async {
    final doc = await _service.addDocument('communities', {
      'name': name,
      'description': description,
      'memberCount': 1,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    final snapshot = await _service.getDocument('communities', doc.id);
    return CommunityApiModel.fromFirestore(snapshot).toDomain();
  }
  
  Stream<List<Community>> watchAll() {
    return _service.streamCollection('communities').map(
      (snapshot) => snapshot.docs
        .map((doc) => CommunityApiModel.fromFirestore(doc).toDomain())
        .toList(),
    );
  }
}
```

#### Step 5: View Model
```dart
// ui/community/view_model/community_view_model.dart
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
    _repository.watchAll().listen(
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
  
  Future<void> createCommunity(String name, String description) async {
    _loading = true;
    notifyListeners();
    
    try {
      await _repository.create(name, description);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
```

#### Step 6: Screen
```dart
// ui/community/widgets/communities_screen.dart
class CommunitiesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CommunityViewModel>();
    
    if (viewModel.loading) {
      return LoadingIndicator(); // from ui/core/ui/
    }
    
    if (viewModel.error != null) {
      return ErrorMessage(viewModel.error!); // from ui/core/ui/
    }
    
    return ListView.builder(
      itemCount: viewModel.communities.length,
      itemBuilder: (context, index) {
        return CommunityCard(viewModel.communities[index]);
      },
    );
  }
}
```

#### Step 7: Wire Dependencies
```dart
// main.dart
void main() {
  final firestoreService = FirestoreService();
  final storageService = StorageService();
  
  final communityRepository = CommunityRepository(
    firestoreService,
    storageService,
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CommunityViewModel(communityRepository),
        ),
      ],
      child: MyApp(),
    ),
  );
}
```

---

## Key Principles

### ✅ DO

**UI Layer:**
- Organize by feature
- One view model per screen
- View models only talk to repositories
- Keep widgets simple and focused

**Domain Layer:**
- Pure Dart objects only
- No Firebase imports
- No JSON serialization here

**Data Layer:**
- Organize by type (repositories, services)
- Services handle external APIs
- Repositories convert API models to domain models
- Shared across features

### ❌ DON'T

- Don't import Firebase in UI layer
- Don't put business logic in widgets
- Don't use API models in view models
- Don't duplicate services per feature

---

## Why This Structure Works

| Decision | Reason |
|----------|--------|
| UI organized by feature | Each feature is self-contained |
| Data organized by type | Repositories/services are shared |
| Separate domain models | Business logic stays clean |
| API models convert to domain | Easy to swap backends |
| View models use ChangeNotifier | Simple, built-in, works great |

---

## Multiple Environments

```dart
// main_development.dart
void main() {
  AppConfig.setEnvironment(Environment.development);
  runApp(MyApp());
}

// main_staging.dart
void main() {
  AppConfig.setEnvironment(Environment.staging);
  runApp(MyApp());
}

// main.dart (production)
void main() {
  AppConfig.setEnvironment(Environment.production);
  runApp(MyApp());
}
```

Run with:
```bash
flutter run -t lib/main_development.dart
flutter run -t lib/main_staging.dart
flutter run -t lib/main.dart
```

---

## Testing Structure

```
test/                      # Mirrors lib/
├── data/
│   └── repositories/
│       └── community_repository_test.dart
├── ui/
│   └── community/
│       └── view_model/
│           └── community_view_model_test.dart
└── utils/

testing/                   # Test utilities (shared)
├── fakes/
│   └── fake_firestore_service.dart
└── models/
    └── test_community_data.dart
```

**Example test:**
```dart
// test/ui/community/view_model/community_view_model_test.dart
void main() {
  test('loads communities successfully', () async {
    final fakeRepo = FakeCommunityRepository();
    final viewModel = CommunityViewModel(fakeRepo);
    
    viewModel.loadCommunities();
    
    await Future.delayed(Duration.zero);
    
    expect(viewModel.communities.length, 2);
    expect(viewModel.error, isNull);
  });
}
```

---

## What Makes This Better Than Clean Architecture?

| Aspect | This Pattern | Clean Architecture |
|--------|-------------|-------------------|
| Files per feature | 4-5 | 8-10 |
| Learning curve | Low | High |
| Google-endorsed | ✅ Yes | ❌ No |
| Over-engineering | Low risk | High risk |
| Practical for solo dev | ✅ Yes | ❌ No |
| Still testable | ✅ Yes | ✅ Yes |
| Still maintainable | ✅ Yes | ✅ Yes |

---

## Summary for LLMs

When building a feature:

1. **Create domain model** (`domain/models/`)
2. **Create API model** (`data/model/`) with Firestore conversion
3. **Add repository methods** (`data/repositories/`) - converts API → domain
4. **Create view model** (`ui/{feature}/view_model/`) - manages state
5. **Build screen** (`ui/{feature}/widgets/`) - displays data
6. **Wire dependencies** in `main.dart`

**Core principle:** Domain stays pure, data handles Firebase, UI handles user interaction.

This is **Google's official recommendation** from their architecture guide and Compass app example.