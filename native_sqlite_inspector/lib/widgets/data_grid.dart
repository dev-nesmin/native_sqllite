import 'package:flutter/material.dart';

import '../connect_client.dart';

class DataGrid extends StatelessWidget {
  const DataGrid({
    super.key,
    required this.data,
    required this.schema,
    required this.onDelete,
  });

  final List<Map<String, dynamic>> data;
  final TableSchema schema;
  final Function(Map<String, dynamic> row) onDelete;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No data',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final columns = schema.columns.map((c) => c.name).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 24,
          horizontalMargin: 16,
          columns: [
            ...columns.map((col) => DataColumn(
                  label: Text(
                    col,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                )),
            const DataColumn(label: Text('Actions')),
          ],
          rows: data.map((row) {
            return DataRow(
              cells: [
                ...columns.map((col) {
                  final value = row[col];
                  return DataCell(
                    Text(
                      _formatValue(value),
                      style: TextStyle(
                        color: value == null ? Colors.grey : null,
                        fontStyle: value == null ? FontStyle.italic : null,
                      ),
                    ),
                  );
                }),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        color: Colors.red,
                        onPressed: () => onDelete(row),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'NULL';
    if (value is String) {
      return value.length > 100 ? '${value.substring(0, 100)}...' : value;
    }
    return value.toString();
  }
}
