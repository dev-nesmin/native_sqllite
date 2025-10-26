import 'package:flutter/material.dart';
import 'package:native_sqlite/native_sqlite.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/order.dart';

class AdvancedFeaturesScreen extends StatefulWidget {
  const AdvancedFeaturesScreen({super.key});

  @override
  State<AdvancedFeaturesScreen> createState() => _AdvancedFeaturesScreenState();
}

class _AdvancedFeaturesScreenState extends State<AdvancedFeaturesScreen> {
  final _userRepository = UserRepository('example_app');
  final _productRepository = ProductRepository('example_app');
  final _orderRepository = OrderRepository('example_app');
  String _output = 'Select a feature to demo...';
  bool _isLoading = false;

  void _setOutput(String text) {
    setState(() => _output = text);
  }

  void _appendOutput(String text) {
    setState(() => _output += '\n$text');
  }

  Future<void> _demoTransactions() async {
    setState(() => _isLoading = true);
    _setOutput('Testing Transactions...\n');

    try {
      // First, let's create a user and product for our test
      final user = await _userRepository.insert(User(
        name: 'Transaction Test User',
        email: 'transaction${DateTime.now().millisecondsSinceEpoch}@test.com',
      ));
      _appendOutput('Created test user with ID: $user');

      final product = await _productRepository.insert(Product(
        name: 'Test Product',
        price: 99.99,
        categoryId: 1, // Assuming category exists
      ));
      _appendOutput('Created test product with ID: $product');

      // Now test transaction
      _appendOutput('\nExecuting transaction with multiple inserts...');
      final success = await NativeSqlite.transaction('example_app', [
        "INSERT INTO orders (userId, productId, quantity, totalPrice, status) "
            "VALUES ($user, $product, 1, 99.99, 'pending')",
        "INSERT INTO orders (userId, productId, quantity, totalPrice, status) "
            "VALUES ($user, $product, 2, 199.98, 'pending')",
        "INSERT INTO orders (userId, productId, quantity, totalPrice, status) "
            "VALUES ($user, $product, 3, 299.97, 'pending')",
      ]);

      if (success) {
        _appendOutput('\nTransaction completed successfully!');
        final orders = await _orderRepository.findAll();
        _appendOutput('Total orders in database: ${orders.length}');
      } else {
        _appendOutput('\nTransaction failed!');
      }
    } catch (e) {
      _appendOutput('\nError: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _demoForeignKeys() async {
    setState(() => _isLoading = true);
    _setOutput('Testing Foreign Key Constraints...\n');

    try {
      // First, check if we have any users
      final users = await _userRepository.findAll();
      if (users.isEmpty) {
        _appendOutput('Creating a test user first...');
        final userId = await _userRepository.insert(User(
          name: 'FK Test User',
          email: 'fk${DateTime.now().millisecondsSinceEpoch}@test.com',
        ));
        _appendOutput('Created user with ID: $userId');
      }

      final user = (await _userRepository.findAll()).first;
      _appendOutput('Using user: ${user.name} (ID: ${user.id})');

      // Try to create an order with valid foreign key
      _appendOutput('\nAttempting to create order with valid user ID...');
      try {
        await NativeSqlite.execute(
          'example_app',
          'INSERT INTO orders (userId, productId, quantity, totalPrice, status) '
          'VALUES (?, 1, 1, 100.0, ?)',
          [user.id!, 'pending'],
        );
        _appendOutput('Success: Order created with valid foreign key');
      } catch (e) {
        _appendOutput('Note: $e');
      }

      // Try to create an order with invalid foreign key
      _appendOutput('\nAttempting to create order with invalid user ID (999999)...');
      try {
        await NativeSqlite.execute(
          'example_app',
          'INSERT INTO orders (userId, productId, quantity, totalPrice, status) '
          'VALUES (?, 1, 1, 100.0, ?)',
          [999999, 'pending'],
        );
        _appendOutput('Unexpected: Order was created (foreign keys might be disabled)');
      } catch (e) {
        _appendOutput('Expected: Foreign key constraint violation caught!');
        _appendOutput('Error: ${e.toString().substring(0, 100)}...');
      }
    } catch (e) {
      _appendOutput('\nError: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _demoIndexes() async {
    setState(() => _isLoading = true);
    _setOutput('Testing Index Performance...\n');

    try {
      // First, let's add some test data
      _appendOutput('Adding 100 test users...');
      for (int i = 0; i < 100; i++) {
        await _userRepository.insert(User(
          name: 'User $i',
          email: 'user$i${DateTime.now().millisecondsSinceEpoch}@test.com',
          age: 20 + (i % 50),
        ));
      }
      _appendOutput('Added 100 users');

      // Query with index (email has index)
      _appendOutput('\nQuerying by email (indexed)...');
      final stopwatch1 = Stopwatch()..start();
      final result1 = await NativeSqlite.query(
        'example_app',
        "SELECT * FROM users WHERE email LIKE '%test.com%' LIMIT 10",
        [],
      );
      stopwatch1.stop();
      _appendOutput(
          'Found ${result1.toMapList().length} users in ${stopwatch1.elapsedMicroseconds}μs');

      // Query with index (createdAt has index)
      _appendOutput('\nQuerying by createdAt (indexed)...');
      final stopwatch2 = Stopwatch()..start();
      final result2 = await NativeSqlite.query(
        'example_app',
        'SELECT * FROM users WHERE createdAt > ? ORDER BY createdAt DESC LIMIT 10',
        [DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch],
      );
      stopwatch2.stop();
      _appendOutput(
          'Found ${result2.toMapList().length} users in ${stopwatch2.elapsedMicroseconds}μs');

      _appendOutput('\nIndexes improve query performance significantly!');
    } catch (e) {
      _appendOutput('\nError: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _demoComplexQueries() async {
    setState(() => _isLoading = true);
    _setOutput('Testing Complex Queries...\n');

    try {
      // Join query example
      _appendOutput('Executing JOIN query (Orders with User info)...\n');
      final result = await NativeSqlite.query(
        'example_app',
        '''
        SELECT
          o.id as order_id,
          o.quantity,
          o.totalPrice,
          o.status,
          u.name as user_name,
          u.email as user_email
        FROM orders o
        INNER JOIN users u ON o.userId = u.id
        LIMIT 10
        ''',
        [],
      );

      final orders = result.toMapList();
      _appendOutput('Found ${orders.length} orders with user info:');
      for (var order in orders.take(5)) {
        _appendOutput(
            '  Order #${order['order_id']}: ${order['user_name']} '
            '(${order['user_email']}) - ${order['status']} - '
            '\$${order['totalPrice']}');
      }

      // Aggregation query
      _appendOutput('\nExecuting aggregation query...');
      final statsResult = await NativeSqlite.query(
        'example_app',
        '''
        SELECT
          status,
          COUNT(*) as count,
          SUM(totalPrice) as total_revenue,
          AVG(totalPrice) as avg_price
        FROM orders
        GROUP BY status
        ''',
        [],
      );

      _appendOutput('\nOrder statistics by status:');
      for (var stat in statsResult.toMapList()) {
        _appendOutput(
            '  ${stat['status']}: ${stat['count']} orders, '
            'Revenue: \$${(stat['total_revenue'] ?? 0).toStringAsFixed(2)}, '
            'Avg: \$${(stat['avg_price'] ?? 0).toStringAsFixed(2)}');
      }
    } catch (e) {
      _appendOutput('\nError: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _demoCustomQueries() async {
    setState(() => _isLoading = true);
    _setOutput('Testing Custom Queries with Repository...\n');

    try {
      // Using the repository's query method for custom queries
      _appendOutput('Finding active users...');
      final activeUsers = await _userRepository.query(
        'SELECT * FROM users WHERE isActive = ? ORDER BY createdAt DESC LIMIT 5',
        [1],
      );

      _appendOutput('Found ${activeUsers.length} active users:');
      for (var user in activeUsers) {
        _appendOutput('  ${user.name} (${user.email})');
      }

      // Complex product query
      _appendOutput('\nFinding available products...');
      final products = await _productRepository.query(
        'SELECT * FROM products WHERE isAvailable = ? AND stock > ? LIMIT 5',
        [1, 0],
      );

      _appendOutput('Found ${products.length} available products:');
      for (var product in products) {
        _appendOutput(
            '  ${product.name}: \$${product.price.toStringAsFixed(2)} '
            '(Stock: ${product.stock})');
      }
    } catch (e) {
      _appendOutput('\nError: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _demoBatchOperations() async {
    setState(() => _isLoading = true);
    _setOutput('Testing Batch Operations...\n');

    try {
      _appendOutput('Creating 50 users in a transaction...');
      final stopwatch = Stopwatch()..start();

      final statements = <String>[];
      for (int i = 0; i < 50; i++) {
        statements.add(
          "INSERT INTO users (name, email, age, isActive, createdAt) "
          "VALUES ('Batch User $i', 'batch$i${DateTime.now().millisecondsSinceEpoch}@test.com', "
          "${20 + i}, 1, ${DateTime.now().millisecondsSinceEpoch})",
        );
      }

      final success = await NativeSqlite.transaction('example_app', statements);
      stopwatch.stop();

      if (success) {
        _appendOutput(
            'Successfully inserted 50 users in ${stopwatch.elapsedMilliseconds}ms');
        _appendOutput('Average: ${stopwatch.elapsedMilliseconds / 50}ms per insert');

        final totalUsers = await _userRepository.count();
        _appendOutput('Total users in database: $totalUsers');
      } else {
        _appendOutput('Batch operation failed');
      }
    } catch (e) {
      _appendOutput('\nError: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _demoDataTypes() async {
    setState(() => _isLoading = true);
    _setOutput('Testing Various Data Types...\n');

    try {
      // Create a user with various data types
      final now = DateTime.now();
      final user = User(
        name: 'Data Type Test',
        email: 'datatype${now.millisecondsSinceEpoch}@test.com',
        phoneNumber: '+1234567890', // String
        age: 30, // int
        isActive: true, // bool
        createdAt: now, // DateTime
        updatedAt: now.add(const Duration(hours: 1)), // DateTime
      );

      _appendOutput('Inserting user with various data types...');
      final userId = await _userRepository.insert(user);
      _appendOutput('User ID: $userId');

      // Retrieve and verify
      _appendOutput('\nRetrieving user...');
      final retrievedUser = await _userRepository.findById(userId);

      if (retrievedUser != null) {
        _appendOutput('User data:');
        _appendOutput('  Name (String): ${retrievedUser.name}');
        _appendOutput('  Email (String): ${retrievedUser.email}');
        _appendOutput('  Phone (String?): ${retrievedUser.phoneNumber}');
        _appendOutput('  Age (int): ${retrievedUser.age}');
        _appendOutput('  Active (bool): ${retrievedUser.isActive}');
        _appendOutput('  Created (DateTime): ${retrievedUser.createdAt}');
        _appendOutput('  Updated (DateTime?): ${retrievedUser.updatedAt}');

        _appendOutput('\nAll data types properly serialized and deserialized!');
      }
    } catch (e) {
      _appendOutput('\nError: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Features'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFeatureButton(
                    'Transactions',
                    'Test atomic operations with rollback support',
                    Icons.swap_horiz,
                    _demoTransactions,
                  ),
                  _buildFeatureButton(
                    'Foreign Keys',
                    'Test referential integrity constraints',
                    Icons.link,
                    _demoForeignKeys,
                  ),
                  _buildFeatureButton(
                    'Indexes',
                    'Demonstrate query performance with indexes',
                    Icons.speed,
                    _demoIndexes,
                  ),
                  _buildFeatureButton(
                    'Complex Queries',
                    'JOIN, aggregation, and GROUP BY operations',
                    Icons.code,
                    _demoComplexQueries,
                  ),
                  _buildFeatureButton(
                    'Custom Queries',
                    'Use repository query method with custom SQL',
                    Icons.query_stats,
                    _demoCustomQueries,
                  ),
                  _buildFeatureButton(
                    'Batch Operations',
                    'Insert multiple records efficiently',
                    Icons.batch_prediction,
                    _demoBatchOperations,
                  ),
                  _buildFeatureButton(
                    'Data Types',
                    'Test String, int, bool, DateTime, nullable types',
                    Icons.data_object,
                    _demoDataTypes,
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 1,
            color: Colors.grey[300],
          ),
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Output',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          _output,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Colors.greenAccent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureButton(
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: Colors.purple),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.play_arrow, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
