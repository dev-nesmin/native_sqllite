import 'package:flutter/material.dart';
import 'package:native_sqlite_example/models/user.dart';

import '../widgets/glass_app_bar.dart';

/// Example screen demonstrating the type-safe query builder.
class QueryBuilderDemoScreen extends StatefulWidget {
  const QueryBuilderDemoScreen({super.key});

  @override
  State<QueryBuilderDemoScreen> createState() => _QueryBuilderDemoScreenState();
}

class _QueryBuilderDemoScreenState extends State<QueryBuilderDemoScreen> {
  // No need to specify database name anymore! It uses the default from @Table annotation
  final _repository = const UserRepository();
  List<User> _users = [];
  String _queryDescription = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(title: 'Query Builder Demo'),
      body: Column(
        children: [
          const SizedBox(height: kToolbarHeight),
          // Query description
          if (_queryDescription.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Text(
                'Query: $_queryDescription',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),

          // Query buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _queryActiveUsers,
                  child: const Text('Active Users'),
                ),
                ElevatedButton(
                  onPressed: _queryUsersWithAge,
                  child: const Text('Age > 25'),
                ),
                ElevatedButton(
                  onPressed: _queryByNamePattern,
                  child: const Text('Name contains "a"'),
                ),
                ElevatedButton(
                  onPressed: _queryComplexExample,
                  child: const Text('Complex Query'),
                ),
                ElevatedButton(
                  onPressed: _querySortedUsers,
                  child: const Text('Sorted by Name'),
                ),
                ElevatedButton(
                  onPressed: _queryPaginated,
                  child: const Text('First 5 Users'),
                ),
                ElevatedButton(
                  onPressed: _countActiveUsers,
                  child: const Text('Count Active'),
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _users.isEmpty
                ? const Center(child: Text('Run a query to see results'))
                : ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return ListTile(
                        leading: CircleAvatar(child: Text('${user.id}')),
                        title: Text(user.name),
                        subtitle: Text(
                          'Age: ${user.age} | Active: ${user.isActive}',
                        ),
                        trailing: Text(user.email),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Query for active users
  Future<void> _queryActiveUsers() async {
    setState(() => _queryDescription = 'isActive = true');

    final users = await _repository.queryBuilder().isActiveIsTrue().findAll();

    setState(() => _users = users);
  }

  /// Query for users with age > 25
  Future<void> _queryUsersWithAge() async {
    setState(() => _queryDescription = 'age > 25');

    final users = await _repository.queryBuilder().ageGreaterThan(25).findAll();

    setState(() => _users = users);
  }

  /// Query for users with name containing "a"
  Future<void> _queryByNamePattern() async {
    setState(() => _queryDescription = 'name LIKE "%a%"');

    final users = await _repository.queryBuilder().nameContains('a').findAll();

    setState(() => _users = users);
  }

  /// Complex query example
  Future<void> _queryComplexExample() async {
    setState(
      () => _queryDescription =
          'isActive = true AND age BETWEEN 20 AND 40 ORDER BY name ASC LIMIT 10',
    );

    final users = await _repository
        .queryBuilder()
        .isActiveIsTrue()
        .ageBetween(20, 40)
        .sortByNameAsc()
        .limit(10)
        .findAll();

    setState(() => _users = users);
  }

  /// Query with sorting
  Future<void> _querySortedUsers() async {
    setState(() => _queryDescription = 'ORDER BY name ASC');

    final users = await _repository.queryBuilder().sortByNameAsc().findAll();

    setState(() => _users = users);
  }

  /// Query with pagination
  Future<void> _queryPaginated() async {
    setState(() => _queryDescription = 'LIMIT 5');

    final users = await _repository.queryBuilder().limit(5).findAll();

    setState(() => _users = users);
  }

  /// Count active users
  Future<void> _countActiveUsers() async {
    final count = await _repository.queryBuilder().isActiveIsTrue().count();

    setState(() {
      _queryDescription = 'COUNT(*) WHERE isActive = true';
      _users = [];
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Active users: $count')));
    }
  }
}
