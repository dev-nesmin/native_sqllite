import 'package:flutter_test/flutter_test.dart';
import 'package:native_sqlite/inspector_protocol.dart';
import 'package:native_sqlite_inspector/connect_client.dart';

void main() {
  test(
    'client negotiates protocol and decodes recorded typed responses',
    () async {
      final calls = <String>[];
      final client = await ConnectClient.connectWith((method, args) async {
        calls.add(method);
        switch (method) {
          case NativeSqliteInspectorProtocol.getInfo:
            return const InspectorInfo(
              protocol: NativeSqliteInspectorProtocol.version,
              package: 'native_sqlite',
              capabilities: ['browse'],
            ).toJson();
          case NativeSqliteInspectorProtocol.listDatabases:
            return [
              const InspectorDatabaseInfo(
                name: 'app',
                path: '/tmp/app.db',
                tables: [],
                size: 128,
              ).toJson(),
            ];
          case NativeSqliteInspectorProtocol.getSchema:
            expect(args, {'database': 'app'});
            return [
              const InspectorTableSchema(
                name: 'items',
                columns: [
                  InspectorColumnInfo(
                    name: 'id',
                    type: 'INTEGER',
                    nullable: false,
                    primaryKeyPosition: 1,
                  ),
                ],
                primaryKeys: ['id'],
                indexes: [],
                usesRowId: true,
                isView: false,
              ).toJson(),
            ];
          case NativeSqliteInspectorProtocol.executeQuery:
            return const InspectorQueryPage(
              columns: ['id'],
              rows: [
                [1],
              ],
              identities: [
                InspectorRecordIdentity(
                  kind: 'rowid',
                  values: {'__rowid': '1'},
                ),
              ],
              count: 1,
            ).toJson();
          case NativeSqliteInspectorProtocol.executeSql:
            return const InspectorSqlResult(
              columns: ['answer', 'answer'],
              rows: [
                [1, 2],
              ],
              affectedRows: 0,
              truncated: false,
              readOnly: true,
            ).toJson();
          case NativeSqliteInspectorProtocol.getDataVersion:
            return 7;
          case NativeSqliteInspectorProtocol.updateRecord:
          case NativeSqliteInspectorProtocol.deleteRecord:
            return true;
        }
        throw StateError('Unexpected method $method');
      });
      addTearDown(client.dispose);

      final databases = await client.listDatabases();
      expect(databases.single.name, 'app');
      expect(client.databaseInfo['app']?.size, 128);

      final schema = await client.getSchema('app');
      expect(schema.single.name, 'items');
      expect(client.databaseInfo['app']?.tables.single.name, 'items');

      final page = await client.executeQuery(
        const InspectorBrowseRequest(
          database: 'app',
          table: 'items',
          limit: 50,
          offset: 0,
        ),
      );
      expect(page.identities.single?.values['__rowid'], '1');

      final sql = await client.executeSql(
        const InspectorSqlRequest(
          database: 'app',
          sql: 'SELECT 1 AS answer, 2 AS answer',
          allowWrite: false,
        ),
      );
      expect(sql.columns, ['answer', 'answer']);
      expect(await client.getDataVersion('app'), 7);

      const identity = InspectorRecordIdentity(
        kind: 'rowid',
        values: {'__rowid': '1'},
      );
      await client.updateRecord(
        const InspectorMutationRequest(
          database: 'app',
          table: 'items',
          identity: identity,
          values: {'id': 2},
        ),
      );
      await client.deleteRecord(
        const InspectorMutationRequest(
          database: 'app',
          table: 'items',
          identity: identity,
        ),
      );
      expect(calls.first, NativeSqliteInspectorProtocol.getInfo);
      expect(
        calls,
        containsAll([
          NativeSqliteInspectorProtocol.listDatabases,
          NativeSqliteInspectorProtocol.getSchema,
          NativeSqliteInspectorProtocol.executeQuery,
          NativeSqliteInspectorProtocol.executeSql,
          NativeSqliteInspectorProtocol.updateRecord,
          NativeSqliteInspectorProtocol.deleteRecord,
        ]),
      );
    },
  );

  test('client rejects an incompatible protocol before other calls', () async {
    await expectLater(
      ConnectClient.connectWith((method, args) async {
        return const InspectorInfo(
          protocol: 999,
          package: 'native_sqlite',
          capabilities: [],
        ).toJson();
      }),
      throwsStateError,
    );
  });
}
