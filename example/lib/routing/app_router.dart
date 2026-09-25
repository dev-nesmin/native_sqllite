import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../screens/advanced_features_screen.dart';
import '../screens/background_sync_screen.dart';
import '../screens/benchmarks_screen.dart';
import '../screens/crud_demo_screen.dart';
import '../screens/home_screen.dart';
import '../screens/inspector_screen.dart';
import '../screens/manual_api_screen.dart';
import '../screens/model_gallery_screen.dart';
import '../screens/native_integration_screen.dart';
import '../screens/order_management_screen.dart';
import '../screens/query_builder_demo_screen.dart';
import '../screens/statistics_screen.dart';
import '../screens/web_persistence_screen.dart';
import 'adaptive_shell.dart';

abstract final class AppRouter {
  static GoRouter create({String initialLocation = '/'}) => GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            AdaptiveShell(location: state.uri.path, child: child),
        routes: [
          _route('/', const HomeScreen()),
          _route('/crud', const CrudDemoScreen()),
          _route('/orders', const OrderManagementScreen()),
          _route('/query', const QueryBuilderDemoScreen()),
          _route('/advanced', const AdvancedFeaturesScreen()),
          _route('/background', const BackgroundSyncScreen()),
          if (!kReleaseMode) _route('/benchmarks', const BenchmarksScreen()),
          _route('/models', const ModelGalleryScreen()),
          _route('/raw', const ManualApiScreen()),
          _route('/native', const NativeIntegrationScreen()),
          _route('/statistics', const StatisticsScreen()),
          if (kIsWeb) _route('/web', const WebPersistenceScreen()),
          if (kDebugMode) _route('/inspector', const InspectorScreen()),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(child: Text('No example route for ${state.uri.path}')),
    ),
  );

  static GoRoute _route(String path, Widget page) => GoRoute(
    path: path,
    pageBuilder: (context, state) =>
        NoTransitionPage(key: state.pageKey, child: page),
  );
}
