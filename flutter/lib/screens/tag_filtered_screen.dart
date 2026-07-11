import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/link_item.dart';
import '../providers/link_provider.dart';
import '../theme/app_colors.dart';
import '../utils/i18n.dart';
import '../widgets/link_card.dart';

class TagFilteredScreen extends StatelessWidget {
  final String tag;

  const TagFilteredScreen({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    final linkProvider = context.watch<LinkProvider>();
    final links = linkProvider.links.where((l) => l.tags.contains(tag)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(tag),
        centerTitle: true,
      ),
      body: links.isEmpty
          ? _buildEmptyState(context)
          : _buildLinkList(context, links),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link_off, size: 64, color: c.textTertiary),
          const SizedBox(height: 16),
          Text(
            t('tagFiltered.empty'),
            style: TextStyle(
              fontSize: 18,
              color: c.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkList(BuildContext context, List<LinkItem> links) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 32),
      itemCount: links.length,
      itemBuilder: (context, index) {
        final link = links[index];
        return LinkCard(
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
        );
      },
    );
  }
}
