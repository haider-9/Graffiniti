# Search Implementation Guide

This document describes the inline search functionality added to the Discovery and Communities pages with debouncing for Firebase database queries.

## Features Added

### 1. Debounced Search Utility
- **File**: `lib/core/utils/debouncer.dart`
- **Purpose**: Prevents excessive database queries by delaying search execution
- **Delay**: 500ms (configurable)

### 2. Discovery Page Inline Search
- **File**: `lib/pages/discover_page.dart`
- **Features**:
  - Inline search bar that appears above tabs when search icon is clicked
  - Real-time Firebase search for graffiti by title, artist, location
  - Search results replace tab content when active
  - Clear search functionality with close button
  - Loading states and empty states
  - Debounced Firebase queries to avoid excessive requests

### 3. Communities Page Inline Search
- **File**: `lib/pages/communities_page.dart`
- **Features**:
  - Inline search bar that appears above tabs when search icon is clicked
  - Real-time Firebase search for communities by name, description, tags
  - Search results replace tab content when active
  - Clear search functionality with close button
  - Loading states and empty states
  - Debounced Firebase queries to avoid excessive requests

### 4. Firebase Integration
- **Firestore Queries**: Direct Firebase queries using Firestore SDK
  - `collection('graffiti').where('visibility', isEqualTo: 'public')`
  - `collection('communities').where('visibility', isEqualTo: 'public')`
  - Uses `orderBy('title/name').startAt([searchTerm]).endAt([searchTerm + '\uf8ff'])`
  - Fallback to local mock data for demo purposes

### 5. Modern Architecture Example
- **File**: `lib/ui/community/widgets/communities_screen.dart`
- **Features**:
  - Uses Provider pattern with CommunityViewModel
  - Inline search bar in app bar area
  - Real-time Firebase search with database integration
  - Loading states and error handling
  - Proper state management with search results

## How It Works

### Search Flow
1. User taps search icon in header
2. Search bar slides in above tabs
3. Search icon changes to close icon
4. User types search query
5. Debouncer delays execution by 500ms
6. Firebase query executes
7. Results replace tab content
8. User can clear search or close search bar

### Firebase Queries
- **Simplified Queries**: Uses basic `where` clauses without `orderBy` to avoid composite index requirements
- **Local Filtering**: Fetches up to 50 results from Firebase, then filters locally by search terms
- **Collection Filtering**: Only searches public content (`visibility: 'public'`)
- **Result Limiting**: Final results limited to 20 items after local filtering
- **Error Handling**: Falls back to local mock data if Firebase fails

### State Management
- **Legacy Pages**: Use local state with `setState()`
- **Modern Architecture**: Use Provider pattern with ViewModels
- **Search State**: Managed separately from main data
- **Loading States**: Show progress indicators during search
- **UI State**: Toggle between search and normal content

## Usage Examples

### Inline Search UI (Discovery Page)
```dart
Widget build(BuildContext context) {
  return Column(
    children: [
      _buildHeader(),
      if (_showSearchBar) _buildSearchBar(), // Inline search bar
      _buildTabBar(),
      Expanded(
        child: _showSearchBar && _searchQuery.isNotEmpty
            ? _buildSearchResults() // Show search results
            : TabBarView(...), // Show normal tabs
      ),
    ],
  );
}
```

### Firebase Search Query
```dart
void _performFirebaseSearch(String query) async {
  // Simplified Firebase search query without orderBy to avoid index requirement
  final querySnapshot = await FirebaseFirestore.instance
      .collection('graffiti')
      .where('visibility', isEqualTo: 'public')
      .limit(50) // Get more results to filter locally
      .get();

  // Filter results locally to avoid complex Firebase queries
  final results = querySnapshot.docs
      .map((doc) => /* convert to model */)
      .where((graffiti) => /* local search filter */)
      .take(20) // Limit final results
      .toList();
}
```

### Search State Toggle
```dart
void _toggleSearch() {
  setState(() {
    _showSearchBar = !_showSearchBar;
    if (!_showSearchBar) {
      _searchController.clear();
      _searchQuery = '';
      _searchResults = [];
    }
  });
}
```

## Configuration

### Debounce Timing
```dart
final Debouncer _searchDebouncer = Debouncer(milliseconds: 500);
```

### Firebase Collections
- **Graffiti**: `graffiti` collection with fields: title, artist, location, visibility
- **Communities**: `communities` collection with fields: name, description, tags, visibility

### Search Fields
- **Graffiti**: title, artist, location
- **Communities**: name, description, tags

## UI/UX Features

### Search Bar Animation
- Slides in smoothly above tabs
- Auto-focus on text input
- Search icon transforms to close icon
- Clear button appears when typing

### Search Results
- Replace tab content when active
- Loading spinner during search
- Empty state with helpful message
- Error handling with retry option

### State Persistence
- Search state is cleared when closing search
- Tab state is preserved when switching between search and tabs
- Smooth transitions between states

## Testing

To test the inline search functionality:

1. **Discovery Page**:
   - Tap search icon in header
   - Verify search bar appears above tabs
   - Type search query and verify debouncing
   - Check Firebase query execution
   - Test close functionality

2. **Communities Page**:
   - Tap search icon in header
   - Search by community name or description
   - Verify Firebase integration
   - Test empty states and loading states

3. **Modern Communities Screen**:
   - Use Provider-based search
   - Test real-time database integration
   - Verify error handling and retry functionality

## Future Enhancements

1. **Search History**: Store recent searches locally
2. **Search Suggestions**: Auto-complete based on popular searches
3. **Advanced Filters**: Category, date range, location radius
4. **Search Analytics**: Track search terms and results
5. **Offline Search**: Cache recent results for offline access
6. **Full-Text Search**: Implement Algolia or Elasticsearch for better search