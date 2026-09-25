import 'dart:async';

import 'package:flutter/material.dart';

import '../generated/database_manager.dart';
import '../services/web_persistence_service.dart';
import '../services/web_tab_guard.dart';
import '../widgets/glass_app_bar.dart';

/// Demonstrates IndexedDB-backed SQLite persistence across browser reloads.
class WebPersistenceScreen extends StatefulWidget {
  const WebPersistenceScreen({super.key});

  @override
  State<WebPersistenceScreen> createState() => _WebPersistenceScreenState();
}

class _WebPersistenceScreenState extends State<WebPersistenceScreen> {
  final WebTabGuard _tabGuard = WebTabGuard();
  StreamSubscription<bool>? _tabSubscription;
  late Future<int> _launchCount;
  bool _anotherTabIsOpen = false;

  @override
  void initState() {
    super.initState();
    _launchCount = WebPersistenceService.readLaunchCount(
      DatabaseManager.currentDatabase,
    );
    _tabGuard.start();
    _anotherTabIsOpen = _tabGuard.anotherTabIsOpen;
    _tabSubscription = _tabGuard.changes.listen((isOpen) {
      if (mounted) setState(() => _anotherTabIsOpen = isOpen);
    });
  }

  @override
  void dispose() {
    unawaited(_tabSubscription?.cancel());
    _tabGuard.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const GlassAppBar(title: 'Web Persistence'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_anotherTabIsOpen)
            Card(
              color: colors.errorContainer,
              child: ListTile(
                leading: Icon(Icons.warning_amber, color: colors.error),
                title: const Text('Another tab is open'),
                subtitle: const Text(
                  'native_sqlite web currently supports one active tab per '
                  'database. Close the other tab before writing here.',
                ),
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: FutureBuilder<int>(
                future: _launchCount,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text(
                      'Could not read launch count: ${snapshot.error}',
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return Column(
                    children: [
                      Icon(Icons.public, size: 56, color: colors.primary),
                      const SizedBox(height: 16),
                      Text(
                        '${snapshot.data}',
                        key: const ValueKey('web-launch-count'),
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const Text('browser launches stored in SQLite'),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _tabGuard.reloadPage,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reload page'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.storage),
              title: Text('Persistence path'),
              subtitle: Text(
                'SQLite runs in WebAssembly and flushes the database file to '
                'IndexedDB. Reloading recreates Dart state, not the database.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
