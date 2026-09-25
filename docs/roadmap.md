# native_sqlite roadmap

This roadmap records requested schema features without implying that their
annotations exist today. The 0.1 API is intentionally smaller; unsupported
annotations fail generation rather than producing approximate SQL.

## Schema annotations

| Feature | Proposed API direction | Generator work required |
|---|---|---|
| Composite primary keys | Class-level primary-key declaration | Row identity, repositories, migrations, native helpers |
| Composite UNIQUE | Class-level unique constraint | Quoted DDL, migration diff, inspector metadata |
| Column/table rename | `renamedFrom` metadata | Data-preserving migration steps and ambiguity checks |
| CHECK constraints | `@Check` with validated SQL | DDL, table rebuild diff, tests on every backend |
| Collations | Typed built-ins plus explicit custom name | DDL, comparison/query-builder semantics |
| Timestamps | `@CreatedAt` / `@UpdatedAt` policy | Insert/update generation across Dart/Kotlin/Swift |
| Relations | `@Relation` and has-many helpers | Cross-table analysis without hidden eager loading |
| Embedded values | `@Embedded` with a column prefix | Flattening, null semantics, converters, migrations |
| Views | `@DbView` | Dependency ordering, read-only repositories, inspector |
| FTS5 | Dedicated virtual-table declaration | Availability checks and platform-specific diagnostics |
| STRICT / WITHOUT ROWID | Table options | Compatibility validation, PK rules, migrations |
| Index shorthand | `@DbColumn(indexed: true)` | Canonicalize with class-level indexes |

Each feature must define SQLite-version requirements, generated Dart and
native behavior, migration compatibility, schema JSON format, inspector
behavior, and conformance tests before its annotation is added.

## Platform examples

The Android example includes a home-screen `AppWidgetProvider` that reads the
latest order through generated Kotlin helpers. An iOS WidgetKit target is the
follow-up: give Runner and the widget the same App Group entitlement, pass
that identifier as `iosAppGroup`, and read through the generated Swift helper.
