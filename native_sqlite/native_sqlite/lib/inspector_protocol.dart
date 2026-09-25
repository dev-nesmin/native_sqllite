/// Typed wire contract shared by the runtime service extensions and the
/// native_sqlite DevTools extension.
library;

/// Names, limits, and events in the native_sqlite inspector wire protocol.
abstract final class NativeSqliteInspectorProtocol {
  /// Current wire-protocol version.
  static const int version = 1;

  /// Maximum number of rows returned by an ad-hoc SQL query.
  static const int maxSqlRows = 1000;

  /// Synthetic identity key used for SQLite rowids.
  static const String rowIdKey = '__rowid';

  /// Service extension that returns [InspectorInfo].
  static const String getInfo = 'ext.native_sqlite.getInfo';

  /// Service extension that lists open databases.
  static const String listDatabases = 'ext.native_sqlite.listDatabases';

  /// Service extension that returns database schema metadata.
  static const String getSchema = 'ext.native_sqlite.getSchema';

  /// Service extension that browses a table or view.
  static const String executeQuery = 'ext.native_sqlite.executeQuery';

  /// Service extension that executes ad-hoc SQL.
  static const String executeSql = 'ext.native_sqlite.executeSql';

  /// Service extension that reads SQLite's data version.
  static const String getDataVersion = 'ext.native_sqlite.getDataVersion';

  /// Service extension that updates exactly one identified row.
  static const String updateRecord = 'ext.native_sqlite.updateRecord';

  /// Service extension that deletes exactly one identified row.
  static const String deleteRecord = 'ext.native_sqlite.deleteRecord';

  /// Extension event emitted after inspector mutations.
  static const String dataChangedEvent = 'ext.native_sqlite.data_changed';
}

/// Request targeting an open database by logical name.
final class InspectorDatabaseRequest {
  /// Creates a database request.
  const InspectorDatabaseRequest(this.database);

  /// Logical database name.
  final String database;

  /// Decodes a request from its wire representation.
  factory InspectorDatabaseRequest.fromJson(Map<String, Object?> json) =>
      InspectorDatabaseRequest(json['database'] as String);

  /// Encodes this request for the service-extension wire protocol.
  Map<String, Object?> toJson() => {'database': database};
}

/// Request for one stable page of table or view rows.
final class InspectorBrowseRequest {
  /// Creates a table-browse request.
  const InspectorBrowseRequest({
    required this.database,
    required this.table,
    required this.limit,
    required this.offset,
  });

  /// Logical database name.
  final String database;

  /// SQLite table or view name.
  final String table;

  /// Maximum number of rows to return.
  final int limit;

  /// Zero-based row offset.
  final int offset;

  /// Decodes a request from its wire representation.
  factory InspectorBrowseRequest.fromJson(Map<String, Object?> json) =>
      InspectorBrowseRequest(
        database: json['database'] as String,
        table: json['table'] as String,
        limit: json['limit'] as int,
        offset: json['offset'] as int,
      );

  /// Encodes this request for the service-extension wire protocol.
  Map<String, Object?> toJson() => {
    'database': database,
    'table': table,
    'limit': limit,
    'offset': offset,
  };
}

/// Request to execute an ad-hoc SQL statement.
final class InspectorSqlRequest {
  /// Creates an SQL request.
  const InspectorSqlRequest({
    required this.database,
    required this.sql,
    required this.allowWrite,
  });

  /// Logical database name.
  final String database;

  /// Single SQL statement to execute.
  final String sql;

  /// Whether the user explicitly enabled write statements.
  final bool allowWrite;

  /// Decodes a request from its wire representation.
  factory InspectorSqlRequest.fromJson(Map<String, Object?> json) =>
      InspectorSqlRequest(
        database: json['database'] as String,
        sql: json['sql'] as String,
        allowWrite: json['allowWrite'] as bool? ?? false,
      );

  /// Encodes this request for the service-extension wire protocol.
  Map<String, Object?> toJson() => {
    'database': database,
    'sql': sql,
    'allowWrite': allowWrite,
  };
}

/// Stable identity used to target one database record.
final class InspectorRecordIdentity {
  /// Creates a rowid or primary-key identity.
  const InspectorRecordIdentity({required this.kind, required this.values});

  /// Identity strategy, either `rowid` or `primaryKey`.
  final String kind;

  /// Identity column names and their lossless string values.
  final Map<String, String> values;

