import 'package:flutter/material.dart';

import '../services/raw_api_demo_service.dart';
import '../widgets/async_view.dart';
import '../widgets/glass_app_bar.dart';

const _apiCoverage = <({String name, String description})>[
  (name: 'getDatabasePath', description: 'Resolve the platform database path'),
  (
    name: 'open',
    description: 'Create an isolated database from generated schemas',
  ),
  (name: 'executeInsert', description: 'Raw parameterized INSERT with row ID'),
  (
    name: 'execute',
    description: 'Raw parameterized statement and affected rows',
  ),
  (name: 'query', description: 'Parameterized SELECT and typed QueryResult'),
  (name: 'insert', description: 'Map-based insert'),
  (name: 'update', description: 'Map-based update with bound WHERE values'),
  (
    name: 'transaction',
    description: 'Atomic callback with a transaction handle',
  ),
  (name: 'batch', description: 'Mixed operations in one platform call'),
  (name: 'delete', description: 'Delete with a bound predicate'),
  (name: 'close', description: 'Release the owned database handle'),
  (name: 'deleteDatabase', description: 'Remove the disposable database'),
  (name: 'UNIQUE', description: 'Typed SQLITE_CONSTRAINT_UNIQUE'),
  (name: 'NOT NULL', description: 'Typed SQLITE_CONSTRAINT_NOTNULL'),
  (name: 'FOREIGN KEY', description: 'Typed SQLITE_CONSTRAINT_FOREIGNKEY'),
  (name: 'syntax error', description: 'Typed SQLITE_ERROR'),
];

/// Complete raw API and typed-error laboratory.
class ManualApiScreen extends StatefulWidget {
  const ManualApiScreen({super.key});

  @override
  State<ManualApiScreen> createState() => _ManualApiScreenState();
}

class _ManualApiScreenState extends State<ManualApiScreen> {
  bool _loading = false;
  bool _hasRun = false;
  Object? _error;
  List<RawApiResult> _results = const [];

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _hasRun = true;
      _error = null;
      _results = const [];
    });
    try {
      final results = await const RawApiDemoService().run();
      if (!mounted) return;
      setState(() => _results = results);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final passed = _results.where((result) => result.passed).length;
    return Scaffold(
      appBar: const GlassAppBar(title: 'Raw API & Errors'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'The entire low-level API, safely isolated',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'The tour creates a disposable database from generated schema '
            'constants. Every value is bound as an argument; the app database '
            'is never modified.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loading ? null : _run,
            icon: _loading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(_loading ? 'Running API tour…' : 'Run full API tour'),
          ),
          const SizedBox(height: 12),
          if (_hasRun && !_loading && _error == null)
            Text(
              '$passed/${_results.length} checks passed.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          const SizedBox(height: 8),
          AsyncView<List<RawApiResult>>(
            value: _hasRun ? _results : null,
            loading: _loading,
            error: _error,
            isEmpty: (results) => results.isEmpty,
            emptyBuilder: (context) => Column(
              children: [
                for (final operation in _apiCoverage)
                  _PendingOperation(operation: operation),
              ],
            ),
            dataBuilder: (context, results) => Column(
              children: [
                for (final result in results) _ResultCard(result: result),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingOperation extends StatelessWidget {
  const _PendingOperation({required this.operation});

  final ({String name, String description}) operation;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.radio_button_unchecked),
        title: Text(operation.name),
        subtitle: Text(operation.description),
        trailing: const Text('Pending'),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final RawApiResult result;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final error = result.error;
    return Card(
      child: ListTile(
        leading: Icon(
          result.passed ? Icons.check_circle : Icons.cancel,
          color: result.passed ? colors.primary : colors.error,
        ),
        title: Text(result.operation),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.detail),
            if (error != null) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  Chip(label: Text('code ${error.resultCode}')),
                  Chip(label: Text('extended ${error.extendedResultCode}')),
                  if (error.isConstraintViolation)
                    const Chip(label: Text('constraint')),
                  if (error.isSyntaxError) const Chip(label: Text('syntax')),
                ],
              ),
              if (error.sql case final sql?) SelectableText('SQL: $sql'),
            ],
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
