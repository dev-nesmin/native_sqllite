import 'package:flutter/material.dart';

import '../generated/database_manager.dart';
import '../services/model_gallery_service.dart';
import '../widgets/glass_app_bar.dart';

const _models = <({String name, String features})>[
  (name: 'User', features: 'defaults, nullability, bool, DateTime, @Ignore'),
  (name: 'Category', features: 'UNIQUE text'),
  (name: 'Product', features: 'foreign key, REAL, composite indexes'),
  (name: 'Order', features: 'two foreign keys, enum name storage'),
  (name: 'Profile', features: 'JSON maps, lists, objects, dynamic values'),
  (name: 'AdvancedUser', features: 'Duration, Uri, num, both enum codecs'),
  (name: 'FreezedAdvancedUser', features: 'Freezed and shared enums'),
  (name: 'StyledItem', features: 'Color converter and JSON list'),
  (name: 'Note', features: 'local UUID primary key'),
  (name: 'Attachment', features: 'Uint8List BLOB'),
  (name: 'Tag', features: 'renamed column and named UNIQUE @Index'),
  (name: 'Comment', features: 'self FK with ON DELETE SET NULL'),
  (name: 'SyncEvent', features: 'shared native background task row'),
];

/// Saves and reads every generated model against the shared app database.
class ModelGalleryScreen extends StatefulWidget {
  const ModelGalleryScreen({super.key});

  @override
  State<ModelGalleryScreen> createState() => _ModelGalleryScreenState();
}

class _ModelGalleryScreenState extends State<ModelGalleryScreen> {
  bool _running = false;
  List<ModelGalleryResult> _results = const [];

  Future<void> _run() async {
    setState(() {
      _running = true;
      _results = const [];
    });
    final results = await ModelGalleryService(
      DatabaseManager.currentDatabase,
    ).runAll();
    if (!mounted) return;
    setState(() {
      _running = false;
      _results = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    final passed = _results.where((result) => result.passed).length;
    return Scaffold(
      appBar: const GlassAppBar(title: 'Model Gallery'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Every supported shape, one shared database',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Run the gallery to insert a sample for every generated model, '
            'read it back, and compare its stored values.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _running ? null : _run,
            icon: _running
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(_running ? 'Running round-trips…' : 'Run all models'),
          ),
          const SizedBox(height: 12),
          if (_results.isEmpty)
            const Text('Not run yet — the rows below are the coverage plan.')
          else
            Text(
              '$passed/${_results.length} model round-trips passed.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          const SizedBox(height: 12),
          for (final model in _models)
            _ModelCard(
              name: model.name,
              features: model.features,
              result: _resultFor(model.name),
              running: _running,
            ),
        ],
      ),
    );
  }

  ModelGalleryResult? _resultFor(String model) {
    for (final result in _results) {
      if (result.model == model) return result;
    }
    return null;
  }
}

class _ModelCard extends StatelessWidget {
  const _ModelCard({
    required this.name,
    required this.features,
    required this.result,
    required this.running,
  });

  final String name;
  final String features;
  final ModelGalleryResult? result;
  final bool running;

  @override
  Widget build(BuildContext context) {
    final current = result;
    final colors = Theme.of(context).colorScheme;
    final icon = current == null
        ? Icons.radio_button_unchecked
        : current.passed
        ? Icons.check_circle
        : Icons.cancel;
    final color = current == null
        ? colors.onSurfaceVariant
        : current.passed
        ? colors.primary
        : colors.error;

    return Card(
      child: ListTile(
        leading: running && current == null
            ? const CircularProgressIndicator()
            : Icon(icon, color: color),
        title: Text(name),
        subtitle: Text(
          current == null ? features : '$features\n${current.detail}',
        ),
        isThreeLine: current != null,
        trailing: current == null
            ? const Text('Pending')
            : Text(current.passed ? '✓' : '✗'),
      ),
    );
  }
}
