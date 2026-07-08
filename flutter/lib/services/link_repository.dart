import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/link_item.dart';
import 'local_storage_service.dart';
import 'firebase_storage_service.dart';

class LinkRepository {
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

  Future<List<LinkItem>> getLinks() async {
    if (isLoggedIn) {
      debugPrint('[LinkRepository] 🔵 Caricando da Firebase per uid: ${_currentUser!.uid}');
      final links = await _firebaseStorage.getLinks(_currentUser!.uid);
      debugPrint('[LinkRepository] 🔵 Firebase ha restituito ${links.length} link');
      return links;
    } else {
      debugPrint('[LinkRepository] 🟡 Caricando da SQLite locale');
      final links = await _localStorage.getLinks();
      debugPrint('[LinkRepository] 🟡 SQLite ha restituito ${links.length} link');
      return links;
    }
  }

  Future<void> addLink(LinkItem link) async {
    if (isLoggedIn) {
      await _firebaseStorage.addLink(_currentUser!.uid, link);
    } else {
      await _localStorage.addLink(link);
    }
  }

  Future<void> deleteLink(String id) async {
    if (isLoggedIn) {
      await _firebaseStorage.deleteLink(_currentUser!.uid, id);
    } else {
      await _localStorage.deleteLink(id);
    }
  }

  Future<void> updateLink(LinkItem link) async {
    if (isLoggedIn) {
      await _firebaseStorage.updateLink(_currentUser!.uid, link);
    } else {
      await _localStorage.updateLink(link);
    }
  }

  /// Migra tutti i link locali su Firestore dopo il login
  Future<void> migrateLocalToCloud() async {
    if (!isLoggedIn) return;

    final localLinks = await _localStorage.getLinks();
    if (localLinks.isEmpty) return;

    for (final link in localLinks) {
      await _firebaseStorage.addLink(_currentUser!.uid, link);
    }

    // Cancella i link locali dopo la migrazione
    await _localStorage.deleteAllLinks();
  }
}
