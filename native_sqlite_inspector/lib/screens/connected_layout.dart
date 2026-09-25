// Portions adapted from Isar Community Inspector.
// Copyright 2022 Simon Leier. Licensed under Apache-2.0.
// See the package NOTICE and LICENSES/Apache-2.0.txt files.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:native_sqlite/inspector_protocol.dart';

import '../connect_client.dart';
import '../widgets/sidebar.dart';
import '../widgets/table_view.dart';

class ConnectedLayout extends StatefulWidget {
  const ConnectedLayout({
    super.key,
    required this.client,
    required this.databases,
  });

  final ConnectClient client;
  final List<InspectorDatabaseInfo> databases;

  @override
  State<ConnectedLayout> createState() => _ConnectedLayoutState();
}

class _ConnectedLayoutState extends State<ConnectedLayout> {
  late List<InspectorDatabaseInfo> _databases;
  String? _selectedDatabase;
  String? _selectedTable;
  StreamSubscription<void>? _connectionSubscription;
  StreamSubscription<void>? _dataSubscription;
  bool _reconnecting = false;
  String? _connectionError;

  @override
  void initState() {
    super.initState();
    _databases = widget.databases;
    _selectDefaults();
    _connectionSubscription = widget.client.connectionChanged.listen((_) {
      unawaited(_refreshAfterRestart());
    });
    _dataSubscription = widget.client.dataChanged.listen((_) {
      unawaited(_refreshSelectedSchema());
    });
  }

  void _selectDefaults() {
    if (_databases.isEmpty) {
      _selectedDatabase = null;
      _selectedTable = null;
      return;
    }
    if (!_databases.any((database) => database.name == _selectedDatabase)) {
      _selectedDatabase = _databases.first.name;
    }
    final current = _currentDatabase;
    if (current == null || current.tables.isEmpty) {
      _selectedTable = null;
    } else if (!current.tables.any((table) => table.name == _selectedTable)) {
      _selectedTable = current.tables.first.name;
    }
  }

  InspectorDatabaseInfo? get _currentDatabase {
    final selected = _selectedDatabase;
    if (selected == null) return null;
    return _databases
        .where((database) => database.name == selected)
        .firstOrNull;
  }

  Future<void> _refreshAfterRestart() async {
    if (!mounted) return;
    setState(() {
      _reconnecting = true;
      _connectionError = null;
    });
    try {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      final databases = await widget.client.listDatabases();
      if (!mounted) return;
      setState(() {
        _databases = databases;
        _reconnecting = false;
        _selectDefaults();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _reconnecting = false;
        _connectionError = error.toString();
      });
    }
  }

  Future<void> _refreshSelectedSchema() async {
    final selected = _selectedDatabase;
    if (selected == null) return;
    try {
      final tables = await widget.client.getSchema(selected);
      if (!mounted) return;
      setState(() {
        final index = _databases.indexWhere(
          (database) => database.name == selected,
        );
        if (index >= 0) {
          final current = _databases[index];
          _databases = [..._databases];
          _databases[index] = InspectorDatabaseInfo(
            name: current.name,
            path: current.path,
            tables: tables,
            size: current.size,
          );
          _selectDefaults();
        }
      });
    } catch (_) {
      // The reconnect flow reports connection failures; data refresh is best effort.
    }
  }

  void _selectDatabase(String database) {
    setState(() {
      _selectedDatabase = database;
      _selectedTable = _currentDatabase?.tables.firstOrNull?.name;
    });
  }

  @override
  void dispose() {
    unawaited(_connectionSubscription?.cancel());
    unawaited(_dataSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final database = _currentDatabase;
    final table = database?.tables
        .where((schema) => schema.name == _selectedTable)
        .firstOrNull;
    return Column(
      children: [
        if (_reconnecting || _connectionError != null)
          MaterialBanner(
            content: Text(
              _reconnecting
                  ? 'The app restarted. Reconnecting…'
                  : 'Could not reconnect: $_connectionError',
            ),
            actions: [
              if (!_reconnecting)
                TextButton(
                  onPressed: _refreshAfterRestart,
                  child: const Text('Retry'),
                ),
            ],
          ),
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 260,
                child: Sidebar(
                  databases: _databases,
                  selectedDatabase: _selectedDatabase,
                  onDatabaseSelected: _selectDatabase,
                  selectedTable: _selectedTable,
                  onTableSelected: (selected) {
                    setState(() => _selectedTable = selected);
                  },
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: database == null
                    ? const _EmptyState(
                        icon: Icons.storage_outlined,
                        message: 'No open databases were found.',
                      )
                    : table == null
                    ? const _EmptyState(
                        icon: Icons.table_rows_outlined,
                        message: 'This database has no tables or views.',
                      )
                    : TableView(
                        key: ValueKey('${database.name}.${table.name}'),
                        database: database.name,
                        table: table,
                        client: widget.client,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(message),
        ],
      ),
    );
  }
}
