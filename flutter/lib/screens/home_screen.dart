import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/link_item.dart';
import '../providers/link_provider.dart';
import '../providers/collection_provider.dart';
import '../theme/app_colors.dart';
import '../utils/i18n.dart';
import '../widgets/link_card.dart';

// ── Time bucket helpers ────────────────────────────────────────────────────────

enum _TimeBucket { today, yesterday, thisWeek, thisMonth, earlier }

_TimeBucket _bucketFor(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(date.year, date.month, date.day);
  final diff = today.difference(d).inDays;
  if (diff == 0) return _TimeBucket.today;
  if (diff == 1) return _TimeBucket.yesterday;
  if (diff <= 7) return _TimeBucket.thisWeek;
  if (diff <= 30) return _TimeBucket.thisMonth;
  return _TimeBucket.earlier;
}

String _bucketLabel(_TimeBucket bucket) {
  switch (bucket) {
    case _TimeBucket.today:
      return t('home.groupToday');
    case _TimeBucket.yesterday:
      return t('home.groupYesterday');
    case _TimeBucket.thisWeek:
      return t('home.groupThisWeek');
    case _TimeBucket.thisMonth:
      return t('home.groupThisMonth');
    case _TimeBucket.earlier:
      return t('home.groupEarlier');
  }
}

