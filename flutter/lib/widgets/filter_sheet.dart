import 'package:flutter/material.dart';
import '../theme/app_fonts.dart';
import '../models/collection_item.dart';
import '../models/link_filter.dart';
import '../models/link_item.dart';
import '../providers/collection_provider.dart';
import '../theme/app_colors.dart';
import '../utils/i18n.dart';
import 'link_avatar.dart';
import '../theme/cool_icons.dart';

/// "Filtri" bottom sheet — folder, read status and tags in one place.
/// Local edits only take effect when the user taps Applica; Reimposta
/// clears them back to defaults without closing the sheet.
Future<LinkFilter?> showFilterSheet(
  BuildContext context, {
  required LinkFilter current,
  required List<CollectionItem> collections,
  required List<LinkItem> links,
  VoidCallback? onAddCollection,
  void Function(CollectionItem)? onCollectionLongPress,
}) {
  final c = context.colors;
  return showModalBottomSheet<LinkFilter>(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.bgSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _FilterSheetContent(
      initial: current,
      collections: collections,
      links: links,
      onAddCollection: onAddCollection,
      onCollectionLongPress: onCollectionLongPress,
    ),
  );
}

class _FilterSheetContent extends StatefulWidget {
  final LinkFilter initial;
  final List<CollectionItem> collections;
  final List<LinkItem> links;
  final VoidCallback? onAddCollection;
  final void Function(CollectionItem)? onCollectionLongPress;

  const _FilterSheetContent({
    required this.initial,
    required this.collections,
    required this.links,
    this.onAddCollection,
    this.onCollectionLongPress,
  });

  @override
  State<_FilterSheetContent> createState() => _FilterSheetContentState();
}

class _FilterSheetContentState extends State<_FilterSheetContent> {
  String? _collectionId;
  bool _unreadOnly = false;
  late Set<String> _tags;

  /// Tags scoped to the selected folder — every tag when "All" is picked,
  /// only tags used within that folder's links otherwise.
  List<String> get _visibleTags {
    final scoped = _collectionId == null
        ? widget.links
        : widget.links.where((l) => l.collectionId == _collectionId);
    final tags = {for (final l in scoped) ...l.tags}.toList()..sort();
    return tags;
  }

  @override
  void initState() {
    super.initState();
    _collectionId = widget.initial.collectionId;
    _unreadOnly = widget.initial.unreadOnly;
    _tags = {...widget.initial.tags};
  }

  void _selectCollection(String? id) {
    setState(() {
      _collectionId = id;
      // Drop selected tags that don't exist in the newly scoped folder.
      final visible = _visibleTags.toSet();
      _tags = _tags.intersection(visible);
    });
  }

  void _reset() {
    setState(() {
      _collectionId = null;
      _unreadOnly = false;
      _tags = {};
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Text(
                t('filters.title'),
                style: AppFonts.display(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
            ),
            _SectionLabel(t('filters.folder')),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FolderChip(
                    label: t('filters.allFolders'),
                    color: c.accent,
                    selected: _collectionId == null,
                    onTap: () => _selectCollection(null),
                  ),
                  for (final entry in widget.collections.asMap().entries)
                    GestureDetector(
                      onLongPress: widget.onCollectionLongPress == null
                          ? null
                          : () => widget.onCollectionLongPress!(entry.value),
                      child: _FolderChip(
                        label: entry.value.name,
                        color: collectionColor(entry.value.color,
                            fallbackIndex: entry.key),
                        selected: _collectionId == entry.value.id,
                        onTap: () => _selectCollection(entry.value.id),
                      ),
                    ),
                  if (widget.onAddCollection != null)
                    GestureDetector(
                      onTap: widget.onAddCollection,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: c.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CoolIcons.add, size: 14, color: c.textTertiary),
                            const SizedBox(width: 4),
                            Text(
                              t('collections.add'),
                              style: AppFonts.body(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: c.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _SectionLabel(t('filters.status')),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _StatusButton(
                      label: t('home.filterAll'),
                      selected: !_unreadOnly,
                      onTap: () => setState(() => _unreadOnly = false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatusButton(
                      label: t('home.filterUnread'),
                      selected: _unreadOnly,
                      onTap: () => setState(() => _unreadOnly = true),
                    ),
                  ),
                ],
              ),
            ),
            Builder(builder: (context) {
              final visibleTags = _visibleTags;
              if (visibleTags.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          t('filters.tags'),
                          style: AppFonts.body(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: c.textTertiary,
                            letterSpacing: 0.6,
                          ),
                        ),
                        if (_collectionId == null)
                          Text(
                            t('filters.crossFolder'),
                            style: AppFonts.body(
                              fontSize: 11,
                              color: c.textTertiary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: visibleTags.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final tag = visibleTags[i];
                        return Center(
                          child: _TagChip(
                            tag: tag,
                            selected: _tags.contains(tag),
                            onTap: () => setState(() {
                              if (!_tags.add(tag)) _tags.remove(tag);
                            }),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reset,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: c.textPrimary,
                        side: BorderSide(color: c.border),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(t('filters.reset')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(
                        context,
                        LinkFilter(
                          collectionId: _collectionId,
                          unreadOnly: _unreadOnly,
                          tags: _tags,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: c.accent,
                        foregroundColor: c.accentOnPrimary,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: AppFonts.body(fontWeight: FontWeight.w700),
                      ),
                      child: Text(t('filters.apply')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Text(
        label,
        style: AppFonts.body(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: context.colors.textTertiary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _FolderChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _FolderChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(38) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppFonts.body(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? color : c.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? c.accent : c.bgElevated,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: AppFonts.body(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? c.accentOnPrimary : c.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String tag;
  final bool selected;
  final VoidCallback onTap;

  const _TagChip({
    required this.tag,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = linkAccentColor(tag);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(38) : c.bgElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : c.border),
        ),
        child: Text(
          '#$tag',
          style: AppFonts.body(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? color : c.textSecondary,
          ),
        ),
      ),
    );
  }
}
