import 'package:flutter/material.dart';
import '../theme/app_fonts.dart';
import 'package:provider/provider.dart';
import '../models/link_item.dart';
import '../providers/link_provider.dart';
import '../providers/collection_provider.dart';
import '../theme/app_colors.dart';
import '../utils/i18n.dart';
import '../utils/dialogs.dart';
import '../widgets/link_card.dart';
import '../widgets/empty_state_view.dart';
import '../theme/cool_icons.dart';

/// Full-text search across saved links — title, domain and tags.
/// Reached from the search icon on Home.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<LinkItem> _filter(List<LinkItem> links) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return links.where((l) {
      return l.title.toLowerCase().contains(q) ||
          l.url.toLowerCase().contains(q) ||
          l.tags.any((tag) => tag.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final links = context.watch<LinkProvider>().links;
    final results = _filter(links);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: (val) => setState(() => _query = val),
          style: AppFonts.body(color: c.textPrimary, fontSize: 16),
          decoration: InputDecoration(
            hintText: t('home.searchHint'),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide.none,
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide.none,
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: c.bgElevated,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(CoolIcons.close),
              onPressed: () => setState(() {
                _controller.clear();
                _query = '';
              }),
            ),
        ],
      ),
      body: _query.isEmpty
          ? const SizedBox.shrink()
          : results.isEmpty
              ? Center(
                  child: EmptyStateView(
                    icon: CoolIcons.searchOff,
                    title: t('search.emptyTitle'),
                    subtitle: '',
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: results.length,
                  itemBuilder: (_, i) {
                    final link = results[i];
                    return LinkCard(
                      key: ValueKey(link.id),
                      link: link,
                      stripeColor: context
                          .read<CollectionProvider>()
                          .colorForCollectionId(link.collectionId),
                      onFavoriteToggle: () =>
                          context.read<LinkProvider>().toggleFavorite(link.id),
                      onReadToggle: () =>
                          context.read<LinkProvider>().toggleRead(link.id),
                      onDismissConfirm: () => confirmDelete(
                        context,
                        title: t('dialog.deleteTitle'),
                        message: t('dialog.deleteMessage'),
                      ),
                      onDismissed: () =>
                          context.read<LinkProvider>().deleteLink(link.id),
                    );
                  },
                ),
    );
  }
}
