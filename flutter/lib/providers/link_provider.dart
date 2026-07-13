import 'package:flutter/material.dart';
import '../models/link_item.dart';
import '../services/link_repository.dart';
import '../utils/normalize_url.dart';

/// Result of [LinkProvider.addLink] — either the newly saved link, or a flag
/// that it was already saved (with the existing entry attached).
class AddLinkResult {
  final LinkItem? link;
  final bool isDuplicate;
  final LinkItem? existingLink;

  const AddLinkResult.success(this.link)
      : isDuplicate = false,
        existingLink = null;

  const AddLinkResult.duplicate(this.existingLink)
      : link = null,
        isDuplicate = true;
}

class LinkProvider extends ChangeNotifier {
  final LinkRepository _repository = LinkRepository();
  List<LinkItem> _links = [];
  bool _isLoading = false;

  List<LinkItem> get links => _links;
  bool get isLoading => _isLoading;

  List<LinkItem> get favoriteLinks =>
      _links.where((link) => link.isFavorite).toList();

  /// Tutti i tag unici presenti nei link salvati, ordinati alfabeticamente.
  List<String> get allTags {
    final tags = <String>{};
    for (final link in _links) {
      tags.addAll(link.tags);
    }
    return tags.toList()..sort();
  }

  Future<void> loadLinks() async {
    _isLoading = true;
    notifyListeners();
    debugPrint('[LinkProvider] Inizio caricamento link...');

    try {
      _links = await _repository.getLinks();
      debugPrint('[LinkProvider] ✅ Link caricati: ${_links.length}');
      for (final link in _links) {
        debugPrint('  - ${link.title} (${link.url})');
      }
    } catch (e) {
      debugPrint('[LinkProvider] ❌ Errore caricamento link: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<AddLinkResult> addLink({
    required String url,
    required String title,
    List<String> tags = const [],
    String? thumbnail,
    String? collectionId,
  }) async {
    final normalized = normalizeUrl(url);
    final existing = _links.where((l) => normalizeUrl(l.url) == normalized);
    if (existing.isNotEmpty) {
      return AddLinkResult.duplicate(existing.first);
    }

    final normalizedTags = tags
        .map((t) => t.trim().toUpperCase())
        .where((t) => t.isNotEmpty)
        .toList();
    final link = LinkItem(
      url: url,
      title: title,
      tags: normalizedTags,
      thumbnail: thumbnail,
      collectionId: collectionId,
    );
    await _repository.addLink(link);
    await loadLinks();
    return AddLinkResult.success(link);
  }

  Future<void> deleteLink(String id) async {
    await _repository.deleteLink(id);
    await loadLinks();
  }

  /// Deletes every saved link — used by the "clear library (demo)" reset.
  Future<void> clearAll() async {
    for (final link in _links) {
      await _repository.deleteLink(link.id);
    }
    await loadLinks();
  }

  Future<void> updateLink(LinkItem link) async {
    await _repository.updateLink(link);
    await loadLinks();
  }

  Future<void> toggleFavorite(String id) async {
    final index = _links.indexWhere((l) => l.id == id);
    if (index == -1) return;
    await updateLink(_links[index].copyWith(isFavorite: !_links[index].isFavorite));
  }

  Future<void> toggleRead(String id) async {
    final index = _links.indexWhere((l) => l.id == id);
    if (index == -1) return;
    await updateLink(_links[index].copyWith(isRead: !_links[index].isRead));
  }

  Future<void> migrateLocalToCloud() async {
    await _repository.migrateLocalToCloud();
    await loadLinks();
  }

  // ── Tag management ──────────────────────────────────────────────────────

  /// Renames [oldTag] to [newTag] on every link that has it.
  Future<void> renameTag(String oldTag, String newTag) async {
    final trimmed = newTag.trim().toUpperCase();
    if (trimmed.isEmpty || trimmed == oldTag) return;
    final affected = _links.where((l) => l.tags.contains(oldTag)).toList();
    for (final link in affected) {
      final updated = link.tags
          .map((t) => t == oldTag ? trimmed : t)
          .toList();
      await _repository.updateLink(link.copyWith(tags: updated));
    }
    await loadLinks();
  }

  /// Removes [tag] from every link that has it.
  Future<void> deleteTag(String tag) async {
    final affected = _links.where((l) => l.tags.contains(tag)).toList();
    for (final link in affected) {
      final updated = link.tags.where((t) => t != tag).toList();
      await _repository.updateLink(link.copyWith(tags: updated));
    }
    await loadLinks();
  }

  /// Replaces [fromTag] with [toTag] on all affected links (deduplicates).
  Future<void> mergeTag(String fromTag, String toTag) async {
    final target = toTag.trim().toUpperCase();
    if (target.isEmpty || target == fromTag) return;
    final affected = _links.where((l) => l.tags.contains(fromTag)).toList();
    for (final link in affected) {
      final updated = link.tags
          .map((t) => t == fromTag ? target : t)
          .toSet()
          .toList();
      await _repository.updateLink(link.copyWith(tags: updated));
    }
    await loadLinks();
  }

  /// Adds [tag] to the links identified by [linkIds].
  Future<void> addTagToLinks(List<String> linkIds, String tag) async {
    final trimmed = tag.trim().toUpperCase();
    if (trimmed.isEmpty) return;
    for (final id in linkIds) {
      final link = _links.firstWhere((l) => l.id == id, orElse: () => throw StateError('Not found'));
      if (!link.tags.contains(trimmed)) {
        await _repository.updateLink(
            link.copyWith(tags: [...link.tags, trimmed]));
      }
    }
    await loadLinks();
  }

  /// Removes [tag] from the links identified by [linkIds].
  Future<void> removeTagFromLinks(List<String> linkIds, String tag) async {
    final trimmed = tag.trim().toUpperCase();
    if (trimmed.isEmpty) return;
    for (final id in linkIds) {
      final link = _links.firstWhere((l) => l.id == id, orElse: () => throw StateError('Not found'));
      if (link.tags.contains(trimmed)) {
        await _repository.updateLink(
            link.copyWith(tags: link.tags.where((t) => t != trimmed).toList()));
      }
    }
    await loadLinks();
  }
}
