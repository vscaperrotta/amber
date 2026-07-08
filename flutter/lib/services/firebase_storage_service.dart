import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/link_item.dart';
import '../models/collection_item.dart';

// Settings stored at /users/{uid}/links/__settings__ — covered by existing Firestore rules.

class FirebaseStorageService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userLinksCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('links');
  }

  Future<List<LinkItem>> getLinks(String uid) async {
    debugPrint(
      '[FirebaseStorageService] Querying collection: users/$uid/links',
    );
    try {
      // Usa 'savedAt' per ordinamento (compatibile con i dati esistenti)
      final snapshot = await _userLinksCollection(
        uid,
      ).orderBy('savedAt', descending: true).get();
      debugPrint(
        '[FirebaseStorageService] ✅ Query success: ${snapshot.docs.length} documenti trovati',
      );

      if (snapshot.docs.isEmpty) {
        debugPrint('[FirebaseStorageService] ⚠️  Collection è vuota!');
      } else {
        for (final doc in snapshot.docs) {
          debugPrint(
            '[FirebaseStorageService] Doc: ${doc.id} -> ${doc.data()}',
          );
        }
      }

      return snapshot.docs
          .map((doc) => LinkItem.fromMap({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      debugPrint('[FirebaseStorageService] ❌ Query error: $e');
      debugPrint('[FirebaseStorageService] Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<void> addLink(String uid, LinkItem link) async {
    await _userLinksCollection(uid).doc(link.id).set(link.toFirestoreMap());
  }

  Future<void> deleteLink(String uid, String linkId) async {
    await _userLinksCollection(uid).doc(linkId).delete();
  }

  Future<void> updateLink(String uid, LinkItem link) async {
    await _userLinksCollection(uid).doc(link.id).update(link.toFirestoreMap());
  }

  // ── Collections ────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _userCollectionsCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('collections');
  }

  Future<List<CollectionItem>> getCollections(String uid) async {
    final snapshot = await _userCollectionsCollection(uid)
        .orderBy('createdAt', descending: false)
        .get();
    return snapshot.docs
        .map((doc) => CollectionItem.fromMap({'id': doc.id, ...doc.data()}))
        .toList();
  }

  Future<void> addCollection(String uid, CollectionItem collection) async {
    await _userCollectionsCollection(uid).doc(collection.id).set(collection.toFirestoreMap());
  }

  Future<void> updateCollection(String uid, CollectionItem collection) async {
    await _userCollectionsCollection(uid).doc(collection.id).update(collection.toFirestoreMap());
  }

  Future<void> deleteCollection(String uid, String collectionId) async {
    await _userCollectionsCollection(uid).doc(collectionId).delete();
  }
}
