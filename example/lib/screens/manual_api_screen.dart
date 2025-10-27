import 'package:flutter/material.dart';
import 'package:native_sqlite/native_sqlite.dart';

/// Demonstrates using the Native SQLite API directly without code generation
class ManualApiScreen extends StatefulWidget {
  const ManualApiScreen({super.key});

  @override
  State<ManualApiScreen> createState() => _ManualApiScreenState();
}

class _ManualApiScreenState extends State<ManualApiScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  List<Map<String, Object?>> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final result = await NativeSqlite.query(
        'example_app',
        'SELECT * FROM users ORDER BY createdAt DESC LIMIT 20',
        [],
      );
      setState(() {
        _items = result.toMapList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error loading items: $e');
    }
  }

  Future<void> _insertItem() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    try {
      // Using manual insert API
      final id = await NativeSqlite.insert(
        'example_app',
        'users',
        {
          'name': _nameController.text,
          'email': _emailController.text,
          'age': 25,
          'isActive': 1,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        },
      );

      _showSuccess('User inserted with ID: $id');
      _nameController.clear();
      _emailController.clear();
      _loadItems();
    } catch (e) {
      _showError('Error inserting: $e');
    }
  }

  Future<void> _updateItem(int id, String name) async {
    try {
      final rowsAffected = await NativeSqlite.update(
        'example_app',
        'users',
        {
          'name': '$name (Updated)',
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      _showSuccess('Updated $rowsAffected row(s)');
      _loadItems();
    } catch (e) {
      _showError('Error updating: $e');
    }
  }

  Future<void> _deleteItem(int id) async {
    try {
      final rowsAffected = await NativeSqlite.delete(
        'example_app',
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );

      _showSuccess('Deleted $rowsAffected row(s)');
      _loadItems();
    } catch (e) {
      _showError('Error deleting: $e');
    }
  }

  Future<void> _executeCustomQuery() async {
    try {
      final result = await NativeSqlite.query(
        'example_app',
        'SELECT COUNT(*) as count, AVG(age) as avg_age FROM users',
        [],
      );

      final data = result.toMapList().first;
      _showSuccess(
          'Total users: ${data['count']}, Average age: ${(data['avg_age'] ?? 0).toStringAsFixed(1)}');
    } catch (e) {
      _showError('Error executing query: $e');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual API Demo'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadItems,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildInfoCard(),
          _buildInputForm(),
          _buildActionButtons(),
          const Divider(height: 1),
          _buildDataList(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'This screen uses the Native SQLite API directly without code generation',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _insertItem,
              icon: const Icon(Icons.add),
              label: const Text('Insert'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _executeCustomQuery,
              icon: const Icon(Icons.analytics),
              label: const Text('Stats Query'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataList() {
    return Expanded(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Text(
                    'No data yet.\nInsert some items to see them here.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final id = item['id'] as int;
                    final name = item['name'] as String;
                    final email = item['email'] as String;
                    final age = item['age'] as int;
                    final createdAt = DateTime.fromMillisecondsSinceEpoch(
                      item['createdAt'] as int,
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(child: Text('$id')),
                        title: Text(name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(email),
                            Text(
                              'Age: $age • Created: ${createdAt.toString().substring(0, 16)}',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _updateItem(id, name),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                              onPressed: () => _deleteItem(id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
