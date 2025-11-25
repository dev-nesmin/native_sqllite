import 'dart:async';

import 'package:flutter/material.dart';

import '../connect_client.dart';
import 'connected_layout.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({
    super.key,
    required this.port,
    required this.secret,
  });

  final String port;
  final String secret;

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  late Future<ConnectClient> clientFuture;
  // Add a key to force rebuild/retry
  int _retryKey = 0;

  @override
  void initState() {
    super.initState();
    _loadClient();
  }

  void _loadClient() {
    setState(() {
      clientFuture = ConnectClient.connect(widget.port, widget.secret);
    });
  }

  void _retry() {
    setState(() {
      _retryKey++;
      _loadClient();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ConnectClient>(
      key: ValueKey(_retryKey),
      future: clientFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _SchemaLoader(client: snapshot.data!);
        } else if (snapshot.hasError) {
          return ErrorScreen(
            error: snapshot.error.toString(),
            onRetry: _retry,
            port: widget.port,
            secret: widget.secret,
          );
        } else {
          return const Loading();
        }
      },
    );
  }
}

class _SchemaLoader extends StatefulWidget {
  const _SchemaLoader({required this.client});

  final ConnectClient client;

  @override
  State<_SchemaLoader> createState() => _SchemaLoaderState();
}

class _SchemaLoaderState extends State<_SchemaLoader> {
  late Future<List<DatabaseInfo>> databasesFuture;

  @override
  void initState() {
    databasesFuture = widget.client.listDatabases();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant _SchemaLoader oldWidget) {
    databasesFuture = widget.client.listDatabases();
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DatabaseInfo>>(
      future: databasesFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No databases found'),
            );
          }
          return ConnectedLayout(
            client: widget.client,
            databases: snapshot.data!,
          );
        } else if (snapshot.hasError) {
          return ErrorScreen(
            error: snapshot.error.toString(),
            onRetry: () {
              setState(() {
                databasesFuture = widget.client.listDatabases();
              });
            },
          );
        } else {
          return const Loading();
        }
      },
    );
  }
}

class Loading extends StatelessWidget {
  const Loading({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text('Connecting to app...'),
          const SizedBox(height: 8),
          Text(
            'v1.0.1',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({
    super.key,
    required this.error,
    required this.onRetry,
    this.port,
    this.secret,
  });

  final String error;
  final VoidCallback onRetry;
  final String? port;
  final String? secret;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Connection Error',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            if (port != null) ...[
              const SizedBox(height: 16),
              Text(
                'Target: $port',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Connection'),
            ),
          ],
        ),
      ),
    );
  }
}
