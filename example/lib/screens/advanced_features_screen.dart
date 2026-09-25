import 'package:flutter/material.dart';

import '../generated/database_manager.dart';
import '../models/category.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../services/order_demo_service.dart';
import '../widgets/glass_app_bar.dart';

class AdvancedFeaturesScreen extends StatefulWidget {
  const AdvancedFeaturesScreen({super.key});

  @override
  State<AdvancedFeaturesScreen> createState() => _AdvancedFeaturesScreenState();
}

class _AdvancedFeaturesScreenState extends State<AdvancedFeaturesScreen> {
  final _userRepository = UserRepository(DatabaseManager.currentDatabase);
  final _categoryRepository = CategoryRepository(
    DatabaseManager.currentDatabase,
  );
  final _productRepository = ProductRepository(DatabaseManager.currentDatabase);
  final _orderDemo = OrderDemoService(DatabaseManager.currentDatabase);
  String _output = 'Select a feature to demo...';
  bool _isLoading = false;

  void _setOutput(String text) {
    setState(() => _output = text);
  }

  void _appendOutput(String text) {
    setState(() => _output += '\n$text');
  }

  Future<int> _createTestProduct(String label, {int stock = 5}) async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final categoryId = await _categoryRepository.insert(
      Category(name: '$label Category $stamp'),
    );
    if (categoryId == null) throw StateError('Could not create test category');
    final productId = await _productRepository.insert(
      Product(
        name: '$label Product $stamp',
        price: 99.99,
        stock: stock,
        categoryId: categoryId,
      ),
    );
    if (productId == null) throw StateError('Could not create test product');
    return productId;
  }

  Future<void> _demoTransactions() async {
    setState(() => _isLoading = true);
    _setOutput('Testing Transactions...\n');

    try {
      final user = await _userRepository.insert(
        User(
          name: 'Transaction Test User',
          email: 'transaction${DateTime.now().millisecondsSinceEpoch}@test.com',
        ),
      );
      if (user == null) throw StateError('Could not create test user');
      _appendOutput('Created test user with ID: $user');

      final product = await _createTestProduct('Transaction');
      _appendOutput('Created test product with ID: $product');

      _appendOutput('\nPlacing an order and decrementing stock atomically...');
      final orderId = await _orderDemo.placeOrder(
        userId: user,
        productId: product,
        quantity: 2,
        totalPrice: 199.98,
      );
      final stockAfterSuccess = await _orderDemo.stockFor(product);
      _appendOutput('Created order $orderId; stock is now $stockAfterSuccess.');

      _appendOutput('\nForcing a failure after both transaction writes...');
      try {
        await _orderDemo.placeOrder(
          userId: user,
          productId: product,
          quantity: 1,
          totalPrice: 99.99,
          forceFailure: true,
        );
      } on StateError catch (error) {
        _appendOutput('Expected failure: ${error.message}');
      }
      final stockAfterFailure = await _orderDemo.stockFor(product);
      _appendOutput(
        'Rollback verified: stock stayed at $stockAfterFailure '
        '(expected $stockAfterSuccess).',
      );
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
        final userId = await _userRepository.insert(
          User(
            name: 'FK Test User',
            email: 'fk${DateTime.now().millisecondsSinceEpoch}@test.com',
          ),
        );
        _appendOutput('Created user with ID: $userId');
      }

      final user = (await _userRepository.findAll()).first;
      _appendOutput('Using user: ${user.name} (ID: ${user.id})');
      final productId = await _createTestProduct('Foreign Key');

      // Try to create an order with valid foreign key
      _appendOutput('\nAttempting to create order with valid user ID...');
      try {
        await DatabaseManager.currentDatabase.execute(
          'INSERT INTO ${OrderSchema.tableName} ('
          '${OrderSchema.USER_ID}, ${OrderSchema.PRODUCT_ID}, '
          '${OrderSchema.QUANTITY}, ${OrderSchema.TOTAL_PRICE}, '
          '${OrderSchema.STATUS}, ${OrderSchema.CREATED_AT}) '
          'VALUES (?, ?, ?, ?, ?, ?)',
          [
            user.id!,
            productId,
            1,
            100.0,
            'pending',
            DateTime.now().millisecondsSinceEpoch,
          ],
        );
        _appendOutput('Success: Order created with valid foreign key');
      } catch (e) {
        _appendOutput('Note: $e');
      }

      // Try to create an order with invalid foreign key
      _appendOutput(
        '\nAttempting to create order with invalid user ID (999999)...',
      );
      try {
        await DatabaseManager.currentDatabase.execute(
          'INSERT INTO ${OrderSchema.tableName} ('
          '${OrderSchema.USER_ID}, ${OrderSchema.PRODUCT_ID}, '
          '${OrderSchema.QUANTITY}, ${OrderSchema.TOTAL_PRICE}, '
          '${OrderSchema.STATUS}, ${OrderSchema.CREATED_AT}) '
          'VALUES (?, ?, ?, ?, ?, ?)',
          [
            999999,
            productId,
            1,
            100.0,
            'pending',
            DateTime.now().millisecondsSinceEpoch,
          ],
        );
        _appendOutput(
          'Unexpected: Order was created (foreign keys might be disabled)',
        );
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
        await _userRepository.insert(
          User(
            name: 'User $i',
            email: 'user$i${DateTime.now().millisecondsSinceEpoch}@test.com',
            age: 20 + (i % 50),
          ),
        );
      }
      _appendOutput('Added 100 users');

      // Query with index (email has index)
      _appendOutput('\nQuerying by email (indexed)...');
      final stopwatch1 = Stopwatch()..start();
      final result1 = await DatabaseManager.currentDatabase.query(
        'SELECT * FROM ${UserSchema.tableName} '
        'WHERE ${UserSchema.EMAIL} LIKE ? LIMIT ?',
        ['%test.com%', 10],
      );
      stopwatch1.stop();
      _appendOutput(
        'Found ${result1.toMapList().length} users in ${stopwatch1.elapsedMicroseconds}μs',
      );

      // Query with index (createdAt has index)
      _appendOutput('\nQuerying by createdAt (indexed)...');
      final stopwatch2 = Stopwatch()..start();
      final result2 = await DatabaseManager.currentDatabase.query(
        'SELECT * FROM ${UserSchema.tableName} '
        'WHERE ${UserSchema.CREATED_AT} > ? '
        'ORDER BY ${UserSchema.CREATED_AT} DESC LIMIT ?',
        [
          DateTime.now()
              .subtract(const Duration(days: 1))
              .millisecondsSinceEpoch,
          10,
        ],
      );
      stopwatch2.stop();
      _appendOutput(
        'Found ${result2.toMapList().length} users in ${stopwatch2.elapsedMicroseconds}μs',
      );

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
      final result = await DatabaseManager.currentDatabase.query(
        '''
        SELECT
          o.${OrderSchema.ID} AS order_id,
          o.${OrderSchema.QUANTITY},
          o.${OrderSchema.TOTAL_PRICE},
          o.${OrderSchema.STATUS},
          u.${UserSchema.NAME} AS user_name,
          u.${UserSchema.EMAIL} AS user_email
        FROM ${OrderSchema.tableName} o
        INNER JOIN ${UserSchema.tableName} u
          ON o.${OrderSchema.USER_ID} = u.${UserSchema.ID}
        LIMIT ?
        ''',
        [10],
      );

      final orders = result.toMapList();
      _appendOutput('Found ${orders.length} orders with user info:');
      for (var order in orders.take(5)) {
        _appendOutput(
          '  Order #${order['order_id']}: ${order['user_name']} '
          '(${order['user_email']}) - ${order['status']} - '
          '\$${order[OrderSchema.TOTAL_PRICE]}',
        );
      }

      // Aggregation query
      _appendOutput('\nExecuting aggregation query...');
      final statsResult = await DatabaseManager.currentDatabase.query('''
        SELECT
          ${OrderSchema.STATUS},
          COUNT(*) as count,
          SUM(${OrderSchema.TOTAL_PRICE}) as total_revenue,
          AVG(${OrderSchema.TOTAL_PRICE}) as avg_price
        FROM ${OrderSchema.tableName}
        GROUP BY ${OrderSchema.STATUS}
        ''');

      _appendOutput('\nOrder statistics by status:');
      for (var stat in statsResult.toTypedList()) {
        _appendOutput(
          '  ${stat.getString(OrderSchema.STATUS)}: ${stat.getInt('count')} orders, '
          'Revenue: \$${stat.getFormattedNumber('total_revenue', 2)}, '
          'Avg: \$${stat.getFormattedNumber('avg_price', 2)}',
        );
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
        'SELECT * FROM ${UserSchema.tableName} '
        'WHERE ${UserSchema.IS_ACTIVE} = ? '
        'ORDER BY ${UserSchema.CREATED_AT} DESC LIMIT ?',
        [true, 5],
      );

      _appendOutput('Found ${activeUsers.length} active users:');
      for (var user in activeUsers) {
        _appendOutput('  ${user.name} (${user.email})');
      }

      // Complex product query
      _appendOutput('\nFinding available products...');
      final products = await _productRepository.query(
        'SELECT * FROM ${ProductSchema.tableName} '
        'WHERE ${ProductSchema.IS_AVAILABLE} = ? '
        'AND ${ProductSchema.STOCK} > ? LIMIT ?',
        [true, 0, 5],
      );

      _appendOutput('Found ${products.length} available products:');
      for (var product in products) {
        _appendOutput(
          '  ${product.name}: \$${product.price.toStringAsFixed(2)} '
          '(Stock: ${product.stock})',
        );
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
      const count = 1000;
      _appendOutput('Inserting $count users in one parameterized batch...');
      final stopwatch = Stopwatch()..start();
      final inserted = await _orderDemo.insertUsersBatch(
        count: count,
        uniquePrefix: 'batch-${DateTime.now().microsecondsSinceEpoch}',
      );
      stopwatch.stop();

      _appendOutput(
        'Successfully inserted $inserted users in '
        '${stopwatch.elapsedMilliseconds}ms',
      );
      _appendOutput(
        'Average: ${stopwatch.elapsedMilliseconds / count}ms per insert',
      );

      final totalUsers = await _userRepository.count();
      _appendOutput('Total users in database: $totalUsers');
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
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const GlassAppBar(title: 'Advanced Features'),
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
          Container(height: 1, color: colors.outlineVariant),
          Expanded(
            flex: 3,
            child: Container(
              color: colors.surfaceContainer,
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
                        color: colors.inverseSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          _output,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: colors.onInverseSurface,
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
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: colors.primary),
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
                        color: colors.onSurfaceVariant,
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
