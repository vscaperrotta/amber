import 'package:flutter/material.dart';
import '../theme/app_fonts.dart';
import '../theme/app_colors.dart';

/// Centered icon + title + subtitle used for every "nothing here"
/// state across the app (no links, no favorites, no tags, filtered
/// to zero results). Callers wrap it in whatever scroll/layout
/// container the screen needs (ListView for pull-to-refresh, Center
/// otherwise).
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 64, color: c.textTertiary),
        const SizedBox(height: 16),
        Text(
          title,
          style: AppFonts.body(
            fontSize: 18,
            color: c.textTertiary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: AppFonts.body(
            fontSize: 14,
            color: c.textTertiary,
          ),
        ),
      ],
    );
  }
}
