import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/auth_provider.dart' as app;
import '../providers/link_provider.dart';
import '../providers/collection_provider.dart';
import '../theme/app_colors.dart';
import '../utils/i18n.dart';
import '../utils/dialogs.dart';
import '../utils/collection_dialogs.dart';
import '../widgets/header_icon_button.dart';
import 'auth_screen.dart';
import '../theme/cool_icons.dart';

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

  Future<void> _clearLibrary() async {
    final confirmed = await confirmDelete(
      context,
      title: t('options.clearLibraryTitle'),
      message: t('options.clearLibraryMessage'),
    );
    if (confirmed == true && mounted) {
      await context.read<LinkProvider>().clearAll();
    }
  }

  void _showManageFolders() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.bgSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _ManageFoldersSheet(),
    );
  }

  // ── Section header helper ─────────────────────────────────────────────────

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: AppFonts.body(
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
              style: AppFonts.body(
                fontSize: 12,
                color: c.textTertiary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(
              authProvider.user?.email ?? '',
              style: AppFonts.body(
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
              CoolIcons.logout,
              size: 18,
              color: c.statusError,
            ),
            title: Text(
              t('options.signOut'),
              style: AppFonts.body(color: c.statusError),
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
          title: Text(
            t('options.signIn'),
            style: AppFonts.body(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          trailing: Icon(
            CoolIcons.chevronRight,
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

  // ── Statistics section ────────────────────────────────────────────────────

  Widget _buildStatsSection(
      LinkProvider linkProvider, CollectionProvider collectionProvider) {
    final total = linkProvider.links.length;
    final favs = linkProvider.favoriteLinks.length;
    final tags = linkProvider.allTags.length;
    final folders = collectionProvider.collections.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatTile(label: t('options.totalLinks'), value: '$total'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(label: t('options.favorites'), value: '$favs'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatTile(label: t('options.tags'), value: '$tags'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(label: t('options.folders'), value: '$folders'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Data section ───────────────────────────────────────────────────────────

  Widget _buildDataSection() {
    final c = context.colors;
    return _card(
      children: [
        ListTile(
          dense: true,
          leading: Icon(CoolIcons.folder, size: 18, color: c.textSecondary),
          title: Text(
            t('collections.manage'),
            style: AppFonts.body(color: c.textPrimary),
          ),
          onTap: _showManageFolders,
        ),
        Divider(height: 1, color: c.border),
        ListTile(
          dense: true,
          leading: Icon(CoolIcons.download, size: 18, color: c.textSecondary),
          title: Text(
            t('options.exportJson'),
            style: AppFonts.body(color: c.textPrimary),
          ),
          onTap: _exportJson,
        ),
        Divider(height: 1, color: c.border),
        ListTile(
          dense: true,
          leading: Icon(CoolIcons.deleteOutline, size: 18, color: c.statusError),
          title: Text(
            t('options.clearLibrary'),
            style: AppFonts.body(color: c.statusError),
          ),
          onTap: _clearLibrary,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final authProvider = context.watch<app.AuthProvider>();
    final linkProvider = context.watch<LinkProvider>();
    final collectionProvider = context.watch<CollectionProvider>();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  HeaderIconButton(
                    icon: CoolIcons.chevronLeft,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    t('options.title'),
                    style: AppFonts.display(
                      fontSize: 20,
                      color: c.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            _sectionHeader(t('options.sectionAccount')),
            _buildAccountSection(authProvider, linkProvider),
            _sectionHeader(t('options.sectionStats')),
            _buildStatsSection(linkProvider, collectionProvider),
            _sectionHeader(t('options.sectionData')),
            _buildDataSection(),
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Center(
                child: Text(
                  t('options.footer'),
                  style: AppFonts.body(fontSize: 12, color: c.textTertiary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat tile ───────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppFonts.body(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: c.accent,
            ),
          ),
          Text(
            label,
            style: AppFonts.body(
              fontSize: 12,
              color: c.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Manage folders bottom sheet ─────────────────────────────────────────────

class _ManageFoldersSheet extends StatelessWidget {
  const _ManageFoldersSheet();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final collections = context.watch<CollectionProvider>().collections;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              t('collections.manage'),
              style: AppFonts.display(fontSize: 18, color: c.textPrimary),
            ),
          ),
          if (collections.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(
                t('collections.none'),
                style: AppFonts.body(color: c.textTertiary),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: collections.length,
                itemBuilder: (context, i) {
                  final item = collections[i];
                  return ListTile(
                    leading: Icon(CoolIcons.folder, size: 18, color: c.textSecondary),
                    title: Text(
                      item.name,
                      style: AppFonts.body(color: c.textPrimary),
                    ),
                    trailing: Icon(CoolIcons.edit, size: 16, color: c.textTertiary),
                    onTap: () => showCollectionOptionsSheet(context, item),
                  );
                },
              ),
            ),
          Divider(height: 1, color: c.border),
          ListTile(
            leading: Icon(CoolIcons.add, size: 18, color: c.accent),
            title: Text(
              t('collections.add'),
              style: AppFonts.body(fontWeight: FontWeight.w600, color: c.accent),
            ),
            onTap: () => showAddCollectionDialog(context),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
