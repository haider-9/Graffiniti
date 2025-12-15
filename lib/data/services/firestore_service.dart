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
}
