// Portions adapted from Isar Community Inspector.
// Copyright 2022 Simon Leier. Licensed under Apache-2.0.
// See the package NOTICE and LICENSES/Apache-2.0.txt files.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:native_sqlite/inspector_protocol.dart';

import '../connect_client.dart';
import 'data_grid.dart';
import 'query_builder.dart';

class TableView extends StatefulWidget {
  const TableView({
    super.key,
    required this.database,
    required this.table,
    required this.client,
  });

  final String database;
  final InspectorTableSchema table;
  final ConnectClient client;

  @override
  State<TableView> createState() => _TableViewState();
}

class _TableViewState extends State<TableView> {
  static const _limit = 50;

  InspectorQueryPage? _page;
  InspectorSqlResult? _sqlResult;
  StreamSubscription<void>? _dataSubscription;
  StreamSubscription<void>? _connectionSubscription;
  Timer? _pollTimer;
  int? _dataVersion;
  int _offset = 0;
  bool _loading = false;
  String? _error;
  String? _connectionWarning;

  @override
  void initState() {
    super.initState();
    _dataSubscription = widget.client.dataChanged.listen((_) {
      if (_sqlResult == null) unawaited(_loadPage());
    });
    _connectionSubscription = widget.client.connectionChanged.listen((_) {
      if (mounted) {
        setState(() => _connectionWarning = 'The app restarted. Reconnecting…');
      }
      unawaited(_loadPage());
    });
    _pollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => unawaited(_pollDataVersion()),
    );
    unawaited(_loadPage());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    unawaited(_dataSubscription?.cancel());
    unawaited(_connectionSubscription?.cancel());
    super.dispose();
  }

  Future<void> _pollDataVersion() async {
    try {
      final version = await widget.client.getDataVersion(widget.database);
      if (!mounted) return;
      final changed = _dataVersion != null && version != _dataVersion;
      _dataVersion = version;
      if (changed && _sqlResult == null) await _loadPage();
      if (_connectionWarning != null) {
        setState(() => _connectionWarning = null);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _connectionWarning = 'Live refresh paused: $error');
      }
    }
  }

  Future<void> _loadPage({bool clearSqlResult = false}) async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
        if (clearSqlResult) _sqlResult = null;
      });
    }
    try {
      final page = await widget.client.executeQuery(
        InspectorBrowseRequest(
          database: widget.database,
          table: widget.table.name,
          limit: _limit,
          offset: _offset,
        ),
      );
      if (!mounted) return;
      setState(() {
        _page = page;
        _loading = false;
        _connectionWarning = null;
      });
      unawaited(_pollDataVersion());
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _executeSql(String sql, bool allowWrite) async {
    if (allowWrite && _isDestructive(sql)) {
      final confirmed = await _confirm(
        title: 'Run destructive SQL?',
        message:
            'This statement can remove or restructure data. This cannot be undone.',
        action: 'Execute',
      );
      if (!confirmed) return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.client.executeSql(
        InspectorSqlRequest(
          database: widget.database,
          sql: sql,
          allowWrite: allowWrite,
        ),
      );
      if (!mounted) return;
      setState(() {
        _sqlResult = result;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _deleteRow(int index) async {
    final identity = _page?.identities[index];
    if (identity == null) return;
    final confirmed = await _confirm(
      title: 'Delete row?',
      message: 'Exactly one matching row will be deleted in a transaction.',
      action: 'Delete',
    );
    if (!confirmed) return;
    try {
      await widget.client.deleteRecord(
        InspectorMutationRequest(
          database: widget.database,
          table: widget.table.name,
          identity: identity,
        ),
      );
      await _loadPage();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _editRow(int index) async {
    final page = _page;
    final identity = page?.identities[index];
    if (page == null || identity == null) return;
    final row = page.rows[index];
    final controllers = <String, TextEditingController>{};
    final initial = <String, String>{};
    for (
      var columnIndex = 0;
      columnIndex < page.columns.length;
      columnIndex++
    ) {
      final name = page.columns[columnIndex];
      final value = columnIndex < row.length ? row[columnIndex] : null;
      if (value is Map && value[r'$type'] == 'blob') continue;
      final text = value?.toString() ?? '';
      controllers[name] = TextEditingController(text: text);
      initial[name] = text;
    }
    final values = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit row'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final entry in controllers.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: entry.value,
                      decoration: InputDecoration(
                        labelText: entry.key,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final changed = <String, Object?>{};
              for (final entry in controllers.entries) {
                if (entry.value.text == initial[entry.key]) continue;
                changed[entry.key] = _parseValue(entry.key, entry.value.text);
              }
              Navigator.of(context).pop(changed);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    for (final controller in controllers.values) {
      controller.dispose();
    }
    if (values == null || values.isEmpty) return;
    try {
      await widget.client.updateRecord(
        InspectorMutationRequest(
          database: widget.database,
          table: widget.table.name,
          identity: identity,
          values: values,
        ),
      );
      await _loadPage();
    } catch (error) {
      _showError(error);
    }
  }

  Object _parseValue(String columnName, String value) {
    final type = widget.table.columns
        .where((column) => column.name == columnName)
        .firstOrNull
        ?.type
        .toUpperCase();
    if (type?.contains('INT') ?? false) return int.tryParse(value) ?? value;
    if (type?.contains('REAL') == true ||
        type?.contains('FLOA') == true ||
        type?.contains('DOUB') == true) {
      return double.tryParse(value) ?? value;
    }
    return value;
  }

  Future<void> _exportJson() async {
    try {
      final rows = <List<Object?>>[];
      List<String> columns = const [];
      var offset = 0;
      var total = 0;
      do {
        final page = await widget.client.executeQuery(
          InspectorBrowseRequest(
            database: widget.database,
            table: widget.table.name,
            limit: 500,
            offset: offset,
          ),
        );
        columns = page.columns;
        rows.addAll(page.rows);
        total = page.count;
        offset += page.rows.length;
      } while (offset < total && rows.length < total);
      final objects = [
        for (final row in rows)
          {
            for (var index = 0; index < columns.length; index++)
              columns[index]: index < row.length ? row[index] : null,
          },
      ];
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Export ${widget.table.name} as JSON'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 560),
            child: SingleChildScrollView(
              child: SelectableText(
                const JsonEncoder.withIndent('  ').convert(objects),
              ),
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
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _showSchema() {
    final table = widget.table;
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${table.name} schema'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 560),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final column in table.columns)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(column.name),
                    subtitle: Text(
                      [
                        column.type.isEmpty ? 'untyped' : column.type,
                        column.nullable ? 'nullable' : 'not null',
                        if (column.primaryKeyPosition > 0)
                          'primary key ${column.primaryKeyPosition}',
                        if (column.defaultValue != null)
                          'default ${column.defaultValue}',
                      ].join(' · '),
                    ),
                  ),
                const Divider(),
                Text('Indexes', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Text(table.indexes.isEmpty ? 'None' : table.indexes.join('\n')),
              ],
            ),
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

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(action),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.toString())));
  }

  static bool _isDestructive(String sql) {
    final normalized = sql
        .replaceFirst(RegExp(r'^(?:\s|--[^\n]*(?:\n|$)|/\*[\s\S]*?\*/)*'), '')
        .toUpperCase();
    return RegExp(
      r'^(DELETE|DROP|ALTER|REPLACE|VACUUM)\b',
    ).hasMatch(normalized);
  }

  @override
  Widget build(BuildContext context) {
    final sql = _sqlResult;
    final page = _page;
    final columns = sql?.columns ?? page?.columns ?? const <String>[];
    final rows = sql?.rows ?? page?.rows ?? const <List<Object?>>[];
    final canEdit = sql == null && !widget.table.isView;
    return Column(
      children: [
        if (_connectionWarning != null)
          MaterialBanner(
            content: Text(_connectionWarning!),
            actions: [
              TextButton(onPressed: _loadPage, child: const Text('Retry')),
            ],
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Icon(
                widget.table.isView
                    ? Icons.visibility_outlined
                    : Icons.table_chart,
              ),
              const SizedBox(width: 8),
              Text(
                widget.table.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (widget.table.isView) ...[
                const SizedBox(width: 8),
                const Chip(label: Text('view')),
              ],
              const Spacer(),
              IconButton(
                onPressed: _showSchema,
                icon: const Icon(Icons.schema_outlined),
                tooltip: 'View schema',
              ),
              if (sql != null) ...[
                Text(
                  sql.readOnly
                      ? '${sql.rows.length} result rows${sql.truncated ? ' (truncated)' : ''}'
                      : '${sql.affectedRows} rows changed${sql.truncated ? '; result truncated' : ''}',
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _loadPage(clearSqlResult: true),
                  icon: const Icon(Icons.table_rows),
                  label: const Text('Back to table'),
                ),
              ] else ...[
                Text('${page?.count ?? 0} rows'),
                IconButton(
                  onPressed: () => _loadPage(clearSqlResult: true),
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
                IconButton(
                  onPressed: _exportJson,
                  icon: const Icon(Icons.download_outlined),
                  tooltip: 'Export JSON',
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _ErrorView(error: _error!, retry: _loadPage)
              : DataGrid(
                  columns: columns,
                  rows: rows,
                  onEdit: canEdit ? _editRow : null,
                  onDelete: canEdit ? _deleteRow : null,
                ),
        ),
        if (sql == null && (page?.count ?? 0) > _limit)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _offset > 0
                      ? () {
                          _offset = (_offset - _limit).clamp(0, page!.count);
                          unawaited(_loadPage());
                        }
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  '${_offset + 1}–${(_offset + rows.length).clamp(0, page!.count)} of ${page.count}',
                ),
                IconButton(
                  onPressed: _offset + _limit < page.count
                      ? () {
                          _offset += _limit;
                          unawaited(_loadPage());
                        }
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        QueryBuilder(table: widget.table.name, onExecute: _executeSql),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.retry});

  final String error;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: retry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
