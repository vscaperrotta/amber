import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/link_item.dart';
import '../theme/void_colors.dart';
import '../utils/i18n.dart';
import 'edit_link_sheet.dart';

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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: VoidColors.darkBgSurface,
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
    final overlay = Overlay.of(context);
    OverlayEntry? entry;
    const panelWidth = 168.0;
    const panelHeight = 96.0;
    const margin = 8.0;

    final renderBox = context.findRenderObject() as RenderBox?;
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    double x, y;
    if (renderBox != null && renderBox.hasSize) {
      final pos = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      x = pos.dx + (size.width - panelWidth) / 2;
      y = pos.dy + size.height + margin;
      if (x < padding.left + margin) {
        x = padding.left + margin;
      } else if (x + panelWidth >
          screenSize.width - padding.right - margin) {
        x = screenSize.width - padding.right - margin - panelWidth;
      }
      if (y + panelHeight >
          screenSize.height - padding.bottom - margin) {
        y = pos.dy - panelHeight - margin;
      }
    } else {
      x = (screenSize.width - panelWidth) / 2;
      y = (screenSize.height - panelHeight) / 2;
    }

    entry = OverlayEntry(
      builder: (ctx) {
        final mediaQuery = MediaQuery.of(ctx);
        return Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => entry?.remove(),
              child: SizedBox(
                width: mediaQuery.size.width,
                height: mediaQuery.size.height,
              ),
            ),
            Positioned(
              left: x,
              top: y,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: panelWidth,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: VoidColors.darkBgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: VoidColors.darkBorder),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          entry?.remove();
                          _openEditSheet(context);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.edit,
                                size: 20,
                                color: VoidColors.darkAccent,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  t('linkCard.editTooltip'),
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: VoidColors.darkTextPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: VoidColors.darkBorder,
                      ),
                      InkWell(
                        onTap: () {
                          entry?.remove();
                          _confirmAndDelete(context);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.delete,
                                size: 20,
                                color: VoidColors.darkStatusError,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  t('common.delete'),
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: VoidColors.darkStatusError,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    // In selectable mode, wrap with a simple checkable tile — no swipe-to-delete
    if (selectable) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        decoration: BoxDecoration(
          color: selected
              ? VoidColors.darkAccentMuted
              : VoidColors.darkBgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? VoidColors.darkAccent : VoidColors.darkBorder,
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
                  activeColor: VoidColors.darkAccent,
                  checkColor: VoidColors.accentOnPrimary,
                  side: const BorderSide(color: VoidColors.darkBorder),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    link.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: VoidColors.darkTextPrimary,
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

    return GestureDetector(
      onLongPress: () => _showActionMenu(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        decoration: BoxDecoration(
          color: VoidColors.darkBgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: link.isRead ? VoidColors.darkBorder : VoidColors.darkAccent,
            width: link.isRead ? 1.0 : 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openUrl(context, link.url),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Thumbnail — flush left/top/bottom, fills full card height
                if (link.thumbnail != null && link.thumbnail!.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    child: SizedBox(
                      width: 88,
                      child: CachedNetworkImage(
                        imageUrl: link.thumbnail!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            Container(color: VoidColors.darkBgElevated),
                        placeholder: (_, __) =>
                            Container(color: VoidColors.darkBgElevated),
                      ),
                    ),
                  ),
                // Text content
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      link.thumbnail != null && link.thumbnail!.isNotEmpty
                          ? 12
                          : 14,
                      14,
                      14,
                      14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!link.isRead)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 5,
                                  right: 6,
                                ),
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: VoidColors.darkAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                link.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: VoidColors.darkTextPrimary,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: onFavoriteToggle,
                              child: Tooltip(
                                message: link.isFavorite
                                    ? t('linkCard.removeFavorite')
                                    : t('linkCard.addFavorite'),
                                child: Icon(
                                  link.isFavorite
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 28,
                                  color: link.isFavorite
                                      ? VoidColors.darkAccent
                                      : VoidColors.darkTextTertiary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Domain
                        Text(
                          _extractDomain(link.url),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: VoidColors.darkTextTertiary,
                          ),
                        ),
                        // Tags
                        if (link.tags.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: link.tags
                                .map(
                                  (tag) => Chip(label: Text(tag.toUpperCase())),
                                )
                                .toList(),
                          ),
                        ],
                        const SizedBox(height: 6),
                        // Timestamp + read toggle
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _formatDate(link.createdAt),
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: VoidColors.darkTextTertiary,
                                ),
                              ),
                            ),
                            if (onReadToggle != null)
                              GestureDetector(
                                onTap: onReadToggle,
                                child: Tooltip(
                                  message: link.isRead
                                      ? t('link.markUnread')
                                      : t('link.markRead'),
                                  child: Icon(
                                    link.isRead
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 28,
                                    color: link.isRead
                                        ? VoidColors.darkTextTertiary
                                        : VoidColors.darkAccent,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
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
