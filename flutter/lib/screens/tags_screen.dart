import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/link_provider.dart';
import '../providers/collection_provider.dart';
import '../providers/ui_state_provider.dart';
import '../models/link_item.dart';
import '../theme/app_colors.dart';
import '../utils/i18n.dart';
import '../utils/dialogs.dart';
import '../widgets/link_card.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/collection_scoped_app_bar.dart';

class TagsScreen extends StatefulWidget {
  const TagsScreen({super.key});

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  final Set<String> _selectedTags = {};

  // Bulk-select mode
  bool _selectMode = false;
  final Set<String> _selectedLinkIds = {};
  final TextEditingController _bulkTagController = TextEditingController();

  @override
  void dispose() {
    context.read<UiStateProvider>().setSelectMode(false);
    _bulkTagController.dispose();
    super.dispose();
  }

  // ── Tag actions bottom sheet ─────────────────────────────────────────────

  void _showTagActionsSheet(BuildContext context, String tag, LinkProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.bgElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _TagActionsSheet(
        tag: tag,
        allTags: provider.allTags,
        onRename: (newName) async {
          Navigator.pop(ctx);
          await provider.renameTag(tag, newName);
        },
        onDelete: () async {
          Navigator.pop(ctx);
          final confirmed = await confirmDelete(
            context,
            title: t('tags.deleteTag'),
            message: '#$tag',
          );
          if (confirmed == true) await provider.deleteTag(tag);
        },
        onMerge: (targetTag) async {
          Navigator.pop(ctx);
          await provider.mergeTag(tag, targetTag);
        },
      ),
    );
  }

  // ── Bulk-select bottom bar ────────────────────────────────────────────────

  Widget _buildBulkBar(LinkProvider provider) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: c.bgElevated,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Selected count
          Text(
            t('tags.selectedCount', {'n': '${_selectedLinkIds.length}'}),
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: c.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          // Tag input
          TextField(
            controller: _bulkTagController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: t('tags.tagHint'),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _selectedLinkIds.isEmpty
                      ? null
                      : () async {
                          final tag = _bulkTagController.text.trim().toUpperCase();
                          if (tag.isEmpty) return;
                          final uiState = context.read<UiStateProvider>();
                          await provider.addTagToLinks(
                              _selectedLinkIds.toList(), tag);
                          uiState.setSelectMode(false);
                          setState(() {
                            _selectMode = false;
                            _selectedLinkIds.clear();
                            _bulkTagController.clear();
                          });
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.accent,
                    side: BorderSide(color: c.accent),
                  ),
                  child: Text(t('tags.addTagToSelected')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _selectedLinkIds.isEmpty
                      ? null
                      : () async {
                          final tag = _bulkTagController.text.trim().toUpperCase();
                          if (tag.isEmpty) return;
                          final uiState = context.read<UiStateProvider>();
                          await provider.removeTagFromLinks(
                              _selectedLinkIds.toList(), tag);
                          uiState.setSelectMode(false);
                          setState(() {
                            _selectMode = false;
                            _selectedLinkIds.clear();
                            _bulkTagController.clear();
                          });
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.statusError,
                    side: BorderSide(color: c.statusError),
                  ),
                  child: Text(t('tags.removeTagFromSelected')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final linkProvider = context.watch<LinkProvider>();
    final collectionProvider = context.watch<CollectionProvider>();
    final activeCollectionId = collectionProvider.activeCollectionId;

    final scopedLinks = activeCollectionId == null
        ? linkProvider.links
        : linkProvider.links.where((l) => l.collectionId == activeCollectionId).toList();
    final allTags = ({for (final l in scopedLinks) ...l.tags}).toList()..sort();

    if (allTags.isEmpty) {
      return _buildEmptyState(
        isFiltered: activeCollectionId != null,
        collectionName: collectionProvider.activeCollection?.name,
        onClearFilter: () => collectionProvider.setActiveCollection(null),
      );
    }

    final tagGroups = {
      for (final tag in allTags)
        tag: scopedLinks.where((l) => l.tags.contains(tag)).toList(),
    };

    final tagsToShow =
        _selectedTags.isNotEmpty ? _selectedTags.toList() : allTags;
    final items = <_TagListItem>[];
    for (final tag in tagsToShow) {
      items.add(_TagHeader(tag, tagGroups[tag]?.length ?? 0));
      for (final link in tagGroups[tag] ?? <LinkItem>[]) {
        items.add(_TagLink(link));
      }
    }

    return Scaffold(
      appBar: CollectionScopedAppBar(
        defaultTitle: t('tags.title'),
        activeCollectionName: collectionProvider.activeCollection?.name,
        onClearFilter: () => collectionProvider.setActiveCollection(null),
        extraActions: [
          TextButton(
            onPressed: () {
              final newMode = !_selectMode;
              context.read<UiStateProvider>().setSelectMode(newMode);
              setState(() {
                _selectMode = newMode;
                _selectedLinkIds.clear();
                _bulkTagController.clear();
              });
            },
            child: Text(
              _selectMode ? t('tags.bulkDone') : t('tags.selectLinks'),
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _selectMode ? c.accent : c.textSecondary,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Chip row ──────────────────────────────────────────────────────
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: allTags.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                if (i == 0) {
                  final isAll = _selectedTags.isEmpty;
                  return FilterChip(
                    showCheckmark: false,
                    avatar: Icon(
                      isAll ? Icons.check : Icons.label_outline,
                      size: 14,
                      color: isAll ? c.accent : c.textTertiary,
                    ),
                    label: Text(
                      t('tags.all'),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: c.textSecondary,
                      ),
                    ),
                    selected: isAll,
                    onSelected: (_) {
                      setState(() {
                        _selectedTags.clear();
                      });
                    },
                    selectedColor: c.accentMuted,
                    side: BorderSide(color: isAll ? c.accent : c.border),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  );
                }
                final tag = allTags[i - 1];
                final isSelected = _selectedTags.contains(tag);
                return GestureDetector(
                  onLongPress: () {
                    HapticFeedback.mediumImpact();
                    _showTagActionsSheet(context, tag, linkProvider);
                  },
                  child: FilterChip(
                    showCheckmark: false,
                    avatar: Icon(
                      isSelected ? Icons.check : Icons.label_outline,
                      size: 14,
                      color: isSelected ? c.accent : c.textTertiary,
                    ),
                    label: Text(
                      '$tag (${tagGroups[tag]!.length})',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: c.textSecondary,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        if (_selectedTags.contains(tag)) {
                          _selectedTags.remove(tag);
                        } else {
                          _selectedTags.add(tag);
                        }
                      });
                    },
                    selectedColor: c.accentMuted,
                    side: BorderSide(color: isSelected ? c.accent : c.border),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          // ── Grouped links list ─────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(
                top: 8,
                bottom: _selectMode ? 0 : 96,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                if (item is _TagHeader) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Row(
                      children: [
                        Text(
                          '#${item.tag}',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: c.accent,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${item.count}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: c.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final linkItem = (item as _TagLink).link;
                return LinkCard(
                  key: ValueKey('${index}_${linkItem.id}'),
                  link: linkItem,
                  keyPrefix: '${index}_',
                  selectable: _selectMode,
                  selected: _selectedLinkIds.contains(linkItem.id),
                  onSelectChanged: _selectMode
                      ? (val) {
                          setState(() {
                            if (val) {
                              _selectedLinkIds.add(linkItem.id);
                            } else {
                              _selectedLinkIds.remove(linkItem.id);
                            }
                          });
                        }
                      : null,
                  onFavoriteToggle: () =>
                      context.read<LinkProvider>().toggleFavorite(linkItem.id),
                  onReadToggle: () =>
                      context.read<LinkProvider>().toggleRead(linkItem.id),
                  onDismissConfirm: () => confirmDelete(
                    context,
                    title: t('dialog.deleteTitle'),
                    message: t('dialog.deleteMessage'),
                  ),
                  onDismissed: () =>
                      context.read<LinkProvider>().deleteLink(linkItem.id),
                );
              },
            ),
          ),
          // ── Bulk-select bottom bar ────────────────────────────────────────
          if (_selectMode) _buildBulkBar(linkProvider),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    bool isFiltered = false,
    String? collectionName,
    VoidCallback? onClearFilter,
  }) {
    return Scaffold(
      appBar: isFiltered
          ? CollectionScopedAppBar(
              defaultTitle: t('tags.title'),
              activeCollectionName: collectionName,
              onClearFilter: onClearFilter ?? () {},
            )
          : null,
      body: Center(
        child: EmptyStateView(
          icon: Icons.label_off_outlined,
          title: isFiltered ? t('collections.emptyTitle') : t('tags.emptyTitle'),
          subtitle: isFiltered ? t('collections.emptySubtitle') : t('tags.emptySubtitle'),
        ),
      ),
    );
  }
}

// ── Tag actions bottom sheet ──────────────────────────────────────────────────

class _TagActionsSheet extends StatefulWidget {
  final String tag;
  final List<String> allTags;
  final Future<void> Function(String newName) onRename;
  final Future<void> Function() onDelete;
  final Future<void> Function(String targetTag) onMerge;

  const _TagActionsSheet({
    required this.tag,
    required this.allTags,
    required this.onRename,
    required this.onDelete,
    required this.onMerge,
  });

  @override
  State<_TagActionsSheet> createState() => _TagActionsSheetState();
}

class _TagActionsSheetState extends State<_TagActionsSheet> {
  final _renameController = TextEditingController();
  final _mergeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _renameController.text = widget.tag;
  }

  @override
  void dispose() {
    _renameController.dispose();
    _mergeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final otherTags =
        widget.allTags.where((t) => t != widget.tag).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
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
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                '#${widget.tag}',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: c.accent,
                ),
              ),
            ),
            Divider(height: 1, color: c.border),
            // ── Rename ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Text(
                t('tags.renameTag'),
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c.textTertiary,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _renameController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: t('tags.renameHint'),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: c.accent,
                      foregroundColor: c.accentOnPrimary,
                      minimumSize: const Size(72, 40),
                    ),
                    onPressed: () =>
                        widget.onRename(_renameController.text.trim().toUpperCase()),
                    child: Text(t('tags.confirm')),
                  ),
                ],
              ),
            ),
            // ── Merge into ───────────────────────────────────────────────────
            if (otherTags.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(
                  t('tags.mergeInto'),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.textTertiary,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _MergeDropdown(
                        tags: otherTags,
                        controller: _mergeController,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: c.bgElevated,
                        foregroundColor: c.textPrimary,
                        minimumSize: const Size(72, 40),
                      ),
                      onPressed: () {
                        final target = _mergeController.text.trim().toUpperCase();
                        if (target.isNotEmpty) widget.onMerge(target);
                      },
                      child: Text(t('tags.confirm')),
                    ),
                  ],
                ),
              ),
            ],
            // ── Delete ───────────────────────────────────────────────────────
            const SizedBox(height: 8),
            Divider(height: 1, color: c.border),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: c.statusError,
                size: 18,
              ),
              title: Text(
                t('tags.deleteTag'),
                style: GoogleFonts.outfit(color: c.statusError),
              ),
              onTap: widget.onDelete,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Simple dropdown for merge target ─────────────────────────────────────────

class _MergeDropdown extends StatefulWidget {
  final List<String> tags;
  final TextEditingController controller;
  const _MergeDropdown({required this.tags, required this.controller});

  @override
  State<_MergeDropdown> createState() => _MergeDropdownState();
}

class _MergeDropdownState extends State<_MergeDropdown> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DropdownButtonFormField<String>(
      initialValue: _selected,
      hint: Text(
        t('tags.mergeHint'),
        style: GoogleFonts.outfit(
          fontSize: 13,
          color: c.textTertiary,
        ),
      ),
      decoration: const InputDecoration(isDense: true),
      dropdownColor: c.bgElevated,
      items: widget.tags
          .map(
            (tag) => DropdownMenuItem(
              value: tag,
              child: Text(
                tag,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: c.textPrimary,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: (val) {
        setState(() => _selected = val);
        widget.controller.text = val ?? '';
      },
    );
  }
}

// ── Internal list item types ──────────────────────────────────────────────────

abstract class _TagListItem {}

class _TagHeader extends _TagListItem {
  final String tag;
  final int count;
  _TagHeader(this.tag, this.count);
}

class _TagLink extends _TagListItem {
  final LinkItem link;
  _TagLink(this.link);
}
