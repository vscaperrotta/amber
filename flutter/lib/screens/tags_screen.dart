import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/link_provider.dart';
import '../providers/collection_provider.dart';
import '../providers/ui_state_provider.dart';
import '../models/link_item.dart';
import '../theme/app_colors.dart';
import '../utils/i18n.dart';
import '../utils/dialogs.dart';
import '../utils/time_bucket.dart';
import '../widgets/link_card.dart';
import '../widgets/link_avatar.dart';
import '../widgets/group_header.dart';
import '../widgets/empty_state_view.dart';
import '../theme/cool_icons.dart';

class TagsScreen extends StatelessWidget {
  const TagsScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final linkProvider = context.watch<LinkProvider>();
    final links = linkProvider.links;
    final allTags = ({for (final l in links) ...l.tags}).toList()..sort();

    if (allTags.isEmpty) {
      return Scaffold(
        body: Center(
          child: EmptyStateView(
            icon: CoolIcons.tagOff,
            title: t('tags.emptyTitle'),
            subtitle: t('tags.emptySubtitle'),
          ),
        ),
      );
    }

    final counts = {
      for (final tag in allTags)
        tag: links.where((l) => l.tags.contains(tag)).length,
    };
    final maxCount = counts.values.reduce((a, b) => a > b ? a : b);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('tags.title'),
                style: AppFonts.display(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                t('tags.subtitle'),
                style: AppFonts.body(
                  fontSize: 13,
                  color: c.textTertiary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final tag in allTags)
                    _TagBubble(
                      tag: tag,
                      count: counts[tag]!,
                      maxCount: maxCount,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TagDetailScreen(tag: tag),
                        ),
                      ),
                      onLongPress: () {
                        HapticFeedback.mediumImpact();
                        _showTagActionsSheet(context, tag, linkProvider);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tag bubble ─────────────────────────────────────────────────────────────
// Size scales with usage count so heavily-used tags visually dominate the
// cloud — the mapping is deliberately soft (sqrt) so one outlier tag
// doesn't swallow the layout.

class _TagBubble extends StatelessWidget {
  final String tag;
  final int count;
  final int maxCount;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _TagBubble({
    required this.tag,
    required this.count,
    required this.maxCount,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final color = linkAccentColor(tag);
    final scale = maxCount <= 1 ? 1.0 : (count / maxCount);
    final t = scale.clamp(0.0, 1.0);
    final fontSize = 13.0 + 9.0 * t;
    final hPad = 14.0 + 8.0 * t;
    final vPad = 8.0 + 6.0 * t;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        decoration: BoxDecoration(
          color: color.withAlpha(38),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '#$tag',
              style: AppFonts.body(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '$count',
              style: AppFonts.body(
                fontSize: fontSize * 0.75,
                fontWeight: FontWeight.w600,
                color: color.withAlpha(200),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tag detail screen ───────────────────────────────────────────────────────
// Reached by tapping a bubble: every link carrying that tag, grouped by
// time like Home. Keeps the bulk tag-editing flow that used to live on
// the old chip-row Tags screen, now scoped to this one tag.

class TagDetailScreen extends StatefulWidget {
  final String tag;
  const TagDetailScreen({super.key, required this.tag});

  @override
  State<TagDetailScreen> createState() => _TagDetailScreenState();
}

class _TagDetailScreenState extends State<TagDetailScreen> {
  bool _selectMode = false;
  final Set<String> _selectedLinkIds = {};
  final _bulkTagController = TextEditingController();

  @override
  void dispose() {
    context.read<UiStateProvider>().setSelectMode(false);
    _bulkTagController.dispose();
    super.dispose();
  }

  List<Widget> _buildGroupedItems(BuildContext context, List<LinkItem> links) {
    final grouped = groupByTimeBucket(links);
    final items = <Widget>[];
    for (final bucket in TimeBucket.values) {
      final bucketLinks = grouped[bucket];
      if (bucketLinks == null || bucketLinks.isEmpty) continue;
      items.add(GroupHeader(label: bucketLabel(bucket)));
      for (final link in bucketLinks) {
        items.add(LinkCard(
          key: ValueKey(link.id),
          link: link,
          stripeColor:
              context.read<CollectionProvider>().colorForCollectionId(link.collectionId),
          selectable: _selectMode,
          selected: _selectedLinkIds.contains(link.id),
          onSelectChanged: _selectMode
              ? (val) => setState(() {
                    if (val) {
                      _selectedLinkIds.add(link.id);
                    } else {
                      _selectedLinkIds.remove(link.id);
                    }
                  })
              : null,
          onFavoriteToggle: () =>
              context.read<LinkProvider>().toggleFavorite(link.id),
          onReadToggle: () => context.read<LinkProvider>().toggleRead(link.id),
          onDismissConfirm: () => confirmDelete(
            context,
            title: t('dialog.deleteTitle'),
            message: t('dialog.deleteMessage'),
          ),
          onDismissed: () => context.read<LinkProvider>().deleteLink(link.id),
        ));
      }
    }
    return items;
  }

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
          Text(
            t('tags.selectedCount', {'n': '${_selectedLinkIds.length}'}),
            style: AppFonts.body(fontSize: 13, color: c.textTertiary),
          ),
          const SizedBox(height: 8),
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
                          await provider.addTagToLinks(_selectedLinkIds.toList(), tag);
                          _exitSelectMode();
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
                          await provider.removeTagFromLinks(
                              _selectedLinkIds.toList(), tag);
                          _exitSelectMode();
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

  void _exitSelectMode() {
    context.read<UiStateProvider>().setSelectMode(false);
    setState(() {
      _selectMode = false;
      _selectedLinkIds.clear();
      _bulkTagController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final linkProvider = context.watch<LinkProvider>();
    final links = linkProvider.links.where((l) => l.tags.contains(widget.tag)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '#${widget.tag}',
          style: AppFonts.body(fontWeight: FontWeight.w700, color: c.accent),
        ),
        centerTitle: true,
        actions: [
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
              style: AppFonts.body(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _selectMode ? c.accent : c.textSecondary,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: links.isEmpty
                ? Center(
                    child: EmptyStateView(
                      icon: CoolIcons.tagOff,
                      title: t('tagFiltered.empty'),
                      subtitle: '',
                    ),
                  )
                : ListView(
                    padding: EdgeInsets.only(top: 8, bottom: _selectMode ? 0 : 96),
                    children: _buildGroupedItems(context, links),
                  ),
          ),
          if (_selectMode) _buildBulkBar(linkProvider),
        ],
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
                style: AppFonts.body(
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
                style: AppFonts.body(
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
                  style: AppFonts.body(
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
                CoolIcons.deleteOutline,
                color: c.statusError,
                size: 18,
              ),
              title: Text(
                t('tags.deleteTag'),
                style: AppFonts.body(color: c.statusError),
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
        style: AppFonts.body(
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
                style: AppFonts.body(
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
