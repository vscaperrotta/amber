import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/i18n.dart';

/// AppBar whose title switches to the active collection's name (with
/// a close action to clear the filter) whenever one is selected,
/// falling back to [defaultTitle] otherwise. Used by Home, Favorites
/// and Tags so collection filtering reads the same everywhere.
class CollectionScopedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String defaultTitle;
  final String? activeCollectionName;
  final VoidCallback onClearFilter;
  final List<Widget> extraActions;

  const CollectionScopedAppBar({
    super.key,
    required this.defaultTitle,
    required this.activeCollectionName,
    required this.onClearFilter,
    this.extraActions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        activeCollectionName ?? defaultTitle,
        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
      ),
      centerTitle: true,
      actions: [
        if (activeCollectionName != null)
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: t('collections.clearFilter'),
            onPressed: onClearFilter,
          ),
        ...extraActions,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
