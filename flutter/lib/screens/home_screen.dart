import 'package:flutter/material.dart';
import '../theme/app_fonts.dart';
import 'package:provider/provider.dart';
import '../models/link_item.dart';
import '../models/link_filter.dart';
import '../providers/link_provider.dart';
import '../providers/collection_provider.dart';
import '../theme/app_colors.dart';
import '../utils/i18n.dart';
import '../utils/time_bucket.dart';
import '../utils/dialogs.dart';
import '../utils/collection_dialogs.dart';
import '../widgets/link_card.dart';
import '../widgets/group_header.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/header_icon_button.dart';
import 'search_screen.dart';
import '../theme/cool_icons.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LinkFilter _filter = const LinkFilter();

  List<Widget> _buildGroupedList(BuildContext context, List<LinkItem> links) {
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
          onDismissed: () => context.read<LinkProvider>().deleteLink(link.id),
          onReadToggle: () => context.read<LinkProvider>().toggleRead(link.id),
        ));
      }
    }

    return items;
  }

  Future<void> _openFilterSheet(BuildContext context) async {
    final linkProvider = context.read<LinkProvider>();
    final collectionProvider = context.read<CollectionProvider>();
    final result = await showFilterSheet(
      context,
      current: _filter,
      collections: collectionProvider.collections,
      links: linkProvider.links,
      onAddCollection: () => showAddCollectionDialog(context),
      onCollectionLongPress: (c) => showCollectionOptionsSheet(context, c),
    );
    if (result != null && mounted) {
      setState(() => _filter = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final linkProvider = context.watch<LinkProvider>();
    final collectionProvider = context.watch<CollectionProvider>();

    var filteredLinks = linkProvider.links;
    if (_filter.collectionId != null) {
      filteredLinks = filteredLinks
          .where((l) => l.collectionId == _filter.collectionId)
          .toList();
    }
    if (_filter.unreadOnly) {
      filteredLinks = filteredLinks.where((l) => !l.isRead).toList();
    }
    if (_filter.tags.isNotEmpty) {
      filteredLinks = filteredLinks
          .where((l) => l.tags.any(_filter.tags.contains))
          .toList();
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: app title + search + filter ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      t('home.title'),
                      style: AppFonts.display(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  HeaderIconButton(
                    icon: CoolIcons.search,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  HeaderIconButton(
                    icon: CoolIcons.tune,
                    badge: _filter.activeCount > 0 ? _filter.activeCount : null,
                    onTap: () => _openFilterSheet(context),
                  ),
                ],
              ),
            ),
            // ── Main content ─────────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => linkProvider.loadLinks(),
                child: (linkProvider.isLoading || collectionProvider.isLoading) &&
                        linkProvider.links.isEmpty
                    ? Center(child: CircularProgressIndicator(color: c.accent))
                    : filteredLinks.isEmpty
                        ? _buildEmptyState(_filter.isActive)
                        : _buildGroupedListView(context, filteredLinks),
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
            icon: isFiltered ? CoolIcons.filterOff : CoolIcons.linkOff,
            title: isFiltered ? t('collections.emptyTitle') : t('home.emptyTitle'),
            subtitle: isFiltered ? t('collections.emptySubtitle') : t('home.emptySubtitle'),
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
