// Portions adapted from Isar Community Inspector.
// Copyright 2022 Simon Leier. Licensed under Apache-2.0.
// See the package NOTICE and LICENSES/Apache-2.0.txt files.

import 'package:flutter/material.dart';

typedef ExecuteSql = Future<void> Function(String sql, bool allowWrite);

class QueryBuilder extends StatefulWidget {
  const QueryBuilder({super.key, required this.table, required this.onExecute});

  final String table;
  final ExecuteSql onExecute;

  @override
  State<QueryBuilder> createState() => _QueryBuilderState();
}

class _QueryBuilderState extends State<QueryBuilder> {
  final _controller = TextEditingController();
  bool _allowWrite = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.code, size: 20),
                const SizedBox(width: 8),
                Text(
                  'SQL console',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Tooltip(
                  message: 'Permit statements that may modify the database',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Allow writes'),
                      Switch(
                        value: _allowWrite,
                        onChanged: (value) =>
                            setState(() => _allowWrite = value),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLines: 3,
              style: const TextStyle(fontFamily: 'monospace'),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'SELECT * FROM "${widget.table}"',
                filled: true,
              ),
              onSubmitted: (_) => _execute(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _execute,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Execute'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _controller.clear,
                  child: const Text('Clear'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    final escaped = widget.table.replaceAll('"', '""');
                    _controller.text = 'SELECT * FROM "$escaped"';
                  },
                  child: const Text('Select all'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _execute() async {
    final sql = _controller.text.trim();
    if (sql.isNotEmpty) await widget.onExecute(sql, _allowWrite);
  }
}
