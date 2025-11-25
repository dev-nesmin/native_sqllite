import 'package:logging/logging.dart';

final logger = Logger('NativeSqliteGenerator');

/// Configures the logger for the generator.
///
/// [verbose] - If true, enables verbose logging (ALL levels).
/// [quiet] - If true, disables all console output (OFF).
void setupLogger({bool verbose = false, bool quiet = false}) {
  if (quiet) {
    Logger.root.level = Level.OFF;
    return;
  }

  Logger.root.level = verbose ? Level.ALL : Level.INFO;

  Logger.root.onRecord.listen((record) {
    if (record.level >= Level.SEVERE) {
      print('❌ ${record.message}');
      if (record.error != null) print(record.error);
      if (record.stackTrace != null) print(record.stackTrace);
    } else if (record.level >= Level.WARNING) {
      print('⚠️  ${record.message}');
    } else if (record.level >= Level.INFO) {
      print(record.message);
    } else {
      print('[${record.level.name}] ${record.message}');
    }
  });
}
