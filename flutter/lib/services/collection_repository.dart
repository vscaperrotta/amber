import 'package:firebase_auth/firebase_auth.dart';
import '../models/collection_item.dart';
import 'local_storage_service.dart';
import 'firebase_storage_service.dart';

class CollectionRepository {
  final LocalStorageService _localStorage = LocalStorageService();
  final FirebaseStorageService _firebaseStorage = FirebaseStorageService();

  User? get _currentUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  bool get isLoggedIn => _currentUser != null;

  Future<List<CollectionItem>> getCollections() async {
    if (isLoggedIn) {
      return _firebaseStorage.getCollections(_currentUser!.uid);
    } else {
      return _localStorage.getCollections();
    }
  }

  Future<void> addCollection(CollectionItem collection) async {
    if (isLoggedIn) {
      await _firebaseStorage.addCollection(_currentUser!.uid, collection);
    } else {
      await _localStorage.addCollection(collection);
    }
  }

  Future<void> updateCollection(CollectionItem collection) async {
    if (isLoggedIn) {
      await _firebaseStorage.updateCollection(_currentUser!.uid, collection);
    } else {
      await _localStorage.updateCollection(collection);
    }
  }

  Future<void> deleteCollection(String id) async {
    if (isLoggedIn) {
      await _firebaseStorage.deleteCollection(_currentUser!.uid, id);
    } else {
      await _localStorage.deleteCollection(id);
    }
  }
}