// ── HomeScreen ─────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showUnreadOnly = false;

  List<Widget> _buildGroupedList(BuildContext context, List<LinkItem> links) {
    final grouped = <_TimeBucket, List<LinkItem>>{};
    for (final link in links) {
      final b = _bucketFor(link.createdAt);
      grouped.putIfAbsent(b, () => []).add(link);
    }

    final order = _TimeBucket.values;
    final items = <Widget>[];

    for (final bucket in order) {
      final bucketLinks = grouped[bucket];
      if (bucketLinks == null || bucketLinks.isEmpty) continue;

      items.add(_GroupHeader(label: _bucketLabel(bucket)));

      for (final link in bucketLinks) {
        items.add(LinkCard(
          key: ValueKey(link.id),
          link: link,
          onFavoriteToggle: () =>
              context.read<LinkProvider>().toggleFavorite(link.id),
          onDismissConfirm: () => showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(t('dialog.deleteTitle')),
              content: Text(t('dialog.deleteMessage')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(t('common.cancel')),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    t('common.delete'),
                    style: TextStyle(color: context.colors.statusError),
                  ),
                ),
              ],
            ),
          ),
          onDismissed: () => context.read<LinkProvider>().deleteLink(link.id),
          onReadToggle: () => context.read<LinkProvider>().toggleRead(link.id),
        ));
      }
    }

    return items;
  }

  void _showAddCollectionDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('collections.addTitle')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: t('collections.nameHint')),
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              context.read<CollectionProvider>().addCollection(val.trim());
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('common.cancel')),
          ),
          TextButton(
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                context.read<CollectionProvider>().addCollection(val);
                Navigator.pop(ctx);
              }
            },
            child: Text(t('collections.add')),
          ),
        ],
      ),
    );
  }

  void _showCollectionOptions(BuildContext context, collection) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: Text(t('collections.rename')),
              onTap: () {
                Navigator.pop(ctx);
                _showRenameDialog(context, collection);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: ctx.colors.statusError),
              title: Text(
                t('common.delete'),
                style: TextStyle(color: ctx.colors.statusError),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteConfirm(context, collection);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, collection) {
    final controller = TextEditingController(text: collection.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('collections.rename')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: t('collections.nameHint')),
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              context.read<CollectionProvider>().renameCollection(collection.id, val.trim());
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('common.cancel')),
          ),
          TextButton(
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                context.read<CollectionProvider>().renameCollection(collection.id, val);
                Navigator.pop(ctx);
              }
            },
            child: Text(t('common.save')),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, collection) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('collections.deleteConfirm')),
        content: Text(t('collections.deleteMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('common.cancel')),
          ),
          TextButton(
            onPressed: () {
              context.read<CollectionProvider>().deleteCollection(collection.id);
              Navigator.pop(ctx);
            },
            child: Text(
              t('common.delete'),
              style: TextStyle(color: ctx.colors.statusError),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final linkProvider = context.watch<LinkProvider>();
    final collectionProvider = context.watch<CollectionProvider>();
    final collections = collectionProvider.collections;
    final activeCollectionId = collectionProvider.activeCollectionId;

    var allLinks = linkProvider.links;

    if (activeCollectionId != null) {
      allLinks = allLinks.where((l) => l.collectionId == activeCollectionId).toList();
    }

    final filteredLinks = _showUnreadOnly
        ? allLinks.where((l) => !l.isRead).toList()
        : allLinks;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          activeCollectionId != null
              ? (collectionProvider.activeCollection?.name ?? t('home.title'))
              : t('home.title'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: activeCollectionId != null
            ? [
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: t('collections.clearFilter'),
                  onPressed: () => collectionProvider.setActiveCollection(null),
                ),
              ]
            : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Collection chips + add button ─────────────────────────────────
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                _CollectionChip(
                  label: t('home.filterAll'),
                  selected: activeCollectionId == null,
                  onTap: () => collectionProvider.setActiveCollection(null),
                  icon: Icons.inbox_outlined,
                ),
                const SizedBox(width: 6),
                ...collections.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _CollectionChip(
                    label: e.value.name,
                    selected: activeCollectionId == e.value.id,
                    color: e.value.color,
                    colorFallbackIndex: e.key,
                    onTap: () => collectionProvider.setActiveCollection(e.value.id),
                    onLongPress: () => _showCollectionOptions(context, e.value),
                    icon: Icons.folder_outlined,
                  ),
                )),
                // Add collection button
                _AddCollectionChip(
                  onTap: () => _showAddCollectionDialog(context),
                ),
              ],
            ),
          ),
          // ── Filter chips ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                _FilterChip(
                  label: t('home.filterAll'),
                  selected: !_showUnreadOnly,
                  onTap: () => setState(() => _showUnreadOnly = false),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: t('home.filterUnread'),
                  selected: _showUnreadOnly,
                  onTap: () => setState(() => _showUnreadOnly = true),
                ),
              ],
            ),
          ),
          // ── Main content ─────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => linkProvider.loadLinks(),
              child: linkProvider.isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: context.colors.accent))
                  : filteredLinks.isEmpty
                      ? _buildEmptyState(activeCollectionId != null)
                      : _buildGroupedListView(context, filteredLinks),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isFiltered) {
    final c = context.colors;
    return ListView(
      children: [
        const SizedBox(height: 200),
        Center(
          child: Column(
            children: [
              Icon(
                isFiltered ? Icons.folder_open : Icons.link_off,
                size: 64,
                color: c.textTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                isFiltered ? t('collections.emptyTitle') : t('home.emptyTitle'),
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  color: c.textTertiary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isFiltered
                    ? t('collections.emptySubtitle')
                    : t('home.emptySubtitle'),
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: c.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroupedListView(BuildContext context, List<LinkItem> links) {
    final items = _buildGroupedList(context, links);
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: items.length,
      itemBuilder: (_, i) => items[i],
    );
  }
}

// ── Collection chip ────────────────────────────────────────────────────────────

class _CollectionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final IconData icon;
  final String? color;
  final int colorFallbackIndex;

  const _CollectionChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.icon,
    this.onLongPress,
    this.color,
    this.colorFallbackIndex = 0,
  });

  Color get _resolvedColor {
    final hex = (color?.isNotEmpty == true
            ? color!
            : _kCollectionColorFallbacks[colorFallbackIndex % _kCollectionColorFallbacks.length])
        .replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  static const _kCollectionColorFallbacks = [
    '#F5A623', '#5096F0', '#50D282', '#EE5555',
    '#A78BFA', '#4ECDC4', '#FF8C42', '#F06292',
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final chipColor = (color != null || label != t('home.filterAll'))
        ? _resolvedColor
        : c.accent;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? chipColor.withAlpha(38)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? chipColor : c.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: chipColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
            ] else ...[
              Icon(
                icon,
                size: 14,
                color: selected ? chipColor : c.textSecondary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? chipColor : c.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add collection chip ────────────────────────────────────────────────────────

class _AddCollectionChip extends StatelessWidget {
  final VoidCallback onTap;

  const _AddCollectionChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14, color: c.textTertiary),
            const SizedBox(width: 4),
            Text(
              t('collections.add'),
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: c.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter chip ────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? c.accentMuted : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c.accent : c.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? c.accent : c.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Group header ───────────────────────────────────────────────────────────────

class _GroupHeader extends StatelessWidget {
  final String label;

  const _GroupHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: context.colors.textTertiary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
