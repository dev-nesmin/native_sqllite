import 'package:flutter/material.dart';
import 'package:native_sqlite/native_sqlite.dart';
import 'models/user.dart';
import 'models/post.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Native SQLite Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const DatabaseExample(),
    );
  }
}

class DatabaseExample extends StatefulWidget {
  const DatabaseExample({super.key});

  @override
  State<DatabaseExample> createState() => _DatabaseExampleState();
}

class _DatabaseExampleState extends State<DatabaseExample> {
  static const _dbName = 'example_db';
  late final UserRepository _userRepo;
  late final PostRepository _postRepo;

  List<User> _users = [];
  List<Post> _posts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    setState(() => _isLoading = true);

    try {
      // Open database with generated schemas
      await NativeSqlite.open(
        config: DatabaseConfig(
          name: _dbName,
          version: 1,
          onCreate: [
            UserSchema.createTableSql,
            PostSchema.createTableSql,
          ],
          enableWAL: true,
          enableForeignKeys: true,
        ),
      );

      // Initialize repositories
      _userRepo = UserRepository(_dbName);
      _postRepo = PostRepository(_dbName);

      // Load initial data
      await _loadData();
    } catch (e) {
      debugPrint('Error initializing database: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadData() async {
    final users = await _userRepo.findAll();
    final posts = await _postRepo.findAll();

    setState(() {
      _users = users;
      _posts = posts;
    });
  }

  Future<void> _addSampleData() async {
    setState(() => _isLoading = true);

    try {
      // Add a user
      final userId = await _userRepo.insert(User(
        name: 'John Doe ${DateTime.now().millisecondsSinceEpoch}',
        email: 'john${DateTime.now().millisecondsSinceEpoch}@example.com',
        age: 30,
        isActive: true,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      ));

      // Add a post for the user
      await _postRepo.insert(Post(
        title: 'My First Post',
        content: 'This is the content of my first post!',
        userId: userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        viewCount: 0,
      ));

      await _loadData();
    } catch (e) {
      debugPrint('Error adding sample data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearData() async {
    setState(() => _isLoading = true);

    try {
      await _postRepo.deleteAll(); // Delete posts first (foreign key)
      await _userRepo.deleteAll();
      await _loadData();
    } catch (e) {
      debugPrint('Error clearing data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Native SQLite Example'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _addSampleData,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Sample Data'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _clearData,
                          icon: const Icon(Icons.delete),
                          label: const Text('Clear All'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Users (${_users.length})',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  ..._users.map((user) => Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(user.name[0].toUpperCase()),
                          ),
                          title: Text(user.name),
                          subtitle: Text(user.email),
                          trailing: Chip(
                            label: Text(user.isActive ? 'Active' : 'Inactive'),
                            backgroundColor:
                                user.isActive ? Colors.green : Colors.grey,
                          ),
                        ),
                      )),
                  const SizedBox(height: 24),
                  Text(
                    'Posts (${_posts.length})',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  ..._posts.map((post) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.article),
                          title: Text(post.title),
                          subtitle: Text(post.content),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.remove_red_eye, size: 16),
                              Text('${post.viewCount}'),
                            ],
                          ),
                        ),
                      )),
                ],
              ),
            ),
    );
  }
}
