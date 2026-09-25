import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../generated/database_manager.dart';
import '../models/sync_event.dart';
import '../widgets/async_view.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/ui_feedback.dart';

class BackgroundSyncScreen extends StatefulWidget {
  const BackgroundSyncScreen({super.key});

  @override
  State<BackgroundSyncScreen> createState() => _BackgroundSyncScreenState();
}

class _BackgroundSyncScreenState extends State<BackgroundSyncScreen> {
  static const _native = MethodChannel(
    'com.example.native_sqlite_example/native',
  );

  late final AppLifecycleListener _lifecycle;
  List<SyncEvent> _events = const [];
  bool _loading = true;
  Object? _error;

  bool get _supportsNativeTasks =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(_load()));
    unawaited(_load());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final events = await SyncEventQueryBuilder(
        DatabaseManager.currentDatabase,
      ).sortByCreatedAtDesc().limit(100).findAll();
      if (!mounted) return;
      setState(() {
        _events = events;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _schedule() async {
    await _invokeNative('scheduleBackgroundSync', 'Periodic work scheduled.');
  }

  Future<void> _enqueue() async {
    await _invokeNative(
      'enqueueBackgroundSyncNow',
      'A one-time background task was submitted.',
    );
  }

  Future<void> _runNow() async {
    await _invokeNative(
      'runBackgroundSyncNow',
      'The native task body inserted a row.',
      refresh: true,
    );
  }

  Future<void> _addDartRow() async {
    await SyncEventRepository(DatabaseManager.currentDatabase).insert(
      SyncEvent(source: 'dart-ui', message: 'Foreground comparison row'),
    );
    await _load();
  }

  Future<void> _invokeNative(
    String method,
    String success, {
    bool refresh = false,
  }) async {
    setState(() => _loading = true);
    try {
      await _native.invokeMethod<Object?>(method);
      if (!mounted) return;
      UiFeedback.showMessage(context, success);
      if (refresh) {
        await _load();
      } else {
        setState(() => _loading = false);
      }
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
        title: 'Background Sync',
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            tooltip: 'Refresh rows',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Native writes while Flutter is away',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _supportsNativeTasks
                ? 'Android uses WorkManager; iOS uses BackgroundTasks. This '
                      'screen reloads the shared table whenever the app resumes.'
                : 'Platform-native schedulers are available in the Android and '
                      'iOS builds. Web can still inspect rows written by Dart.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _supportsNativeTasks && !_loading ? _schedule : null,
                icon: const Icon(Icons.schedule),
                label: const Text('Schedule periodic'),
              ),
              OutlinedButton.icon(
                onPressed: _supportsNativeTasks && !_loading ? _enqueue : null,
                icon: const Icon(Icons.queue),
                label: const Text('Submit run now'),
              ),
              OutlinedButton.icon(
                onPressed: _supportsNativeTasks && !_loading ? _runNow : null,
                icon: const Icon(Icons.bug_report_outlined),
                label: const Text('Run task body now'),
              ),
              TextButton.icon(
                onPressed: _loading ? null : _addDartRow,
                icon: const Icon(Icons.flutter_dash),
                label: const Text('Add Dart row'),
              ),
            ],
          ),
          if (defaultTargetPlatform == TargetPlatform.iOS && !kIsWeb) ...[
            const SizedBox(height: 12),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: SelectableText(
                  'Real-device LLDB simulation:\n'
                  'e -l objc -- (void)[[BGTaskScheduler sharedScheduler] '
                  '_simulateLaunchForTaskWithIdentifier:'
                  '@"dev.nesmin.native-sqlite-example.refresh"]',
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Shared sync_events rows',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 420,
            child: AsyncView<List<SyncEvent>>(
              value: _events,
              loading: _loading,
              error: _error,
              onRetry: _load,
              isEmpty: (events) => events.isEmpty,
              emptyBuilder: (context) =>
                  const Center(child: Text('No sync events yet.')),
              dataBuilder: (context, events) => ListView.separated(
                itemCount: events.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final event = events[index];
                  final native = event.source == 'native-worker';
                  return ListTile(
                    tileColor: native
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    leading: Icon(native ? Icons.memory : Icons.flutter_dash),
                    title: Text(event.message),
                    subtitle: Text(
                      '${event.source} · ${event.createdAt.toLocal()}',
                    ),
                    trailing: native ? const Text('NATIVE') : null,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
