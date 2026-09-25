import 'package:flutter/scheduler.dart';
import 'package:native_sqlite/native_sqlite.dart';

/// One measured operation shown by the benchmark screen.
final class BenchmarkMeasurement {
  const BenchmarkMeasurement(this.label, this.elapsed, {this.detail});

  final String label;
  final Duration elapsed;
  final String? detail;
}

/// Results from one repeatable benchmark run.
final class BenchmarkReport {
  const BenchmarkReport({required this.measurements, required this.maxFrame});

  final List<BenchmarkMeasurement> measurements;
  final Duration maxFrame;
}

/// Runs small comparative SQLite workloads used by the profile-mode demo.
abstract final class BenchmarkService {
  static const _table = 'benchmark_rows';

  /// Compares individual writes, a transaction, a platform batch, and indexed
  /// versus unindexed lookup while collecting Flutter frame timings.
  static Future<BenchmarkReport> run(
    NativeSqliteDatabase database, {
    int rowCount = 500,
  }) async {
    if (rowCount < 1 || rowCount > 10000) {
      throw RangeError.range(rowCount, 1, 10000, 'rowCount');
    }

    final frames = <FrameTiming>[];
    void collect(List<FrameTiming> timings) => frames.addAll(timings);
    SchedulerBinding.instance.addTimingsCallback(collect);
    try {
      await database.execute('DROP TABLE IF EXISTS $_table');
      await database.execute(
        'CREATE TABLE $_table ('
        'id INTEGER PRIMARY KEY, lookup_value INTEGER NOT NULL, '
        'payload TEXT NOT NULL)',
      );

      final measurements = <BenchmarkMeasurement>[];
      measurements.add(
        await _measure('Loop: $rowCount inserts', () async {
          for (var index = 0; index < rowCount; index++) {
            await database.insert(_table, {
              'lookup_value': index % 100,
              'payload': 'loop-$index',
            });
          }
        }),
      );

      await database.execute('DELETE FROM $_table');
      measurements.add(
        await _measure('One transaction', () async {
          await database.transaction((transaction) async {
            for (var index = 0; index < rowCount; index++) {
              await transaction.insert(_table, {
                'lookup_value': index % 100,
                'payload': 'transaction-$index',
              });
            }
          });
        }),
      );

      await database.execute('DELETE FROM $_table');
      measurements.add(
        await _measure('Native platform batch', () async {
          final batch = database.batch();
          for (var index = 0; index < rowCount; index++) {
            batch.insert(_table, {
              'lookup_value': index % 100,
              'payload': 'batch-$index',
            });
          }
          await batch.commit();
        }),
      );

      measurements.add(
        await _queryMeasurement(database, 'Query without index'),
      );
      await database.execute(
        'CREATE INDEX benchmark_lookup_idx ON $_table (lookup_value)',
      );
      measurements.add(await _queryMeasurement(database, 'Query with index'));

      return BenchmarkReport(
        measurements: measurements,
        maxFrame: frames.fold(
          Duration.zero,
          (maximum, frame) =>
              frame.totalSpan > maximum ? frame.totalSpan : maximum,
        ),
      );
    } finally {
      SchedulerBinding.instance.removeTimingsCallback(collect);
    }
  }

  static Future<BenchmarkMeasurement> _queryMeasurement(
    NativeSqliteDatabase database,
    String label,
  ) async {
    final plan = await database.query(
      'EXPLAIN QUERY PLAN SELECT * FROM $_table WHERE lookup_value = ?',
      [42],
    );
    return _measure(label, () async {
      await database.query('SELECT * FROM $_table WHERE lookup_value = ?', [
        42,
      ]);
    }, detail: plan.rows.map((row) => row.last).join('\n'));
  }

  static Future<BenchmarkMeasurement> _measure(
    String label,
    Future<void> Function() action, {
    String? detail,
  }) async {
    final stopwatch = Stopwatch()..start();
    await action();
    stopwatch.stop();
    return BenchmarkMeasurement(label, stopwatch.elapsed, detail: detail);
  }
}
