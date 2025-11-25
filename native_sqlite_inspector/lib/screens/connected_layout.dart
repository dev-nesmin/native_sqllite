import 'dart:async';

import 'package:flutter/material.dart';

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
  final List<DatabaseInfo> databases;

  @override
  State<ConnectedLayout> createState() => _ConnectedLayoutState();
}

class _ConnectedLayoutState extends State<ConnectedLayout> {
  late String selectedDatabase;
  late String selectedTable;
  late StreamSubscription<void> infoSubscription;

  @override
  void initState() {
    _selectDatabase(widget.databases.first.name);
    infoSubscription = widget.client.dataChanged.listen((_) {
      setState(() {});
    });
    super.initState();
  }

  void _selectDatabase(String database) {
    selectedDatabase = database;
    final db = widget.databases.firstWhere((d) => d.name == database);
    if (db.tables.isNotEmpty) {
      selectedTable = db.tables.first.name;
    }
    // widget.client.watchDatabase(database);
  }

  @override
  void dispose() {
    infoSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentDb = widget.databases.firstWhere(
      (d) => d.name == selectedDatabase,
    );

    return Row(
      children: [
        SizedBox(
          width: 250,
          child: Sidebar(
            databases: widget.databases.map((d) => d.name).toList(),
            selectedDatabase: selectedDatabase,
            onDatabaseSelected: (db) {
              setState(() {
                _selectDatabase(db);
              });
            },
            tables: currentDb.tables.map((t) => t.name).toList(),
            selectedTable: selectedTable,
            onTableSelected: (table) {
              setState(() {
                selectedTable = table;
              });
            },
            databaseInfo: widget.client.databaseInfo[selectedDatabase],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: TableView(
            key: Key('$selectedDatabase.$selectedTable'),
            database: selectedDatabase,
            table: selectedTable,
            client: widget.client,
            schema: currentDb.tables.firstWhere((t) => t.name == selectedTable),
          ),
        ),
      ],
    );
  }
}
