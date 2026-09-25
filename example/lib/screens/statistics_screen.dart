import 'dart:async';

import 'package:flutter/material.dart';

import '../generated/database_manager.dart';
import '../services/database_maintenance_service.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/ui_feedback.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Map<String, int> _counts = const {};
  List<Map<String, Object?>> _schema = const [];
  String _path = '';
  String _sqliteVersion = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final database = DatabaseManager.currentDatabase;
      final counts = <String, int>{};
      for (final table in DatabaseManager.tableNames) {
        final result = await database.query(
          'SELECT COUNT(*) AS count FROM "$table"',
        );
        counts[table] = result.toMapList().single['count'] as int;
      }
      final schema = await database.query(
        "SELECT name, sql FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%' ORDER BY name",
      );
      final version = await database.query(
        'SELECT sqlite_version() AS sqlite_version',
      );
      if (!mounted) return;
      setState(() {
        _counts = counts;
        _schema = schema.toMapList();
        _path = database.path;
        _sqliteVersion = version.toMapList().single['sqlite_version'] as String;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      UiFeedback.showMessage(context, error.toString(), error: true);
    }
  }

  Future<void> _generateSamples() async {
    setState(() => _loading = true);
    try {
      final inserted = await DatabaseMaintenanceService(
        DatabaseManager.currentDatabase,
      ).generateSampleData();
      if (!mounted) return;
      UiFeedback.showMessage(
        context,
        'Committed ${inserted.values.fold(0, (sum, value) => sum + value)} '
        'rows across ${inserted.length} tables.',
      );
      await _load();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      UiFeedback.showMessage(context, error.toString(), error: true);
    }
  }

  Future<void> _reset() async {
    final confirmed = await UiFeedback.confirm(
      context,
      title: 'Reset database?',
      message:
          'The current database file will be closed and deleted, then a fresh '
          'schema will be created. All rows will be lost.',
      confirmLabel: 'Reset database',
    );
    if (!confirmed || !mounted) return;

    setState(() => _loading = true);
    try {
      await DatabaseMaintenanceService.resetDatabase();
      if (!mounted) return;
      UiFeedback.showMessage(context, 'Fresh database created.');
      await _load();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      UiFeedback.showMessage(context, error.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlassAppBar(
        title: 'Database Statistics',
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _databaseCard(context),
                const SizedBox(height: 16),
                Text(
                  'Every generated table',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth >= 700
                        ? (constraints.maxWidth - 24) / 3
                        : (constraints.maxWidth - 8) / 2;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final table in DatabaseManager.tableNames)
                          SizedBox(
                            width: width,
                            child: _CountCard(
                              table: table,
                              count: _counts[table] ?? 0,
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _generateSamples,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Generate sample data in one transaction'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reset database'),
                ),
                const SizedBox(height: 16),
                _schemaCard(context),
              ],
            ),
    );
  }

  Widget _databaseCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generated database',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Name: ${DatabaseManager.currentDatabaseName}'),
            Text('Schema version: ${DatabaseManager.schemaVersion}'),
            Text('SQLite engine: $_sqliteVersion'),
            SelectableText('Path: $_path'),
          ],
        ),
      ),
    );
  }

  Widget _schemaCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SQLite schema',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            for (final table in _schema)
              ExpansionTile(
                title: Text(table['name'] as String),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(
                      table['sql'] as String? ?? 'Schema unavailable',
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({required this.table, required this.count});

  final String table;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text('$count', style: Theme.of(context).textTheme.headlineMedium),
            Text(table, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
