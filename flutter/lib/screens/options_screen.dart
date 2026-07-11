import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/auth_provider.dart' as app;
import '../providers/link_provider.dart';
import '../theme/app_colors.dart';
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
          color: context.colors.textTertiary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    final c = context.colors;
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: c.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border, width: 1),
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
    final c = context.colors;
    if (authProvider.isLoggedIn) {
      return _card(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              t('options.signedInAs'),
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: c.textTertiary,
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
                color: c.textPrimary,
              ),
            ),
          ),
          Divider(height: 1, color: c.border),
          ListTile(
            dense: true,
            leading: Icon(
              Icons.logout,
              size: 18,
              color: c.statusError,
            ),
            title: Text(
              t('options.signOut'),
              style: GoogleFonts.outfit(color: c.statusError),
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
          leading: Icon(
            Icons.person_outline,
            size: 18,
            color: c.textSecondary,
          ),
          title: Text(
            t('options.signIn'),
            style: GoogleFonts.outfit(color: c.textPrimary),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: c.textTertiary,
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
    final c = context.colors;
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
        Divider(height: 1, color: c.border),
        ListTile(
          dense: true,
          leading: Icon(
            Icons.download_outlined,
            size: 18,
            color: c.textSecondary,
          ),
          title: Text(
            t('options.exportJson'),
            style: GoogleFonts.outfit(color: c.textPrimary),
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
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.bgElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border),
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
              color: c.accent,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: c.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
