/// Combined filter state for the Home list — folder (collection),
/// read status, and a cross-folder set of tags — all applied together.
class LinkFilter {
  final String? collectionId;
  final bool unreadOnly;
  final Set<String> tags;

  const LinkFilter({
    this.collectionId,
    this.unreadOnly = false,
    this.tags = const {},
  });

  bool get isActive =>
      collectionId != null || unreadOnly || tags.isNotEmpty;

  int get activeCount =>
      (collectionId != null ? 1 : 0) + (unreadOnly ? 1 : 0) + tags.length;

  LinkFilter copyWith({
    String? collectionId,
    bool clearCollectionId = false,
    bool? unreadOnly,
    Set<String>? tags,
  }) {
    return LinkFilter(
      collectionId:
          clearCollectionId ? null : (collectionId ?? this.collectionId),
      unreadOnly: unreadOnly ?? this.unreadOnly,
      tags: tags ?? this.tags,
    );
  }
}
