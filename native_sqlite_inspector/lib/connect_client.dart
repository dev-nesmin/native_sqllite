// Portions adapted from Isar Community Inspector.
// Copyright 2022 Simon Leier. Licensed under Apache-2.0.
// See the package NOTICE and LICENSES/Apache-2.0.txt files.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:native_sqlite/inspector_protocol.dart';

import 'devtools_transport.dart';

typedef InspectorServiceCall =
    Future<Object?> Function(String method, Map<String, Object?> args);

/// Typed client for the native_sqlite VM service extensions exposed by the
/// connected debug application.
class ConnectClient {
  ConnectClient._(this._callService, [this._transport]);

  static const normalTimeout = Duration(seconds: 4);
  static const longTimeout = Duration(seconds: 10);

  final InspectorServiceCall _callService;
  final DevToolsTransport? _transport;
  final databaseInfo = <String, InspectorDatabaseInfo>{};
  final _dataChangedController = StreamController<void>.broadcast();
  final _connectionChangedController = StreamController<void>.broadcast();
  bool _disposed = false;

  Stream<void> get dataChanged => _dataChangedController.stream;
  Stream<void> get connectionChanged => _connectionChangedController.stream;

  static Future<ConnectClient> connect() async {
    final transport = createDevToolsTransport();
    final client = ConnectClient._(transport.call, transport);
    await client._verifyProtocol();
    await client._listenToDevTools();
    return client;
  }

  @visibleForTesting
  static Future<ConnectClient> connectWith(InspectorServiceCall call) async {
    final client = ConnectClient._(call);
    await client._verifyProtocol();
    return client;
  }

  Future<void> _listenToDevTools() async {
    await _transport!.start(
      onDataChanged: () {
        if (!_dataChangedController.isClosed) {
          _dataChangedController.add(null);
        }
      },
      onMainIsolateChanged: () {
        databaseInfo.clear();
        if (!_connectionChangedController.isClosed) {
          _connectionChangedController.add(null);
        }
      },
    );
  }

  Future<void> _verifyProtocol() async {
    final info = InspectorInfo.fromJson(
      _asMap(
        await _call(
          NativeSqliteInspectorProtocol.getInfo,
          timeout: normalTimeout,
        ),
      ),
    );
    if (info.protocol != NativeSqliteInspectorProtocol.version) {
      throw StateError(
        'Inspector protocol ${info.protocol} is not supported by this '
        'extension (expected ${NativeSqliteInspectorProtocol.version}).',
      );
    }
  }

  Future<Object?> _call(
    String method, {
    Map<String, Object?> args = const {},
    Duration timeout = normalTimeout,
  }) {
    if (_disposed) throw StateError('Inspector client has been disposed.');
    return _callService(method, args).timeout(timeout);
  }

  Future<List<InspectorDatabaseInfo>> listDatabases() async {
    final raw = await _call(NativeSqliteInspectorProtocol.listDatabases);
    final databases = (raw as List)
        .map((value) => InspectorDatabaseInfo.fromJson(_asMap(value)))
        .toList();
    databaseInfo
      ..clear()
      ..addEntries(
        databases.map((database) => MapEntry(database.name, database)),
      );
    return databases;
  }

  Future<List<InspectorTableSchema>> getSchema(String database) async {
    final raw = await _call(
      NativeSqliteInspectorProtocol.getSchema,
      args: InspectorDatabaseRequest(database).toJson(),
    );
    final tables = (raw as List)
        .map((value) => InspectorTableSchema.fromJson(_asMap(value)))
        .toList();
    final current = databaseInfo[database];
    if (current != null) {
      databaseInfo[database] = InspectorDatabaseInfo(
        name: current.name,
        path: current.path,
        tables: tables,
        size: current.size,
      );
    }
    return tables;
  }

  Future<InspectorQueryPage> executeQuery(
    InspectorBrowseRequest request,
  ) async {
    final raw = await _call(
      NativeSqliteInspectorProtocol.executeQuery,
      args: request.toJson(),
      timeout: longTimeout,
    );
    return InspectorQueryPage.fromJson(_asMap(raw));
  }

  Future<InspectorSqlResult> executeSql(InspectorSqlRequest request) async {
    final raw = await _call(
      NativeSqliteInspectorProtocol.executeSql,
      args: request.toJson(),
      timeout: longTimeout,
    );
    return InspectorSqlResult.fromJson(_asMap(raw));
  }

  Future<int> getDataVersion(String database) async {
    final value = await _call(
      NativeSqliteInspectorProtocol.getDataVersion,
      args: InspectorDatabaseRequest(database).toJson(),
    );
    return value as int;
  }

  Future<void> updateRecord(InspectorMutationRequest request) async {
    await _call(
      NativeSqliteInspectorProtocol.updateRecord,
      args: request.toJson(),
      timeout: longTimeout,
    );
  }

  Future<void> deleteRecord(InspectorMutationRequest request) async {
    await _call(
      NativeSqliteInspectorProtocol.deleteRecord,
      args: request.toJson(),
      timeout: longTimeout,
    );
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _transport?.dispose();
    await _dataChangedController.close();
    await _connectionChangedController.close();
  }

  static Map<String, Object?> _asMap(Object? value) {
    return (value as Map).cast<String, Object?>();
  }
}
