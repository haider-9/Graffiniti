import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<DocumentSnapshot> getDocument(String collection, String id) {
    return _db.collection(collection).doc(id).get();
  }

  Stream<QuerySnapshot> streamCollection(String collection) {
    return _db.collection(collection).snapshots();
  }

  Stream<QuerySnapshot> streamCollectionWhere(
    String collection,
    String field,
    dynamic value,
  ) {
    return _db
        .collection(collection)
        .where(field, isEqualTo: value)
        .snapshots();
  }

  Future<DocumentReference> addDocument(
    String collection,
    Map<String, dynamic> data,
  ) {
    return _db.collection(collection).add(data);
  }

  Future<void> updateDocument(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) {
    return _db.collection(collection).doc(id).update(data);
  }

  Future<void> deleteDocument(String collection, String id) {
    return _db.collection(collection).doc(id).delete();
  }

  Query queryCollection(String collection) {
    return _db.collection(collection);
  }

  // Search methods with simplified queries to avoid index requirements
  Stream<QuerySnapshot> searchCommunities(String searchTerm) {
    if (searchTerm.isEmpty) {
      return streamCollection('communities');
    }

    // Simple query without orderBy to avoid index requirement
    return _db
        .collection('communities')
        .where('visibility', isEqualTo: 'public')
        .limit(50)
        .snapshots();
  }

  Stream<QuerySnapshot> searchCommunitiesByTags(List<String> tags) {
    if (tags.isEmpty) {
      return streamCollection('communities');
    }

    return _db
        .collection('communities')
        .where('visibility', isEqualTo: 'public')
        .where('tags', arrayContainsAny: tags)
        .snapshots();
  }

  Stream<QuerySnapshot> searchGraffiti(String searchTerm) {
    if (searchTerm.isEmpty) {
      return streamCollection('graffiti');
    }

    // Simple query without orderBy to avoid index requirement
    return _db
        .collection('graffiti')
        .where('visibility', isEqualTo: 'public')
        .limit(50)
        .snapshots();
  }

  Stream<QuerySnapshot> searchGraffitiByTags(List<String> tags) {
    if (tags.isEmpty) {
      return streamCollection('graffiti');
    }

    return _db
        .collection('graffiti')
        .where('visibility', isEqualTo: 'public')
        .where('tags', arrayContainsAny: tags)
        .snapshots();
  }
}
