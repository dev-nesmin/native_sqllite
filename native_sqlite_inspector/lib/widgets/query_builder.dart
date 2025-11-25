import 'package:flutter/material.dart';

class QueryBuilder extends StatefulWidget {
  const QueryBuilder({
    super.key,
    required this.database,
    required this.table,
    required this.onExecute,
  });

  final String database;
  final String table;
  final Function(String sql) onExecute;

  @override
  State<QueryBuilder> createState() => _QueryBuilderState();
}

class _QueryBuilderState extends State<QueryBuilder> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.code, size: 20),
                const SizedBox(width: 8),
                Text(
                  'SQL Query',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 3,
              style: const TextStyle(fontFamily: 'monospace'),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'SELECT * FROM ${widget.table}',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    final sql = _controller.text.trim();
                    if (sql.isNotEmpty) {
                      widget.onExecute(sql);
                    }
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Execute'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    _controller.clear();
                  },
                  child: const Text('Clear'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    _controller.text = 'SELECT * FROM ${widget.table}';
                  },
                  child: const Text('Select All'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
