import 'package:flutter_test/flutter_test.dart';
import 'package:native_sqlite/native_sqlite.dart';
import 'package:native_sqlite/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'inspector handlers honor the typed protocol and safe row identity',
    () async {
      InspectorConnect.enabled = true;
      InspectorConnect.printBanner = false;
      InspectorConnect.debugClearDatabases();
      final backend = NativeSqliteTesting.useFfi();
      final database = await NativeSqlite.open(
        DatabaseConfig(
          name: 'inspector_contract',
          onCreate: const [
            'CREATE TABLE items ('
                'id INTEGER PRIMARY KEY, name TEXT, payload BLOB, score REAL)',
            'CREATE INDEX items_name ON items(name)',
            "INSERT INTO items VALUES (1, 'first', X'0001FF', 1e999)",
            'CREATE TABLE composite ('
                'tenant INTEGER, code TEXT, value TEXT, '
                'PRIMARY KEY (tenant, code)) WITHOUT ROWID',
            "INSERT INTO composite VALUES (9007199254740993, 'A', 'kept')",
            'CREATE VIEW item_names AS SELECT name FROM items',
          ],
        ),
      );
      addTearDown(() async {
        await database.close();
        backend.dispose();
        InspectorConnect.debugClearDatabases();
      });

      final info = InspectorInfo.fromJson(
        (await InspectorConnect.debugHandle(
                  NativeSqliteInspectorProtocol.getInfo,
                )
                as Map<Object?, Object?>)
            .cast<String, Object?>(),
      );
      expect(info.protocol, NativeSqliteInspectorProtocol.version);
      expect(info.capabilities, containsAll(['browse', 'sql', 'updateRecord']));

      final listed =
          await InspectorConnect.debugHandle(
                NativeSqliteInspectorProtocol.listDatabases,
              )
              as List<Object?>;
      final databaseInfo = InspectorDatabaseInfo.fromJson(
        (listed.single as Map).cast<String, Object?>(),
      );
      expect(databaseInfo.name, 'inspector_contract');
      expect(databaseInfo.tables.map((table) => table.name), [
        'composite',
        'item_names',
        'items',
      ]);
      expect(
        databaseInfo.tables.singleWhere((table) => table.name == 'composite'),
        isA<InspectorTableSchema>()
            .having((table) => table.usesRowId, 'usesRowId', isFalse)
            .having((table) => table.primaryKeys, 'primaryKeys', [
              'tenant',
              'code',
            ]),
      );
      expect(
        databaseInfo.tables
            .singleWhere((table) => table.name == 'item_names')
            .isView,
        isTrue,
      );
      expect(
        databaseInfo.tables
            .singleWhere((table) => table.name == 'items')
            .indexes,
        ['items_name (name)'],
      );

      final itemsPage = InspectorQueryPage.fromJson(
        (await InspectorConnect.debugHandle(
                  NativeSqliteInspectorProtocol.executeQuery,
                  const InspectorBrowseRequest(
                    database: 'inspector_contract',
                    table: 'items',
                    limit: 50,
                    offset: 0,
                  ).toJson(),
                )
                as Map)
            .cast<String, Object?>(),
      );
      expect(itemsPage.columns, ['id', 'name', 'payload', 'score']);
      expect(itemsPage.identities.single?.kind, 'rowid');
      expect(
        itemsPage.identities.single?.values[NativeSqliteInspectorProtocol
            .rowIdKey],
        '1',
      );
      expect(itemsPage.rows.single[2], {
        r'$type': 'blob',
        'base64': 'AAH/',
        'length': 3,
      });
      expect(itemsPage.rows.single[3], {
        r'$type': 'number',
        'value': 'Infinity',
      });

      final compositePage = InspectorQueryPage.fromJson(
        (await InspectorConnect.debugHandle(
                  NativeSqliteInspectorProtocol.executeQuery,
                  const InspectorBrowseRequest(
                    database: 'inspector_contract',
                    table: 'composite',
                    limit: 50,
                    offset: 0,
                  ).toJson(),
                )
                as Map)
            .cast<String, Object?>(),
      );
      expect(compositePage.identities.single?.values, {
        'tenant': '9007199254740993',
        'code': 'A',
      });

      final duplicateColumns = InspectorSqlResult.fromJson(
        (await InspectorConnect.debugHandle(
                  NativeSqliteInspectorProtocol.executeSql,
                  const InspectorSqlRequest(
                    database: 'inspector_contract',
                    sql: '/* comment */ SELECT 1 AS duplicate, 2 AS duplicate',
                    allowWrite: false,
                  ).toJson(),
                )
                as Map)
            .cast<String, Object?>(),
      );
      expect(duplicateColumns.columns, ['duplicate', 'duplicate']);
      expect(duplicateColumns.rows, [
        [1, 2],
      ]);
      expect(duplicateColumns.readOnly, isTrue);

      final capped = InspectorSqlResult.fromJson(
        (await InspectorConnect.debugHandle(
                  NativeSqliteInspectorProtocol.executeSql,
                  const InspectorSqlRequest(
                    database: 'inspector_contract',
                    sql:
                        'WITH RECURSIVE n(x) AS ('
                        'VALUES(1) UNION ALL SELECT x + 1 FROM n WHERE x < 1001) '
                        'SELECT x FROM n',
                    allowWrite: false,
                  ).toJson(),
                )
                as Map)
            .cast<String, Object?>(),
      );
      expect(capped.rows, hasLength(NativeSqliteInspectorProtocol.maxSqlRows));
      expect(capped.truncated, isTrue);
      expect(capped.readOnly, isTrue);

      await expectLater(
        InspectorConnect.debugHandle(
          NativeSqliteInspectorProtocol.executeSql,
          const InspectorSqlRequest(
            database: 'inspector_contract',
            sql: 'PRAGMA journal_mode(WAL)',
            allowWrite: false,
          ).toJson(),
        ),
        throwsStateError,
      );

      await expectLater(
        InspectorConnect.debugHandle(
          NativeSqliteInspectorProtocol.executeSql,
          const InspectorSqlRequest(
            database: 'inspector_contract',
            sql: "UPDATE items SET name = 'blocked' WHERE id = 1",
            allowWrite: false,
          ).toJson(),
        ),
        throwsStateError,
      );

      await InspectorConnect.debugHandle(
        NativeSqliteInspectorProtocol.updateRecord,
        InspectorMutationRequest(
          database: 'inspector_contract',
          table: 'items',
          identity: itemsPage.identities.single!,
          values: const {'name': 'updated'},
        ).toJson(),
      );
      expect(
        (await database.query(
          'SELECT name FROM items WHERE id = 1',
        )).rows.single,
        ['updated'],
      );

      await expectLater(
        InspectorConnect.debugHandle(
          NativeSqliteInspectorProtocol.deleteRecord,
          const InspectorMutationRequest(
            database: 'inspector_contract',
            table: 'items',
            identity: InspectorRecordIdentity(
              kind: 'rowid',
              values: {NativeSqliteInspectorProtocol.rowIdKey: '999'},
            ),
          ).toJson(),
        ),
        throwsStateError,
      );
      expect((await database.query('SELECT COUNT(*) FROM items')).rows.single, [
        1,
      ]);

      await InspectorConnect.debugHandle(
        NativeSqliteInspectorProtocol.deleteRecord,
        InspectorMutationRequest(
          database: 'inspector_contract',
          table: 'composite',
          identity: compositePage.identities.single!,
        ).toJson(),
      );
      expect(
        (await database.query('SELECT COUNT(*) FROM composite')).rows.single,
        [0],
      );
    },
  );

  test('protocol value objects round-trip without unchecked shape changes', () {
    const page = InspectorQueryPage(
      columns: ['same', 'same'],
      rows: [
        [1, 2],
      ],
      identities: [
        InspectorRecordIdentity(kind: 'rowid', values: {'__rowid': '42'}),
      ],
      count: 1,
    );
    expect(InspectorQueryPage.fromJson(page.toJson()).toJson(), page.toJson());

    const result = InspectorSqlResult(
      columns: ['a'],
      rows: [
        [null],
      ],
      affectedRows: 0,
      truncated: false,
      readOnly: true,
    );
    expect(
      InspectorSqlResult.fromJson(result.toJson()).toJson(),
      result.toJson(),
    );
  });
}
