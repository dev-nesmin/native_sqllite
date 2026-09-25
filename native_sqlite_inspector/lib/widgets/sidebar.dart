// Portions adapted from Isar Community Inspector.
// Copyright 2022 Simon Leier. Licensed under Apache-2.0.
// See the package NOTICE and LICENSES/Apache-2.0.txt files.

import 'package:flutter/material.dart';
import 'package:native_sqlite/inspector_protocol.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.databases,
    required this.selectedDatabase,
    required this.onDatabaseSelected,
    required this.selectedTable,
    required this.onTableSelected,
  });

  final List<InspectorDatabaseInfo> databases;
  final String? selectedDatabase;
  final ValueChanged<String> onDatabaseSelected;
  final String? selectedTable;
  final ValueChanged<String> onTableSelected;

  @override
  Widget build(BuildContext context) {
    final database = databases
        .where((candidate) => candidate.name == selectedDatabase)
        .firstOrNull;
    return Card(
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Database', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 8),
                if (databases.isEmpty)
                  const Text('None')
                else
                  DropdownButton<String>(
                    value: selectedDatabase,
                    isExpanded: true,
                    items: databases
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.name,
                            child: Row(
                              children: [
                                const Icon(Icons.storage, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) onDatabaseSelected(value);
                    },
                  ),
                if (database != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    database.path,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Objects',
                    value: '${database.tables.length}',
                  ),
                  _InfoRow(label: 'Size', value: _formatBytes(database.size)),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Tables and views',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final table
                    in database?.tables ?? const <InspectorTableSchema>[])
                  ListTile(
                    selected: table.name == selectedTable,
                    dense: true,
                    leading: Icon(
                      table.isView
                          ? Icons.visibility_outlined
                          : Icons.table_chart,
                      size: 18,
                    ),
                    title: Text(table.name),
                    subtitle: table.isView ? const Text('view') : null,
                    onTap: () => onTableSelected(table.name),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
