/// Quotes a SQLite identifier using the SQL-standard double-quote form.
///
/// Identifiers are data, not SQL fragments: embedded quotes are escaped by
/// doubling them. This helper is used by every generator SQL producer.
String quoteSqlIdentifier(String identifier) =>
    '"${identifier.replaceAll('"', '""')}"';
