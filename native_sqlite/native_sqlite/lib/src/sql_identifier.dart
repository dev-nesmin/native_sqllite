/// Quotes a SQLite identifier using double quotes, escaping embedded quotes.
String quoteSqlIdentifier(String identifier) =>
    '"${identifier.replaceAll('"', '""')}"';
