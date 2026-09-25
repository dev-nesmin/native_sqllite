// Portions adapted from Isar Community Inspector.
// Copyright 2022 Simon Leier. Licensed under Apache-2.0.
// See the package NOTICE and LICENSES/Apache-2.0.txt files.

import 'dart:convert';

import 'package:flutter/material.dart';

class DataGrid extends StatelessWidget {
  const DataGrid({
    super.key,
    required this.columns,
    required this.rows,
    this.onEdit,
    this.onDelete,
  });

  final List<String> columns;
  final List<List<Object?>> rows;
  final ValueChanged<int>? onEdit;
  final ValueChanged<int>? onDelete;

  bool get _hasActions => onEdit != null || onDelete != null;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: Colors.grey),
            SizedBox(height: 12),
            Text('No rows'),
          ],
        ),
      );
    }

    return Scrollbar(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columnSpacing: 24,
            horizontalMargin: 16,
            columns: [
              for (final column in columns)
                DataColumn(
                  label: Text(
                    column,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              if (_hasActions) const DataColumn(label: Text('Actions')),
            ],
            rows: [
              for (var rowIndex = 0; rowIndex < rows.length; rowIndex++)
                DataRow(
                  cells: [
                    for (
                      var columnIndex = 0;
                      columnIndex < columns.length;
                      columnIndex++
                    )
                      _cell(
                        context,
                        columnIndex < rows[rowIndex].length
                            ? rows[rowIndex][columnIndex]
                            : null,
                      ),
                    if (_hasActions)
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (onEdit != null)
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                onPressed: () => onEdit!(rowIndex),
                                tooltip: 'Edit row',
                              ),
                            if (onDelete != null)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                ),
                                color: Colors.red,
                                onPressed: () => onDelete!(rowIndex),
                                tooltip: 'Delete row',
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  DataCell _cell(BuildContext context, Object? value) {
    return DataCell(
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Text(
          _formatValue(value),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: value == null ? Colors.grey : null,
            fontStyle: value == null ? FontStyle.italic : null,
            fontFamily: value is Map ? 'monospace' : null,
          ),
        ),
      ),
      onTap: () => _showValue(context, value),
    );
  }

  static String _formatValue(Object? value) {
    if (value == null) return 'NULL';
    if (value is Map && value[r'$type'] == 'blob') {
      return 'BLOB (${value['length']} bytes)';
    }
    if (value is Map && value[r'$type'] == 'number') {
      return value['value'].toString();
    }
    return value.toString();
  }

  static Future<void> _showValue(BuildContext context, Object? value) {
    final text = value is Map || value is List
        ? const JsonEncoder.withIndent('  ').convert(value)
        : _formatValue(value);
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cell value'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 480),
          child: SingleChildScrollView(child: SelectableText(text)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
