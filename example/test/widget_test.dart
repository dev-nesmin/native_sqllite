import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_sqlite/native_sqlite.dart';
import 'package:native_sqlite/testing.dart';

import 'package:native_sqlite_example/generated/database_manager.dart';
import 'package:native_sqlite_example/main.dart';
import 'package:native_sqlite_example/routing/adaptive_shell.dart';
import 'package:native_sqlite_example/screens/home_screen.dart';

void main() {
  const databaseName = 'widget_test';
  late NativeSqliteFfi backend;

  setUpAll(() async {
    backend = NativeSqliteTesting.useFfi();
    await NativeSqlite.deleteDatabase(databaseName);
    await DatabaseManager.init(name: databaseName);
  });

  tearDownAll(() async {
    await DatabaseManager.close();
    await NativeSqlite.deleteDatabase(databaseName);
    backend.dispose();
  });

  testWidgets('home screen lists every demo', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Native SQLite Example'), findsOneWidget);
    for (final demo in [
      'CRUD Operations',
      'Order Management',
      'Query Builder',
      'Advanced Features',
      'Background Sync',
      'Model Gallery',
      'Raw API & Errors',
      'Native Code Integration',
      'Database Statistics',
      'Database Inspector',
    ]) {
      await tester.scrollUntilVisible(find.text(demo), 200);
      expect(find.text(demo), findsOneWidget);
    }
  });

  testWidgets('inspector instructions are deep-linkable in debug mode', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp(initialLocation: '/inspector'));
    await tester.pumpAndSettle();

    expect(find.text('Database Inspector'), findsWidgets);
    expect(find.text('Open DevTools → native_sqlite'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(
      find.text('extensions:\n  - native_sqlite: true', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('first card starts below the app bar at supported widths', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    for (final width in [360.0, 800.0, 1280.0]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 800);

      await tester.pumpWidget(
        KeyedSubtree(key: UniqueKey(), child: const MyApp()),
      );
      await tester.pumpAndSettle();

      final appBarBottom = tester.getBottomLeft(find.byType(AppBar)).dy;
      final firstCardTop = tester.getTopLeft(find.byType(Card).first).dy;

      expect(
        firstCardTop,
        greaterThanOrEqualTo(appBarBottom),
        reason: 'The first card overlaps the app bar at width $width.',
      );
    }
  });

  testWidgets('routes are deep-linkable and navigation is adaptive', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;

    tester.view.physicalSize = const Size(360, 800);
    await tester.pumpWidget(const MyApp(initialLocation: '/query'));
    await tester.pumpAndSettle();
    expect(find.text('Query Builder Playground'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);

    tester.view.physicalSize = const Size(800, 800);
    await tester.pumpWidget(
      KeyedSubtree(
        key: UniqueKey(),
        child: const MyApp(initialLocation: '/query'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('home supports theme, text scale, and width matrix', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;

    for (final width in [360.0, 800.0, 1280.0]) {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        for (final scale in [1.0, 2.0]) {
          tester.view.physicalSize = Size(width, 800);
          await tester.pumpWidget(
            KeyedSubtree(
              key: UniqueKey(),
              child: MyApp(
                themeMode: mode,
                textScaler: TextScaler.linear(scale),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(
            Theme.of(tester.element(find.byType(HomeScreen))).brightness,
            mode == ThemeMode.dark ? Brightness.dark : Brightness.light,
          );
        }
      }
    }
  });

  testWidgets('home visual matrix matches goldens', (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;

    for (final width in [360.0, 800.0, 1280.0]) {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        for (final scale in [1.0, 2.0]) {
          tester.view.physicalSize = Size(width, 800);
          await tester.pumpWidget(
            KeyedSubtree(
              key: UniqueKey(),
              child: MyApp(
                themeMode: mode,
                textScaler: TextScaler.linear(scale),
              ),
            ),
          );
          await tester.pumpAndSettle();

          await expectLater(
            find.byType(AdaptiveShell),
            matchesGoldenFile(
              'goldens/home_${width.toInt()}_${mode.name}_x${scale.toInt()}.png',
            ),
          );
        }
      }
    }
  });
}
