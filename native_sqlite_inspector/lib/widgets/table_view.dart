import 'dart:convert';

import 'package:flutter/material.dart';

import '../connect_client.dart';
import 'data_grid.dart';
import 'query_builder.dart';

class TableView extends StatefulWidget {
  const TableView({
    super.key,
    required this.database,
    required this.table,
    required this.client,
    required this.schema,
  });

  final String database;
  final String table;
  final ConnectClient client;
  final TableSchema schema;

  @override
  State<TableView> createState() => _TableViewState();
}

class _TableViewState extends State<TableView> {
  List<Map<String, dynamic>> _data = [];
  int _totalCount = 0;
  bool _loading = false;
  String? _error;
  int _offset = 0;
  final int _limit = 50;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await widget.client.executeQuery({
        'database': widget.database,
        'table': widget.table,
        'limit': _limit,
        'offset': _offset,
      });

      setState(() {
        _data = List<Map<String, dynamic>>.from(result['objects'] as List);
        _totalCount = result['count'] as int;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _executeSql(String sql) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await widget.client.executeSql(
        widget.database,
        sql,
      );

      setState(() {
        _data = result;
        _totalCount = result.length;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _deleteRecord(Map<String, dynamic> row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.client.deleteRecord(
          widget.database,
          widget.table,
          row[widget.schema.primaryKey ?? 'id'],
        );
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _exportJson() async {
    try {
      final data = await widget.client.exportJson({
        'database': widget.database,
        'table': widget.table,
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export JSON'),
            content: SingleChildScrollView(
              child: SelectableText(
                const JsonEncoder.withIndent('  ').convert(data),
              ),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.table_chart, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.table,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                'Total: $_totalCount records',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadData,
                tooltip: 'Refresh',
              ),
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: _exportJson,
                tooltip: 'Export JSON',
              ),
            ],
          ),
        ),
        // Data grid
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Error',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(_error!),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : DataGrid(
                      data: _data,
                      schema: widget.schema,
                      onDelete: _deleteRecord,
                    ),
        ),
        // Pagination
        if (_totalCount > _limit)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _offset > 0
                      ? () {
                          setState(() {
                            _offset = (_offset - _limit).clamp(0, _totalCount);
                          });
                          _loadData();
                        }
                      : null,
                ),
                Text(
                  'Showing ${_offset + 1}-${(_offset + _limit).clamp(0, _totalCount)} of $_totalCount',
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _offset + _limit < _totalCount
                      ? () {
                          setState(() {
                            _offset += _limit;
                          });
                          _loadData();
                        }
                      : null,
                ),
              ],
            ),
          ),
        // Query builder
        QueryBuilder(
          database: widget.database,
          table: widget.table,
          onExecute: _executeSql,
        ),
      ],
    );
  }
}
