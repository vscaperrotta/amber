import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app;
import '../providers/link_provider.dart';
import '../providers/collection_provider.dart';
import '../providers/ui_state_provider.dart';
import '../theme/app_colors.dart';
import '../utils/i18n.dart';
import '../screens/home_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/tags_screen.dart';
import '../screens/add_link_screen.dart';
import '../screens/options_screen.dart';
import '../theme/cool_icons.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  bool? _lastIsLoggedIn;

  static const List<Widget> _screens = [
    HomeScreen(),
    FavoritesScreen(),
    TagsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reloadData());
  }

  Future<void> _reloadData() async {
    await Future.wait([
      context.read<LinkProvider>().loadLinks(),
      context.read<CollectionProvider>().loadCollections(),
    ]);
  }

  Future<void> _openAddLink() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddLinkScreen()),
    );
    if (result == true && mounted) {
      context.read<LinkProvider>().loadLinks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<app.AuthProvider>().isLoggedIn;
    if (_lastIsLoggedIn != null && _lastIsLoggedIn != isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reloadData());
    }
    _lastIsLoggedIn = isLoggedIn;

    final selectMode = context.watch<UiStateProvider>().selectModeActive;
    final c = context.colors;

    final fab = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x80F5A623), // amber glow, 50% opacity
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _openAddLink,
        tooltip: t('nav.addLink'),
        backgroundColor: c.accent,
        foregroundColor: c.accentOnPrimary,
        elevation: 0,
        shape: const CircleBorder(),
        child: const Icon(CoolIcons.add),
      ),
    );

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      floatingActionButton: selectMode ? null : fab,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: selectMode
            ? const SizedBox(width: double.infinity, height: 0)
            : BottomAppBar(
            color: c.bgElevated,
            elevation: 0,
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: CoolIcons.homeOutline,
                  label: t('nav.home'),
                  selected: _selectedIndex == 0,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),
                _NavItem(
                  icon: CoolIcons.starOutline,
                  label: t('nav.favorites'),
                  selected: _selectedIndex == 1,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
                const SizedBox(width: 56), // spazio per il FAB
                _NavItem(
                  icon: CoolIcons.tagOutline,
                  label: t('nav.tags'),
                  selected: _selectedIndex == 2,
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
                _NavItem(
                  icon: CoolIcons.personOutline,
                  label: t('options.title'),
                  selected: false,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OptionsScreen()),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Single icon; active state is signalled by color only (amber),
    // never by swapping the glyph.
    // Label: always text-primary — never amber.
    final c = context.colors;
    final activeIconColor = c.accent;
    final inactiveIconColor = c.textTertiary;
    final labelColor = c.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? activeIconColor : inactiveIconColor,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
