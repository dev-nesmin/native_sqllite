import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/connection_screen.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(const SQLiteInspectorApp());
}

final _router = GoRouter(
  routes: <GoRoute>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const WelcomeScreen();
      },
    ),
    GoRoute(
      path: '/:port/:secret',
      builder: (BuildContext context, GoRouterState state) {
        final port = state.pathParameters['port']!;
        final secret = state.pathParameters['secret']!;
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: Scaffold(
            body: Material(
              child: ConnectionScreen(
                port: port,
                secret: secret,
              ),
            ),
          ),
        );
      },
    ),
  ],
);

class SQLiteInspectorApp extends StatelessWidget {
  const SQLiteInspectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SQLite Inspector',
      routeInformationProvider: _router.routeInformationProvider,
      routeInformationParser: _router.routeInformationParser,
      routerDelegate: _router.routerDelegate,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0277BD),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
    );
  }
}
