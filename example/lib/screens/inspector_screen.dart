import 'package:flutter/material.dart';

import '../widgets/glass_app_bar.dart';

class InspectorScreen extends StatelessWidget {
  const InspectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const GlassAppBar(title: 'Database Inspector'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: colors.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.developer_mode,
                    size: 48,
                    color: colors.onPrimaryContainer,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Open DevTools → native_sqlite',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The extension uses the existing DevTools connection. '
                    'There is no hosted inspector URL or token to copy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.onPrimaryContainer),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _Step(
            number: 1,
            title: 'Start this app in debug mode',
            body:
                'The inspector is intentionally absent from profile and release builds. '
                'Keep the database open while inspecting it.',
          ),
          const _Step(
            number: 2,
            title: 'Open Flutter DevTools',
            body:
                'Use the VS Code command palette, the Android Studio/IntelliJ '
                'tool window, or the DevTools browser link. Emulators, physical '
                'devices, and Flutter web use the same DDS connection.',
          ),
          const _Step(
            number: 3,
            title: 'Enable the extension',
            body:
                'Open the Extensions menu, trust and enable native_sqlite, then '
                'select its tab. It follows hot restarts automatically.',
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Project-wide preference',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add devtools_options.yaml at the app root if every '
                    'contributor should start with the extension enabled:',
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const SelectableText(
                      'extensions:\n  - native_sqlite: true',
                      style: TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(Icons.security, color: colors.error),
              title: const Text('Debug access is privileged'),
              subtitle: const Text(
                'DevTools can inspect and control the running app. Database '
                'data stays on the local DevTools connection, but you should '
                'enable extensions only from packages you trust. Disable this '
                'one with --dart-define=NATIVE_SQLITE_INSPECTOR=false.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.title, required this.body});

  final int number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: colors.secondaryContainer,
              foregroundColor: colors.onSecondaryContainer,
              child: Text('$number'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
