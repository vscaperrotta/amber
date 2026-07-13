import 'package:flutter/material.dart';
import '../theme/app_fonts.dart';
import '../theme/app_colors.dart';

/// A single row in an [showActionSheet] bottom sheet.
class ActionSheetItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const ActionSheetItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
}

/// Native bottom sheet for a short list of contextual actions —
/// the app-wide replacement for ad-hoc popup menus (long-press on a
/// link, collection rename/delete, etc). Tapping a row closes the
/// sheet then invokes its [ActionSheetItem.onTap].
Future<void> showActionSheet(
  BuildContext context, {
  String? title,
  required List<ActionSheetItem> items,
}) {
  final c = context.colors;
  return showModalBottomSheet(
    context: context,
    backgroundColor: c.bgSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: AppFonts.body(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: c.textTertiary,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          for (final item in items)
            ListTile(
              leading: Icon(item.icon, size: 20, color: item.color ?? c.textPrimary),
              title: Text(
                item.label,
                style: AppFonts.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: item.color ?? c.textPrimary,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                item.onTap();
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
