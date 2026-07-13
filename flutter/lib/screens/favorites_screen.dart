import 'package:flutter/material.dart';
import '../theme/app_fonts.dart';
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
import '../theme/cool_icons.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _showUnreadOnly = false;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
          stripeColor:
              context.read<CollectionProvider>().colorForCollectionId(link.collectionId),
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
    final c = context.colors;
    final linkProvider = context.watch<LinkProvider>();

    var favorites = linkProvider.favoriteLinks;
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      favorites = favorites
          .where((l) =>
              l.title.toLowerCase().contains(q) ||
              l.url.toLowerCase().contains(q) ||
              l.tags.any((tag) => tag.toLowerCase().contains(q)))
          .toList();
    }
    final filtered = _showUnreadOnly
        ? favorites.where((l) => !l.isRead).toList()
        : favorites;
    final isFiltered = _query.trim().isNotEmpty || _showUnreadOnly;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text(
                t('favorites.title'),
                style: AppFonts.display(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _query = val),
                      style: AppFonts.body(fontSize: 14, color: c.textPrimary),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: t('favorites.searchHint'),
                        prefixIcon: Icon(CoolIcons.search, size: 20, color: c.textTertiary),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PillFilterChip(
                    label: t('home.filterUnread'),
                    selected: _showUnreadOnly,
                    onTap: () => setState(() => _showUnreadOnly = !_showUnreadOnly),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => linkProvider.loadLinks(),
                child: linkProvider.isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                            color: context.colors.accent))
                    : filtered.isEmpty
                        ? _buildEmptyState(isFiltered)
                        : _buildGroupedList(context, filtered),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isFiltered) {
    return ListView(
      children: [
        const SizedBox(height: 200),
        Center(
          child: EmptyStateView(
            icon: CoolIcons.starOutline,
            title: isFiltered ? t('search.emptyTitle') : t('favorites.emptyTitle'),
            subtitle: isFiltered ? '' : t('favorites.emptySubtitle'),
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
