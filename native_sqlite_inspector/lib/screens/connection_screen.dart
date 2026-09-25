// Portions adapted from Isar Community Inspector.
// Copyright 2022 Simon Leier. Licensed under Apache-2.0.
// See the package NOTICE and LICENSES/Apache-2.0.txt files.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:native_sqlite/inspector_protocol.dart';

import '../connect_client.dart';
import 'connected_layout.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  late Future<_Connection> _connection;
  ConnectClient? _client;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    _connection = _load();
  }

  Future<_Connection> _load() async {
    final client = await ConnectClient.connect();
    _client = client;
    return _Connection(client, await client.listDatabases());
  }

  @override
  void dispose() {
    unawaited(_client?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Connection>(
      future: _connection,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ConnectedLayout(
            client: snapshot.data!.client,
            databases: snapshot.data!.databases,
          );
        }
        if (snapshot.hasError) {
          return _ErrorScreen(
            error: snapshot.error.toString(),
            onRetry: () => setState(_connect),
          );
        }
        return const _Loading();
      },
    );
  }
}

final class _Connection {
  const _Connection(this.client, this.databases);

  final ConnectClient client;
  final List<InspectorDatabaseInfo> databases;
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Connecting through Flutter DevTools…'),
        ],
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.link_off, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              'native_sqlite is unavailable',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            const Text(
              'Run a debug build that opens a native_sqlite database, then retry.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
