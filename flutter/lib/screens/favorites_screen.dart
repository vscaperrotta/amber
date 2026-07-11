import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/link_item.dart';
import '../providers/link_provider.dart';
import '../providers/collection_provider.dart';
import '../theme/app_colors.dart';
import '../utils/i18n.dart';
import '../utils/time_bucket.dart';
import '../utils/dialogs.dart';
import '../widgets/link_card.dart';
import '../widgets/group_header.dart';
import '../widgets/pill_filter_chip.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/collection_scoped_app_bar.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _showUnreadOnly = false;

  List<Widget> _buildGroupedItems(
      BuildContext context, List<LinkItem> links) {
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
          onFavoriteToggle: () =>
              context.read<LinkProvider>().toggleFavorite(link.id),
          onDismissConfirm: () => confirmDelete(
            context,
            title: t('dialog.deleteTitle'),
            message: t('dialog.deleteMessage'),
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
    final collectionProvider = context.watch<CollectionProvider>();
    final activeCollectionId = collectionProvider.activeCollectionId;

    var favorites = linkProvider.favoriteLinks;
    if (activeCollectionId != null) {
      favorites = favorites.where((l) => l.collectionId == activeCollectionId).toList();
    }
    final filtered = _showUnreadOnly
        ? favorites.where((l) => !l.isRead).toList()
        : favorites;

    return Scaffold(
      appBar: CollectionScopedAppBar(
        defaultTitle: t('favorites.title'),
        activeCollectionName: collectionProvider.activeCollection?.name,
        onClearFilter: () => collectionProvider.setActiveCollection(null),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Filter chips ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                PillFilterChip(
                  label: t('home.filterAll'),
                  selected: !_showUnreadOnly,
                  onTap: () => setState(() => _showUnreadOnly = false),
                ),
                const SizedBox(width: 8),
                PillFilterChip(
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
                      ? _buildEmptyState(activeCollectionId != null)
                      : _buildGroupedList(context, filtered),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isFiltered) {
    return ListView(
      children: [
        const SizedBox(height: 200),
        Center(
          child: EmptyStateView(
            icon: Icons.star_border,
            title: isFiltered ? t('collections.emptyTitle') : t('favorites.emptyTitle'),
            subtitle: isFiltered ? t('collections.emptySubtitle') : t('favorites.emptySubtitle'),
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
