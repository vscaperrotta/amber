import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/link_item.dart';
import '../providers/link_provider.dart';
import '../theme/app_colors.dart';
import '../utils/i18n.dart';
import '../widgets/link_card.dart';

// ── Time bucket helpers (mirrors home_screen.dart) ────────────────────────────

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

// ── FavoritesScreen ───────────────────────────────────────────────────────────

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _showUnreadOnly = false;

  List<Widget> _buildGroupedItems(
      BuildContext context, List<LinkItem> links) {
    final grouped = <_TimeBucket, List<LinkItem>>{};
    for (final link in links) {
      final b = _bucketFor(link.createdAt);
      grouped.putIfAbsent(b, () => []).add(link);
    }

    final items = <Widget>[];
    for (final bucket in _TimeBucket.values) {
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
          onDismissed: () =>
              context.read<LinkProvider>().deleteLink(link.id),
          onReadToggle: () =>
              context.read<LinkProvider>().toggleRead(link.id),
        ));
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final linkProvider = context.watch<LinkProvider>();
    final favorites = linkProvider.favoriteLinks;
    final filtered = _showUnreadOnly
        ? favorites.where((l) => !l.isRead).toList()
        : favorites;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t('favorites.title'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Filter chips ───────────────────────────────────────────────────
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
          // ── Content ────────────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => linkProvider.loadLinks(),
              child: linkProvider.isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                          color: context.colors.accent))
                  : filtered.isEmpty
                      ? _buildEmptyState()
                      : _buildGroupedList(context, filtered),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final c = context.colors;
    return ListView(
      children: [
        const SizedBox(height: 200),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.star_border,
                size: 64,
                color: c.textTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                t('favorites.emptyTitle'),
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  color: c.textTertiary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t('favorites.emptySubtitle'),
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

  Widget _buildGroupedList(BuildContext context, List<LinkItem> links) {
    final items = _buildGroupedItems(context, links);
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: items.length,
      itemBuilder: (_, i) => items[i],
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
