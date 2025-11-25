import 'package:flutter/material.dart';

import '../connect_client.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.databases,
    required this.selectedDatabase,
    required this.onDatabaseSelected,
    required this.tables,
    required this.selectedTable,
    required this.onTableSelected,
    this.databaseInfo,
  });

  final List<String> databases;
  final String selectedDatabase;
  final void Function(String database) onDatabaseSelected;

  final List<String> tables;
  final String? selectedTable;
  final void Function(String table) onTableSelected;

  final DatabaseInfo? databaseInfo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Database selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Database',
                  style: theme.textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: selectedDatabase,
                  isExpanded: true,
                  items: databases.map((db) {
                    return DropdownMenuItem(
                      value: db,
                      child: Row(
                        children: [
                          const Icon(Icons.storage, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              db,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      onDatabaseSelected(value);
                    }
                  },
                ),
                if (databaseInfo != null) ...[
                  const SizedBox(height: 16),
                  _InfoRow(
                    label: 'Tables',
                    value: '${databaseInfo!.tables.length}',
                  ),
                  if (databaseInfo!.size != null)
                    _InfoRow(
                      label: 'Size',
                      value: _formatBytes(databaseInfo!.size!),
                    ),
                ],
              ],
            ),
          ),
          // Tables list
          Expanded(
            child: ListView.builder(
              itemCount: tables.length,
              itemBuilder: (context, index) {
                final table = tables[index];
                final isSelected = table == selectedTable;

                return ListTile(
                  selected: isSelected,
                  dense: true,
                  leading: const Icon(Icons.table_chart, size: 18),
                  title: Text(table),
                  onTap: () => onTableSelected(table),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
