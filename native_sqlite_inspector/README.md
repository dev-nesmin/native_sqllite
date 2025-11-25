# Native SQLite Inspector

A Flutter-based DevTools extension for inspecting SQLite databases in real-time during development. Similar to Isar Community Inspector, this tool provides a web-based interface to browse, query, and manage SQLite databases in your running Flutter applications.

## Features

- 🔍 **Real-time Database Inspection** - View tables, schemas, and data as your app runs
- 📊 **Data Grid View** - Browse table data with pagination and filtering
- 🔧 **SQL Query Execution** - Run custom SQL queries directly from the inspector
- 📤 **JSON Export** - Export table data to JSON format
- 🗑️ **Record Management** - Update and delete records through the UI
- 🎨 **Dark Theme** - Professional dark UI designed for developer workflow
- 🌐 **Web-Based** - Runs in your browser, no additional installation needed

## Architecture

The inspector uses the Dart VM Service Protocol to communicate with your running Flutter application:

```
Flutter App (Debug Mode)
    ↓ VM Service Extension
    ↓ WebSocket Connection
Native SQLite Inspector (Web)
    ↓ User Interface
    ↓ Query Execution
SQLite Database
```

### Key Components

- **ConnectClient** - Manages WebSocket connection to VM Service and database operations
- **Connection Screen** - Handles initial connection and loading states
- **Connected Layout** - Main layout with sidebar and table view
- **Sidebar** - Database and table navigation
- **TableView** - Data viewer with pagination and query execution
- **DataGrid** - Renders table data in a scrollable grid
- **QueryBuilder** - SQL query input and execution interface

## Installation

Add this package to your `dev_dependencies`:

```yaml
dev_dependencies:
  native_sqlite_inspector:
    path: ../native_sqlite_inspector
```

Then run:

```bash
flutter pub get
```

## Usage

### 1. Enable VM Service Extension in Your App

In your Flutter app, register the SQLite inspector service extension:

```dart
import 'package:native_sqlite/native_sqlite.dart';
import 'dart:developer' as developer;

void main() {
  // Register service extension for database inspection
  developer.registerExtension('ext.native_sqlite.listDatabases', (method, parameters) async {
    final databases = Database.listOpenDatabases();
    return developer.ServiceExtensionResponse.result(json.encode({
      'databases': databases.map((db) => {
        'name': db.path,
        'tables': db.tables.length,
      }).toList(),
    }));
  });

  runApp(MyApp());
}
```

### 2. Run Your Flutter App in Debug Mode

```bash
flutter run --observatory-port=8181
```

The app will output a VM Service URL like:
```
Observatory listening on ws://127.0.0.1:8181/AbCdEfGh=/ws
```

### Usage

1. **Access the hosted inspector**: Navigate to `http://dev-nesmin.github.io/native_sqllite/`
   - Note: Use HTTP (not HTTPS) to avoid browser Mixed Content blocking

2. **Run your Flutter app**: The inspector will automatically detect the VM Service URI and print it in the console

3. **Connect**: If auto-detect works, the console will show a clickable link. Otherwise, manually copy the port and secret from the VM Service URIit (or copy-paste it) to connect automatically.

The inspector will:
- List all open databases
- Show available tables
- Display table schemas

## Development

### Project Structure

```
native_sqlite_inspector/
├── lib/
│   ├── connect_client.dart          # VM Service communication
│   ├── main.dart                     # App entry point and routing
│   ├── screens/
│   │   ├── connection_screen.dart   # Connection UI
│   │   └── connected_layout.dart    # Main layout
│   └── widgets/
│       ├── sidebar.dart              # Database/table navigation
│       ├── table_view.dart           # Data viewer
│       ├── data_grid.dart            # Table renderer
│       └── query_builder.dart        # SQL query interface
├── web/
│   ├── index.html                    # Web entry point
│   └── manifest.json                 # PWA manifest
└── pubspec.yaml
```

### Key Technologies

- **Flutter Web** - Cross-platform UI framework
- **VM Service Protocol** - Dart debugger protocol for app introspection
- **WebSocket** - Real-time bidirectional communication
- **go_router** - Declarative routing
- **Provider** - State management

### Building for Production

```bash
flutter build web --release
```

The built files will be in `build/web/`.

## VM Service Extensions

The inspector expects the following service extensions to be registered:

- `ext.native_sqlite.listDatabases` - List all open databases
- `ext.native_sqlite.getSchema` - Get table schema for a database
- `ext.native_sqlite.executeQuery` - Execute a SELECT query
- `ext.native_sqlite.executeSql` - Execute any SQL statement
- `ext.native_sqlite.updateRecord` - Update a record
- `ext.native_sqlite.deleteRecord` - Delete a record
- `ext.native_sqlite.exportJson` - Export table data to JSON
- `ext.native_sqlite.importJson` - Import JSON data to table

## Event Streaming

The inspector listens for database change events:

- `ext.native_sqlite.data_changed` - Fired when data is modified
- `ext.native_sqlite.schema_changed` - Fired when schema is modified

This enables real-time updates in the inspector UI.

## Troubleshooting

### Connection Issues

**Problem**: Inspector can't connect to the app

**Solutions**:
1. Verify the app is running in debug mode
2. Check the port and token are correct
3. Ensure VM service extensions are registered
4. Try restarting both the app and inspector

### Empty Database List

**Problem**: No databases appear in the inspector

**Solutions**:
1. Verify databases are open in your app
2. Check that service extensions are registered before opening databases
3. Look for errors in the Flutter app console

### Query Execution Fails

**Problem**: SQL queries don't execute

**Solutions**:
1. Check SQL syntax
2. Verify table and column names
3. Ensure the database is not locked
4. Check app console for error messages

## Comparison with Isar Community Inspector

This inspector is inspired by the Isar Community Inspector but adapted for SQLite:

| Feature | Isar Inspector | Native SQLite Inspector |
|---------|---------------|-------------------------|
| Database Type | Isar NoSQL | SQLite (SQL) |
| Schema Inspection | ✅ | ✅ |
| Data Browsing | ✅ | ✅ |
| Query Language | Isar Query | SQL |
| Real-time Updates | ✅ | ✅ |
| JSON Export | ✅ | ✅ |
| Record Editing | ✅ | ✅ |

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Credits

Inspired by [Isar Community Inspector](https://github.com/isar-community/isar-community/tree/v3/packages/isar_community_inspector).

## Support

For issues and questions:
- Open an issue on GitHub
- Check the documentation
- Review the example app

---

Built with ❤️ using Flutter and the Dart VM Service Protocol
