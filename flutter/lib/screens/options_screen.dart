import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/auth_provider.dart' as app;
import '../providers/link_provider.dart';
import '../theme/void_colors.dart';
import '../utils/i18n.dart';
import 'auth_screen.dart';

class OptionsScreen extends StatefulWidget {
  const OptionsScreen({super.key});

  @override
  State<OptionsScreen> createState() => _OptionsScreenState();
}

class _OptionsScreenState extends State<OptionsScreen> {
  Future<void> _exportJson() async {
    final links = context.read<LinkProvider>().links;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final now = DateTime.now().toUtc();
      final nowIso = now.toIso8601String();
      final dateStr = nowIso.substring(0, 10);

      final exportedLinks = links.map((l) {
        return <String, Object?>{
          'id': l.id,
          'url': l.url,
          'title': l.title,
          'savedAt': l.createdAt.toUtc().toIso8601String(),
          'isRead': l.isRead,
          'isFavorite': l.isFavorite,
          'tags': l.tags,
          'description': '',
          'thumbnail': l.thumbnail ?? '',
          'note': l.note ?? '',
        };
      }).toList();

      final payload = <String, Object?>{
        'version': 1,
        'app': 'Amber',
        'exportedAt': nowIso,
        'count': links.length,
        'links': exportedLinks,
      };

      final jsonStr = JsonEncoder.withIndent('  ').convert(payload);
      final tmpDir = await getTemporaryDirectory();
      final file = File('${tmpDir.path}/amber-links-$dateStr.json');
      await file.writeAsString(jsonStr, encoding: utf8);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'Amber links export — $dateStr',
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(t('options.exportError'))),
      );
    }
  }

  // ── Section header helper ─────────────────────────────────────────────────

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: VoidColors.darkTextTertiary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: VoidColors.darkBgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: VoidColors.darkBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  // ── Account section ───────────────────────────────────────────────────────

  Widget _buildAccountSection(
      app.AuthProvider authProvider, LinkProvider linkProvider) {
    if (authProvider.isLoggedIn) {
      return _card(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              t('options.signedInAs'),
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: VoidColors.darkTextTertiary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(
              authProvider.user?.email ?? '',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: VoidColors.darkTextPrimary,
              ),
            ),
          ),
          const Divider(height: 1, color: VoidColors.darkBorder),
          ListTile(
            dense: true,
            leading: const Icon(
              Icons.logout,
              size: 18,
              color: VoidColors.darkStatusError,
            ),
            title: Text(
              t('options.signOut'),
              style: GoogleFonts.outfit(color: VoidColors.darkStatusError),
            ),
            onTap: () async {
              await authProvider.signOut();
              if (mounted) linkProvider.loadLinks();
            },
          ),
        ],
      );
    }

    return _card(
      children: [
        ListTile(
          dense: true,
          leading: const Icon(
            Icons.person_outline,
            size: 18,
            color: VoidColors.darkTextSecondary,
          ),
          title: Text(
            t('options.signIn'),
            style: GoogleFonts.outfit(color: VoidColors.darkTextPrimary),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: VoidColors.darkTextTertiary,
          ),
          onTap: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const AuthScreen()),
            );
            if (result == true && mounted) {
              await linkProvider.migrateLocalToCloud();
            }
          },
        ),
      ],
    );
  }

  // ── Collection section ────────────────────────────────────────────────────

  Widget _buildCollectionSection(LinkProvider linkProvider) {
    final total = linkProvider.links.length;
    final favs = linkProvider.favoriteLinks.length;

    return _card(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              _StatChip(label: t('options.totalLinks'), value: '$total'),
              const SizedBox(width: 12),
              _StatChip(label: t('options.favorites'), value: '$favs'),
            ],
          ),
        ),
        const Divider(height: 1, color: VoidColors.darkBorder),
        ListTile(
          dense: true,
          leading: const Icon(
            Icons.download_outlined,
            size: 18,
            color: VoidColors.darkTextSecondary,
          ),
          title: Text(
            t('options.exportJson'),
            style: GoogleFonts.outfit(color: VoidColors.darkTextPrimary),
          ),
          onTap: _exportJson,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<app.AuthProvider>();
    final linkProvider = context.watch<LinkProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t('options.title'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _sectionHeader(t('options.sectionAccount')),
          _buildAccountSection(authProvider, linkProvider),
          _sectionHeader(t('options.sectionCollection')),
          _buildCollectionSection(linkProvider),
        ],
      ),
    );
  }
}

// ── Small helper widgets ───────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: VoidColors.darkBgElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: VoidColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: VoidColors.darkAccent,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: VoidColors.darkTextTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