  /// Decodes an identity from its wire representation.
  factory InspectorRecordIdentity.fromJson(Map<String, Object?> json) =>
      InspectorRecordIdentity(
        kind: json['kind'] as String,
        values: (json['values'] as Map).cast<String, String>(),
      );

  /// Encodes this identity for the service-extension wire protocol.
  Map<String, Object?> toJson() => {'kind': kind, 'values': values};
}

/// Request to update or delete exactly one identified record.
final class InspectorMutationRequest {
  /// Creates a record-mutation request.
  const InspectorMutationRequest({
    required this.database,
    required this.table,
    required this.identity,
    this.values = const {},
  });

  /// Logical database name.
  final String database;

  /// Target table name.
  final String table;

  /// Stable identity of the target row.
  final InspectorRecordIdentity identity;

  /// Column values for an update; empty for deletion.
  final Map<String, Object?> values;

  /// Decodes a request from its wire representation.
  factory InspectorMutationRequest.fromJson(Map<String, Object?> json) =>
      InspectorMutationRequest(
        database: json['database'] as String,
        table: json['table'] as String,
        identity: InspectorRecordIdentity.fromJson(
          (json['identity'] as Map).cast<String, Object?>(),
        ),
        values: (json['values'] as Map?)?.cast<String, Object?>() ?? const {},
      );

  /// Encodes this request for the service-extension wire protocol.
  Map<String, Object?> toJson() => {
    'database': database,
    'table': table,
    'identity': identity.toJson(),
    'values': values,
  };
}

/// Runtime handshake returned to the DevTools extension.
final class InspectorInfo {
  /// Creates inspector handshake information.
  const InspectorInfo({
    required this.protocol,
    required this.package,
    required this.capabilities,
  });

  /// Wire-protocol version supported by the runtime.
  final int protocol;

  /// Runtime package identifier and version.
  final String package;

  /// Named protocol capabilities supported by the runtime.
  final List<String> capabilities;

  /// Decodes handshake information from the wire representation.
  factory InspectorInfo.fromJson(Map<String, Object?> json) => InspectorInfo(
    protocol: json['protocol'] as int,
    package: json['package'] as String,
    capabilities: (json['capabilities'] as List).cast<String>(),
  );

  /// Encodes this information for the service-extension wire protocol.
  Map<String, Object?> toJson() => {
    'protocol': protocol,
    'package': package,
    'capabilities': capabilities,
  };
}

/// Metadata for one open SQLite database.
final class InspectorDatabaseInfo {
  /// Creates database metadata.
  const InspectorDatabaseInfo({
    required this.name,
    required this.path,
    required this.tables,
    required this.size,
  });

  /// Logical database name.
  final String name;

  /// Platform-specific database path.
  final String path;

  /// Tables and views in the database.
  final List<InspectorTableSchema> tables;

  /// Database file size in bytes, or zero when unavailable.
  final int size;

  /// Decodes database metadata from the wire representation.
  factory InspectorDatabaseInfo.fromJson(Map<String, Object?> json) =>
      InspectorDatabaseInfo(
        name: json['name'] as String,
        path: json['path'] as String,
        tables: (json['tables'] as List)
            .map(
              (value) => InspectorTableSchema.fromJson(
                (value as Map).cast<String, Object?>(),
              ),
            )
            .toList(),
        size: json['size'] as int,
      );

  /// Encodes this metadata for the service-extension wire protocol.
  Map<String, Object?> toJson() => {
    'name': name,
    'path': path,
    'tables': tables.map((table) => table.toJson()).toList(),
    'size': size,
  };
}

/// Schema metadata for one SQLite table or view.
final class InspectorTableSchema {
  /// Creates table schema metadata.
  const InspectorTableSchema({
    required this.name,
    required this.columns,
    required this.primaryKeys,
    required this.indexes,
    required this.usesRowId,
    required this.isView,
  });

  /// Table or view name.
  final String name;

  /// Ordered column definitions.
  final List<InspectorColumnInfo> columns;

  /// Primary-key columns in key order.
  final List<String> primaryKeys;

  /// Index names defined for this object.
  final List<String> indexes;

  /// Whether SQLite rowid can identify records.
  final bool usesRowId;

  /// Whether this object is a read-only view.
  final bool isView;

  /// Decodes schema metadata from the wire representation.
  factory InspectorTableSchema.fromJson(Map<String, Object?> json) =>
      InspectorTableSchema(
        name: json['name'] as String,
        columns: (json['columns'] as List)
            .map(
              (value) => InspectorColumnInfo.fromJson(
                (value as Map).cast<String, Object?>(),
              ),
            )
            .toList(),
        primaryKeys: (json['primaryKeys'] as List).cast<String>(),
        indexes: (json['indexes'] as List).cast<String>(),
        usesRowId: json['usesRowId'] as bool,
        isView: json['isView'] as bool,
      );

