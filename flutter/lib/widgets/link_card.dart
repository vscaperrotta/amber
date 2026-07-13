import 'package:flutter/material.dart';
import '../theme/app_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/link_item.dart';
import '../theme/app_colors.dart';
import '../utils/i18n.dart';
import 'action_sheet.dart';
import 'edit_link_sheet.dart';
import 'link_avatar.dart';
import '../theme/cool_icons.dart';

class LinkCard extends StatelessWidget {
  final LinkItem link;
  final VoidCallback onFavoriteToggle;
  final Future<bool?> Function() onDismissConfirm;
  final VoidCallback onDismissed;
  final String? keyPrefix;

  /// When true, shows a checkbox overlay and disables the URL tap.
  final bool selectable;

  /// Whether this card is currently selected (used when [selectable] is true).
  final bool selected;

  /// Called when the checkbox state changes (only used when [selectable]).
  final ValueChanged<bool>? onSelectChanged;

  /// Called when the user taps the read/unread toggle eye icon.
  final VoidCallback? onReadToggle;

  /// Left accent stripe color — the link's folder color. Null (no folder,
  /// or folder not resolved) means no stripe.
  final Color? stripeColor;

  const LinkCard({
    super.key,
    required this.link,
    required this.onFavoriteToggle,
    required this.onDismissConfirm,
    required this.onDismissed,
    this.keyPrefix,
    this.selectable = false,
    this.selected = false,
    this.onSelectChanged,
    this.onReadToggle,
    this.stripeColor,
  });

  Future<void> _openUrl(BuildContext context, String url) async {
    String urlToOpen = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      urlToOpen = 'https://$url';
    }
    final uri = Uri.parse(urlToOpen);
    try {
      final canLaunch = await canLaunchUrl(uri);
      if (!canLaunch) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(t('linkCard.cannotOpen'))));
        }
        return;
      }
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched && !link.isRead) {
        onReadToggle?.call();
      } else if (!launched && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t('linkCard.cannotOpen'))));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t('linkCard.cannotOpen'))));
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return t('linkCard.timeNow');
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return t('linkCard.timeDays', {'n': '${diff.inDays}'});
    return '${date.day}/${date.month}/${date.year}';
  }

  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      return uri.host.replaceFirst('www.', '');
    } catch (_) {
      return url;
    }
  }

  void _openEditSheet(BuildContext context) {
    final c = context.colors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => EditLinkSheet(link: link),
    );
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    final confirmed = await onDismissConfirm();
    if (confirmed == true) onDismissed();
  }

  void _showActionMenu(BuildContext context) {
    final c = context.colors;
    showActionSheet(
      context,
      items: [
        if (onReadToggle != null)
          ActionSheetItem(
            icon: link.isRead
                ? CoolIcons.eyeOff
                : CoolIcons.eye,
            label: link.isRead ? t('link.markUnread') : t('link.markRead'),
            onTap: () => onReadToggle!(),
          ),
        ActionSheetItem(
          icon: CoolIcons.edit,
          label: t('linkCard.editTooltip'),
          onTap: () => _openEditSheet(context),
        ),
        ActionSheetItem(
          icon: CoolIcons.deleteFilled,
          label: t('common.delete'),
          color: c.statusError,
          onTap: () => _confirmAndDelete(context),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    // In selectable mode, wrap with a simple checkable tile — no swipe-to-delete
    if (selectable) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        decoration: BoxDecoration(
          color: selected ? c.accentMuted : c.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? c.accent : c.border,
          ),
        ),
        child: InkWell(
          onTap: () => onSelectChanged?.call(!selected),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Checkbox(
                  value: selected,
                  onChanged: (v) => onSelectChanged?.call(v ?? false),
                  activeColor: c.accent,
                  checkColor: c.accentOnPrimary,
                  side: BorderSide(color: c.border),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    link.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.body(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final domain = _extractDomain(link.url);

    return GestureDetector(
      onLongPress: () => _showActionMenu(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        decoration: BoxDecoration(
          color: c.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openUrl(context, link.url),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left accent stripe — the link's folder color, if any.
                if (stripeColor != null) Container(width: 4, color: stripeColor),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 0, 14),
                  // Align keeps the avatar a fixed square, top-aligned —
                  // without it the Row's stretch forces it to full height.
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: LinkAvatar(
                      domain: domain,
                      imageUrl: link.thumbnail,
                      size: 56,
                    ),
                  ),
                ),
                // Text content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 14, 8, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          link.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.body(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Unread dot + domain + time
                        Row(
                          children: [
                            if (!link.isRead) ...[
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: c.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                            ],
                            Expanded(
                              child: Text(
                                '$domain · ${_formatDate(link.createdAt)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppFonts.body(
                                  fontSize: 11,
                                  color: c.textTertiary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Tags
                        if (link.tags.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: link.tags
                                .map(
                                  (tag) => Chip(
                                    label: Text(tag.toUpperCase()),
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Trailing actions — favorite star + overflow menu.
                // Grouped top-right with card-matching padding so they
                // never glue to the edge or spread apart on tall cards.
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 14, 14, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: onFavoriteToggle,
                        child: Tooltip(
                          message: link.isFavorite
                              ? t('linkCard.removeFavorite')
                              : t('linkCard.addFavorite'),
                          child: Icon(
                            link.isFavorite ? CoolIcons.starFilled : CoolIcons.starOutline,
                            size: 24,
                            color:
                                link.isFavorite ? c.accent : c.textTertiary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () => _showActionMenu(context),
                        child: Icon(
                          CoolIcons.moreVert,
                          size: 20,
                          color: c.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
