import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Small uppercase section label used above a group of list items
/// (e.g. "THIS WEEK", "#AGENTS").
class GroupHeader extends StatelessWidget {
  final String label;

  const GroupHeader({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: context.colors.textTertiary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
