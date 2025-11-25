import 'dart:async';
import 'dart:convert';

import 'package:vm_service/vm_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ConnectClient {
  ConnectClient(this.vmService, this.isolateId);

  static const Duration kNormalTimeout = Duration(seconds: 4);
  static const Duration kLongTimeout = Duration(seconds: 10);

  final VmService vmService;
  final String isolateId;

  // Database info cache
  final databaseInfo = <String, DatabaseInfo>{};

  // Stream controllers for events
  final _dataChangedController = StreamController<void>.broadcast();

  Stream<void> get dataChanged => _dataChangedController.stream;

  static Future<ConnectClient> connect(String port, String secret) async {
    // WebSocket URL format: ws://127.0.0.1:port/secret=/ws
    final wsUrl = Uri.parse('ws://127.0.0.1:$port/$secret=/ws');
    print('Inspector: Attempting to connect to $wsUrl');

    try {
      final channel = WebSocketChannel.connect(wsUrl);
      print('Inspector: WebSocket channel created');

      // Handle errors
      final stream = channel.stream.handleError((error) {
        print('Inspector: WebSocket error: $error');
      });

      final service = VmService(
        stream,
        channel.sink.add,
        disposeHandler: channel.sink.close,
      );

      print('Inspector: VmService initialized, getting VM...');

      // Add timeout for initial connection
      final vm = await service.getVM().timeout(const Duration(seconds: 5));
      print('Inspector: VM received: ${vm.name}');

      final isolateId = vm.isolates!.where((e) => e.name == 'main').first.id!;
      print('Inspector: Main isolate found: $isolateId');

      await service.streamListen(EventStreams.kExtension);
      print('Inspector: Listening to extension events');

      final client = ConnectClient(service, isolateId);

      // Set up event handlers
      final handlers = {
        'ext.native_sqlite.data_changed': (_) {
          client._dataChangedController.add(null);
        },
      };

      service.onExtensionEvent.listen((Event event) {
        final data = event.extensionData?.data ?? {};
        handlers[event.extensionKind]?.call(data);
      });

      print('Inspector: Client ready');
      return client;
    } on TimeoutException {
      print('Inspector: Connection timed out');
      throw Exception(
        'Connection timed out. If you are using the hosted inspector (https), '
        'your browser might be blocking the insecure WebSocket connection (ws://). '
        'Please allow "Insecure Content" for this site in your browser settings.',
      );
    } catch (e) {
      print('Inspector: Connection failed with error: $e');
      throw Exception('Failed to connect: $e');
    }
  }

  Future<T> _call<T>(
    String method, {
    Duration? timeout = kNormalTimeout,
    Map<String, dynamic>? args,
  }) async {
    var responseFuture = vmService.callServiceExtension(
      method,
      isolateId: isolateId,
      args: {if (args != null) 'args': jsonEncode(args)},
    );

    if (timeout != null) {
      responseFuture = responseFuture.timeout(timeout);
    }

    final response = await responseFuture;
    return response.json?['result'] as T;
  }

  Future<List<DatabaseInfo>> listDatabases() async {
    final databases =
        await _call<List<dynamic>>('ext.native_sqlite.listDatabases');
    return databases
        .map((e) => DatabaseInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DatabaseInfo> getSchema(String database) async {
    final schema = await _call<Map<String, dynamic>>(
      'ext.native_sqlite.getSchema',
      args: {'database': database},
    );
    return DatabaseInfo.fromJson(schema);
  }

  // Note: watchDatabase not yet implemented in backend
  // Future<void> watchDatabase(String database) async {
  //   databaseInfo.clear();
  //   await _call<dynamic>(
  //     'ext.native_sqlite.watchDatabase',
  //     args: {'database': database},
  //   );
  // }

  Future<Map<String, Object?>> executeQuery(Map<String, dynamic> query) async {
    return _call<Map<String, Object?>>(
      'ext.native_sqlite.executeQuery',
      args: query,
      timeout: kLongTimeout,
    );
  }

  Future<List<Map<String, dynamic>>> executeSql(
    String database,
    String sql,
  ) async {
    final result = await _call<List<dynamic>>(
      'ext.native_sqlite.executeSql',
      args: {'database': database, 'sql': sql},
      timeout: kLongTimeout,
    );
    return result.cast<Map<String, dynamic>>();
  }

  Future<void> importJson(
    String database,
    String table,
    List<dynamic> objects,
  ) async {
    await _call<dynamic>(
      'ext.native_sqlite.importJson',
      args: {
        'database': database,
        'table': table,
        'data': objects,
      },
    );
  }

  Future<List<Map<String, dynamic>>> exportJson(
    Map<String, dynamic> query,
  ) async {
    final data = await _call<List<dynamic>>(
      'ext.native_sqlite.exportJson',
      args: query,
      timeout: kLongTimeout,
    );
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> updateRecord(
    String database,
    String table,
    dynamic id,
    Map<String, dynamic> values,
  ) async {
    await _call<dynamic>(
      'ext.native_sqlite.updateRecord',
      args: {
        'database': database,
        'table': table,
        'id': id,
        'values': values,
      },
    );
  }

  Future<void> deleteRecord(
    String database,
    String table,
    dynamic id,
  ) async {
    await _call<dynamic>(
      'ext.native_sqlite.deleteRecord',
      args: {
        'database': database,
        'table': table,
        'id': id,
      },
    );
  }

  Future<void> disconnect() async {
    await _dataChangedController.close();
    await vmService.dispose();
  }
}

// Database info model
class DatabaseInfo {
  DatabaseInfo({
    required this.name,
    required this.path,
    required this.tables,
    this.size,
  });

  final String name;
  final String path;
  final List<TableSchema> tables;
  final int? size;

  factory DatabaseInfo.fromJson(Map<String, dynamic> json) {
    return DatabaseInfo(
      name: json['name'] as String,
      path: json['path'] as String,
      tables: (json['tables'] as List<dynamic>)
          .map((t) => TableSchema.fromJson(t as Map<String, dynamic>))
          .toList(),
      size: json['size'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'tables': tables.map((t) => t.toJson()).toList(),
      'size': size,
    };
  }
}

class TableSchema {
  TableSchema({
    required this.name,
    required this.columns,
    this.primaryKey,
    this.indexes = const [],
  });

  final String name;
  final List<ColumnInfo> columns;
  final String? primaryKey;
  final List<String> indexes;

  factory TableSchema.fromJson(Map<String, dynamic> json) {
    return TableSchema(
      name: json['name'] as String,
      columns: (json['columns'] as List<dynamic>)
          .map((c) => ColumnInfo.fromJson(c as Map<String, dynamic>))
          .toList(),
      primaryKey: json['primaryKey'] as String?,
      indexes: (json['indexes'] as List<dynamic>).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'columns': columns.map((c) => c.toJson()).toList(),
      'primaryKey': primaryKey,
      'indexes': indexes,
    };
  }
}

class ColumnInfo {
  ColumnInfo({
    required this.name,
    required this.type,
    required this.nullable,
    this.defaultValue,
  });

  final String name;
  final String type;
  final bool nullable;
  final dynamic defaultValue;

  factory ColumnInfo.fromJson(Map<String, dynamic> json) {
    return ColumnInfo(
      name: json['name'] as String,
      type: json['type'] as String,
      nullable: json['nullable'] as bool,
      defaultValue: json['defaultValue'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'nullable': nullable,
      'defaultValue': defaultValue,
    };
  }
}
