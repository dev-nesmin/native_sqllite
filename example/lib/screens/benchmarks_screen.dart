import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../generated/database_manager.dart';
import '../services/benchmark_service.dart';
import '../widgets/glass_app_bar.dart';

/// Interactive performance comparison intended for Flutter profile mode.
class BenchmarksScreen extends StatefulWidget {
  const BenchmarksScreen({super.key});

  @override
  State<BenchmarksScreen> createState() => _BenchmarksScreenState();
}

class _BenchmarksScreenState extends State<BenchmarksScreen> {
  BenchmarkReport? _report;
  Object? _error;
  bool _running = false;
  int _rowCount = 500;

  Future<void> _run() async {
    setState(() {
      _running = true;
      _error = null;
    });
    try {
      final report = await BenchmarkService.run(
        DatabaseManager.currentDatabase,
        rowCount: _rowCount,
      );
      if (mounted) setState(() => _report = report);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const GlassAppBar(title: 'SQLite Benchmarks'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!kProfileMode)
            Card(
              color: colors.tertiaryContainer,
              child: const ListTile(
                leading: Icon(Icons.speed),
                title: Text('Run with --profile for meaningful numbers'),
                subtitle: Text(
                  'Debug instrumentation changes timings. The comparisons '
                  'still run here so the workflow can be tested.',
                ),
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Rows: $_rowCount'),
                  Slider(
                    value: _rowCount.toDouble(),
                    min: 100,
                    max: 2000,
                    divisions: 19,
                    label: '$_rowCount',
                    onChanged: _running
                        ? null
                        : (value) => setState(() => _rowCount = value.round()),
                  ),
                  FilledButton.icon(
                    key: const ValueKey('run-benchmarks'),
                    onPressed: _running ? null : _run,
                    icon: _running
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(_running ? 'Running…' : 'Run benchmark'),
                  ),
                ],
              ),
            ),
          ),
          if (_error != null)
            Card(
              color: colors.errorContainer,
              child: ListTile(
                leading: Icon(Icons.error_outline, color: colors.error),
                title: const Text('Benchmark failed'),
                subtitle: Text('$_error'),
              ),
            ),
          if (_report case final report?) ...[
            Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Operation')),
                    DataColumn(label: Text('Elapsed'), numeric: true),
                    DataColumn(label: Text('Query plan')),
                  ],
                  rows: [
                    for (final measurement in report.measurements)
                      DataRow(
                        cells: [
                          DataCell(Text(measurement.label)),
                          DataCell(
                            Text('${measurement.elapsed.inMicroseconds} µs'),
                          ),
                          DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 420),
                              child: SelectableText(measurement.detail ?? '—'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(
                  report.maxFrame > const Duration(milliseconds: 16)
                      ? Icons.warning_amber
                      : Icons.check_circle_outline,
                ),
                title: Text(
                  'Longest observed Flutter frame: '
                  '${report.maxFrame.inMicroseconds / 1000} ms',
                ),
                subtitle: const Text(
                  'SQLite work runs through asynchronous platform queues; '
                  'frame timing stays visible while the workload executes.',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
