import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'generated/database_manager.dart';
import 'routing/app_router.dart';
import 'services/web_persistence_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Creates the database on first run and applies any pending migrations
  // (generated from lib/generated/schemas/) on upgrade.
  await DatabaseManager.init(name: DatabaseManager.defaultDatabaseName);
  if (kIsWeb) {
    await WebPersistenceService.recordLaunch(DatabaseManager.currentDatabase);
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    this.initialLocation = '/',
    this.themeMode = ThemeMode.system,
    this.textScaler,
  });

  final String initialLocation;
  final ThemeMode themeMode;
  final TextScaler? textScaler;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router = AppRouter.create(
    initialLocation: widget.initialLocation,
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lightScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xff1565c0),
      brightness: Brightness.light,
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xff90caf9),
      brightness: Brightness.dark,
    );

    return MaterialApp.router(
      title: 'Native SQLite Demo',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: _theme(lightScheme),
      darkTheme: _theme(darkScheme),
      themeMode: widget.themeMode,
      builder: (context, child) {
        final textScaler = widget.textScaler;
        if (textScaler == null) return child!;
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        );
      },
    );
  }

  ThemeData _theme(ColorScheme colorScheme) => ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: colorScheme.surface,
    cardTheme: CardThemeData(
      elevation: 1,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: colorScheme.surface.withValues(alpha: 0.86),
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: colorScheme.surface.withValues(alpha: 0),
      scrolledUnderElevation: 0,
      systemOverlayStyle: colorScheme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    ),
  );
}
