import 'package:flutter/material.dart';
import 'theme/app_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart' as app;
import 'providers/link_provider.dart';
import 'providers/collection_provider.dart';
import 'providers/ui_state_provider.dart';
import 'screens/add_link_screen.dart';
import 'theme/void_colors.dart';
import 'theme/app_colors.dart';
import 'widgets/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }
  runApp(const AmberApp());
}

class AmberApp extends StatefulWidget {
  const AmberApp({super.key});

  @override
  State<AmberApp> createState() => _AmberAppState();
}

class _AmberAppState extends State<AmberApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _setupShareReceiver();
  }

  void _setupShareReceiver() {
    // Gestisce i link condivisi quando l'app è già aperta
    ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedText(value.first.path);
      }
    });

    // Gestisce il link condiviso che ha aperto l'app
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedText(value.first.path);
      }
    });
  }

  void _handleSharedText(String sharedText) {
    // Estrae l'URL dal testo condiviso
    final url = _extractUrl(sharedText);
    if (url != null) {
      // Naviga alla schermata di aggiunta con l'URL precompilato
      _navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => AddLinkScreen(initialUrl: url),
        ),
      );
    }
  }

  String? _extractUrl(String text) {
    // Cerca un URL nel testo condiviso
    final urlRegex = RegExp(
      r'https?://[^\s]+',
      caseSensitive: false,
    );
    final match = urlRegex.firstMatch(text);
    return match?.group(0) ?? (text.trim().isNotEmpty ? text.trim() : null);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => app.AuthProvider()),
        ChangeNotifierProvider(create: (_) => LinkProvider()),
        ChangeNotifierProvider(create: (_) => CollectionProvider()),
        ChangeNotifierProvider(create: (_) => UiStateProvider()),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'Amber',
        debugShowCheckedModeBanner: false,
        // ── Light theme ────────────────────────────────────────────────────────
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          fontFamily: AppFonts.body().fontFamily,
          scaffoldBackgroundColor: VoidColors.lightBgPrimary,
          colorScheme: const ColorScheme.light(
            primary: VoidColors.lightAccent,
            onPrimary: VoidColors.lightTextPrimary,
            secondary: VoidColors.lightTextSecondary,
            onSecondary: VoidColors.lightTextPrimary,
            surface: VoidColors.lightBgSurface,
            onSurface: VoidColors.lightTextPrimary,
            surfaceContainerHighest: VoidColors.lightBgElevated,
            error: VoidColors.lightStatusError,
            onError: VoidColors.lightBgSurface,
            outline: VoidColors.lightBorder,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: VoidColors.lightBgPrimary,
            foregroundColor: VoidColors.lightTextPrimary,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: AppFonts.body(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: VoidColors.lightTextPrimary,
              letterSpacing: -0.3,
            ),
            iconTheme: const IconThemeData(color: VoidColors.lightTextTertiary),
          ),
          bottomAppBarTheme: const BottomAppBarThemeData(
            color: VoidColors.lightBgElevated,
            elevation: 0,
            padding: EdgeInsets.zero,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: VoidColors.lightAccent,
            foregroundColor: VoidColors.accentOnPrimary,
            elevation: 0,
            focusElevation: 0,
            hoverElevation: 0,
            highlightElevation: 0,
          ),
          cardTheme: CardThemeData(
            color: VoidColors.lightBgSurface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: VoidColors.lightBorder, width: 1),
            ),
            margin: EdgeInsets.zero,
          ),
          chipTheme: ChipThemeData(
            backgroundColor: VoidColors.lightBgElevated,
            side: const BorderSide(color: VoidColors.lightBorder),
            labelStyle: AppFonts.body(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: VoidColors.lightTextSecondary,
              letterSpacing: 0.5,
            ),
            labelPadding: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            shape: const StadiumBorder(),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: VoidColors.lightBgElevated,
            hintStyle: AppFonts.body(
              color: VoidColors.lightTextTertiary,
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: VoidColors.lightBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: VoidColors.lightBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: VoidColors.lightBorderFocus,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 12,
            ),
          ),
          dividerTheme: const DividerThemeData(
            color: VoidColors.lightBorder,
            thickness: 1,
          ),
          listTileTheme: const ListTileThemeData(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
          snackBarTheme: SnackBarThemeData(
            backgroundColor: VoidColors.lightBgElevated,
            contentTextStyle: AppFonts.body(
              color: VoidColors.lightTextPrimary,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            behavior: SnackBarBehavior.floating,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: VoidColors.lightAccent,
              textStyle: AppFonts.body(fontWeight: FontWeight.w600),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: VoidColors.lightAccent,
              foregroundColor: VoidColors.accentOnPrimary,
              textStyle: AppFonts.body(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: VoidColors.lightAccent,
          ),
          extensions: const [AppColors.light],
        ),
        // ── Dark theme ─────────────────────────────────────────────────────────
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          fontFamily: AppFonts.body().fontFamily,
          scaffoldBackgroundColor: VoidColors.darkBgPrimary,
          colorScheme: const ColorScheme.dark(
            primary: VoidColors.darkAccent,
            onPrimary: VoidColors.accentOnPrimary,
            secondary: VoidColors.darkTextSecondary,
            onSecondary: VoidColors.accentOnPrimary,
            surface: VoidColors.darkBgSurface,
            onSurface: VoidColors.darkTextPrimary,
            surfaceContainerHighest: VoidColors.darkBgElevated,
            error: VoidColors.darkStatusError,
            onError: VoidColors.darkTextPrimary,
            outline: VoidColors.darkBorder,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: VoidColors.darkBgPrimary,
            foregroundColor: VoidColors.darkTextPrimary,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: AppFonts.body(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: VoidColors.darkTextPrimary,
              letterSpacing: -0.3,
            ),
            iconTheme: const IconThemeData(color: VoidColors.darkTextTertiary),
          ),
          bottomAppBarTheme: const BottomAppBarThemeData(
            color: VoidColors.darkBgElevated,
            elevation: 0,
            padding: EdgeInsets.zero,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: VoidColors.darkAccent,
            foregroundColor: VoidColors.accentOnPrimary,
            elevation: 0,
            focusElevation: 0,
            hoverElevation: 0,
            highlightElevation: 0,
          ),
          cardTheme: CardThemeData(
            color: VoidColors.darkBgSurface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: VoidColors.darkBorder, width: 1),
            ),
            margin: EdgeInsets.zero,
          ),
          chipTheme: ChipThemeData(
            backgroundColor: VoidColors.darkBgElevated,
            side: const BorderSide(color: VoidColors.darkBorder),
            labelStyle: AppFonts.body(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: VoidColors.darkTextSecondary,
              letterSpacing: 0.5,
            ),
            labelPadding: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            shape: const StadiumBorder(),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: VoidColors.darkBgElevated,
            hintStyle: AppFonts.body(
              color: VoidColors.darkTextSecondary,
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: VoidColors.darkBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: VoidColors.darkBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: VoidColors.darkBorderFocus, // neutral gray, NOT amber
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 12,
            ),
          ),
          dividerTheme: const DividerThemeData(
            color: VoidColors.darkBorder,
            thickness: 1,
          ),
          listTileTheme: const ListTileThemeData(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
          snackBarTheme: SnackBarThemeData(
            backgroundColor: VoidColors.darkBgElevated,
            contentTextStyle: AppFonts.body(
              color: VoidColors.darkTextPrimary,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            behavior: SnackBarBehavior.floating,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: VoidColors.darkAccent,
              textStyle: AppFonts.body(fontWeight: FontWeight.w600),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: VoidColors.darkAccent,
              foregroundColor: VoidColors.accentOnPrimary,
              textStyle: AppFonts.body(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: VoidColors.darkAccent,
          ),
          extensions: const [AppColors.dark],
        ),
        themeMode: ThemeMode.system,
        home: const MainScaffold(),
      ),
    );
  }
}