  /// Encodes this metadata for the service-extension wire protocol.
  Map<String, Object?> toJson() => {
    'name': name,
    'columns': columns.map((column) => column.toJson()).toList(),
    'primaryKeys': primaryKeys,
    'indexes': indexes,
    'usesRowId': usesRowId,
    'isView': isView,
  };
}

/// SQLite schema metadata for one column.
final class InspectorColumnInfo {
  /// Creates column metadata.
  const InspectorColumnInfo({
    required this.name,
    required this.type,
    required this.nullable,
    required this.primaryKeyPosition,
    this.defaultValue,
  });

  /// Column name.
  final String name;

  /// Declared SQLite type.
  final String type;

  /// Whether the column accepts null values.
  final bool nullable;

  /// One-based position in a composite primary key, or zero.
  final int primaryKeyPosition;

  /// SQL default value as reported by SQLite.
  final Object? defaultValue;

  /// Decodes column metadata from the wire representation.
  factory InspectorColumnInfo.fromJson(Map<String, Object?> json) =>
      InspectorColumnInfo(
        name: json['name'] as String,
        type: json['type'] as String,
        nullable: json['nullable'] as bool,
        primaryKeyPosition: json['primaryKeyPosition'] as int,
        defaultValue: json['defaultValue'],
      );

  /// Encodes this metadata for the service-extension wire protocol.
  Map<String, Object?> toJson() => {
    'name': name,
    'type': type,
    'nullable': nullable,
    'primaryKeyPosition': primaryKeyPosition,
    'defaultValue': defaultValue,
  };
}

/// A stable page of rows returned by the table browser.
final class InspectorQueryPage {
  /// Creates a table-browser result page.
  const InspectorQueryPage({
    required this.columns,
    required this.rows,
    required this.identities,
    required this.count,
  });

  /// Ordered result column names.
  final List<String> columns;

  /// Positional result rows.
  final List<List<Object?>> rows;

  /// Per-row identities; entries are null for views.
  final List<InspectorRecordIdentity?> identities;

  /// Total rows in the table or view.
  final int count;

  /// Decodes a result page from the wire representation.
  factory InspectorQueryPage.fromJson(Map<String, Object?> json) =>
      InspectorQueryPage(
        columns: (json['columns'] as List).cast<String>(),
        rows: (json['rows'] as List)
            .map((value) => (value as List).cast<Object?>())
            .toList(),
        identities: (json['identities'] as List)
            .map(
              (value) => value == null
                  ? null
                  : InspectorRecordIdentity.fromJson(
                      (value as Map).cast<String, Object?>(),
                    ),
            )
            .toList(),
        count: json['count'] as int,
      );

  /// Encodes this page for the service-extension wire protocol.
  Map<String, Object?> toJson() => {
    'columns': columns,
    'rows': rows,
    'identities': identities.map((identity) => identity?.toJson()).toList(),
    'count': count,
  };
}

/// Result of an ad-hoc SQL statement.
final class InspectorSqlResult {
  /// Creates an SQL execution result.
  const InspectorSqlResult({
    required this.columns,
    required this.rows,
    required this.affectedRows,
    required this.truncated,
    required this.readOnly,
  });

  /// Ordered result column names, including duplicate names.
  final List<String> columns;

  /// Positional result rows.
  final List<List<Object?>> rows;

  /// Number of rows affected by a write statement.
  final int affectedRows;

  /// Whether more rows existed beyond the protocol limit.
  final bool truncated;

  /// Whether the executed statement was classified as read-only.
  final bool readOnly;

  /// Decodes an SQL result from the wire representation.
  factory InspectorSqlResult.fromJson(Map<String, Object?> json) =>
      InspectorSqlResult(
        columns: (json['columns'] as List).cast<String>(),
        rows: (json['rows'] as List)
            .map((value) => (value as List).cast<Object?>())
            .toList(),
        affectedRows: json['affectedRows'] as int,
        truncated: json['truncated'] as bool,
        readOnly: json['readOnly'] as bool,
      );

  /// Encodes this result for the service-extension wire protocol.
  Map<String, Object?> toJson() => {
    'columns': columns,
    'rows': rows,
    'affectedRows': affectedRows,
    'truncated': truncated,
    'readOnly': readOnly,
  };
}
