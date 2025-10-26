import 'package:flutter/material.dart';
import 'package:native_sqlite/native_sqlite.dart';
import '../models/user.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/order.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final _userRepository = UserRepository('example_app');
  final _categoryRepository = CategoryRepository('example_app');
  final _productRepository = ProductRepository('example_app');
  final _orderRepository = OrderRepository('example_app');

  int _userCount = 0;
  int _categoryCount = 0;
  int _productCount = 0;
  int _orderCount = 0;
  String _dbPath = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _userRepository.count(),
        _categoryRepository.count(),
        _productRepository.count(),
        _orderRepository.count(),
        NativeSqlite.getDatabasePath('example_app'),
      ]);

      setState(() {
        _userCount = results[0] as int;
        _categoryCount = results[1] as int;
        _productCount = results[2] as int;
        _orderCount = results[3] as int;
        _dbPath = results[4] as String;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error loading statistics: $e');
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will delete ALL data from ALL tables. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _orderRepository.deleteAll();
        await _productRepository.deleteAll();
        await _categoryRepository.deleteAll();
        await _userRepository.deleteAll();

        _showSuccess('All data cleared successfully');
        _loadStatistics();
      } catch (e) {
        _showError('Error clearing data: $e');
      }
    }
  }

  Future<void> _generateSampleData() async {
    try {
      // Create categories
      final electronicsId = await _categoryRepository.insert(
        Category(name: 'Electronics', description: 'Electronic devices'),
      );
      final clothingId = await _categoryRepository.insert(
        Category(name: 'Clothing', description: 'Apparel and accessories'),
      );
      final booksId = await _categoryRepository.insert(
        Category(name: 'Books', description: 'Books and magazines'),
      );

      // Create users
      final user1Id = await _userRepository.insert(
        User(name: 'Alice Johnson', email: 'alice@example.com', age: 28),
      );
      final user2Id = await _userRepository.insert(
        User(name: 'Bob Smith', email: 'bob@example.com', age: 35),
      );
      final user3Id = await _userRepository.insert(
        User(name: 'Carol Davis', email: 'carol@example.com', age: 42),
      );

      // Create products
      final laptop = await _productRepository.insert(
        Product(
          name: 'Gaming Laptop',
          description: 'High-performance laptop',
          price: 1299.99,
          stock: 5,
          categoryId: electronicsId,
        ),
      );
      final phone = await _productRepository.insert(
        Product(
          name: 'Smartphone',
          description: 'Latest model',
          price: 899.99,
          stock: 10,
          categoryId: electronicsId,
        ),
      );
      final shirt = await _productRepository.insert(
        Product(
          name: 'T-Shirt',
          description: 'Cotton t-shirt',
          price: 19.99,
          stock: 50,
          categoryId: clothingId,
        ),
      );
      final book = await _productRepository.insert(
        Product(
          name: 'Programming Book',
          description: 'Learn Flutter',
          price: 39.99,
          stock: 20,
          categoryId: booksId,
        ),
      );

      // Create orders
      await _orderRepository.insert(
        Order(
          userId: user1Id,
          productId: laptop,
          quantity: 1,
          totalPrice: 1299.99,
          status: 'delivered',
        ),
      );
      await _orderRepository.insert(
        Order(
          userId: user2Id,
          productId: phone,
          quantity: 2,
          totalPrice: 1799.98,
          status: 'processing',
        ),
      );
      await _orderRepository.insert(
        Order(
          userId: user3Id,
          productId: shirt,
          quantity: 3,
          totalPrice: 59.97,
          status: 'pending',
        ),
      );
      await _orderRepository.insert(
        Order(
          userId: user1Id,
          productId: book,
          quantity: 1,
          totalPrice: 39.99,
          status: 'delivered',
        ),
      );

      _showSuccess('Sample data generated successfully');
      _loadStatistics();
    } catch (e) {
      _showError('Error generating sample data: $e');
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
        title: const Text('Database Statistics'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDatabaseInfoCard(),
                  const SizedBox(height: 16),
                  _buildStatisticsGrid(),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                  const SizedBox(height: 16),
                  _buildSchemaInfo(),
                ],
              ),
            ),
    );
  }

  Widget _buildDatabaseInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.storage, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Database Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Database Name', 'example_app'),
            _buildInfoRow('Version', '1'),
            _buildInfoRow('Path', _dbPath, isPath: true),
            _buildInfoRow('WAL Mode', 'Enabled'),
            _buildInfoRow('Foreign Keys', 'Enabled'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isPath = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: isPath ? 'monospace' : null,
                fontSize: isPath ? 11 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Users',
                _userCount,
                Icons.person,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Categories',
                _categoryCount,
                Icons.category,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Products',
                _productCount,
                Icons.shopping_bag,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Orders',
                _orderCount,
                Icons.receipt,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, int count, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _generateSampleData,
          icon: const Icon(Icons.add_circle),
          label: const Text('Generate Sample Data'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _clearAllData,
          icon: const Icon(Icons.delete_sweep, color: Colors.red),
          label: const Text('Clear All Data', style: TextStyle(color: Colors.red)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: const BorderSide(color: Colors.red),
          ),
        ),
      ],
    );
  }

  Widget _buildSchemaInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.schema, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Database Schema',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTableInfo('users', [
              'id (PRIMARY KEY, AUTO INCREMENT)',
              'name (TEXT, NOT NULL)',
              'email (TEXT, UNIQUE, NOT NULL)',
              'phoneNumber (TEXT)',
              'address (TEXT)',
              'age (INTEGER, DEFAULT 1)',
              'isActive (INTEGER, DEFAULT 1)',
              'createdAt (INTEGER, NOT NULL)',
              'updatedAt (INTEGER)',
            ], [
              'INDEX: email',
              'INDEX: createdAt',
            ]),
            const Divider(),
            _buildTableInfo('categories', [
              'id (PRIMARY KEY, AUTO INCREMENT)',
              'name (TEXT, UNIQUE, NOT NULL)',
              'description (TEXT)',
              'createdAt (INTEGER, NOT NULL)',
            ]),
            const Divider(),
            _buildTableInfo('products', [
              'id (PRIMARY KEY, AUTO INCREMENT)',
              'name (TEXT, NOT NULL)',
              'description (TEXT)',
              'price (REAL, NOT NULL)',
              'stock (INTEGER, DEFAULT 0)',
              'isAvailable (INTEGER, DEFAULT 1)',
              'categoryId (INTEGER, NOT NULL, FK → categories.id)',
              'imageUrl (TEXT)',
              'createdAt (INTEGER, NOT NULL)',
              'updatedAt (INTEGER)',
            ], [
              'INDEX: categoryId, price',
              'INDEX: name',
              'FOREIGN KEY: categoryId → categories(id) ON DELETE CASCADE',
            ]),
            const Divider(),
            _buildTableInfo('orders', [
              'id (PRIMARY KEY, AUTO INCREMENT)',
              'userId (INTEGER, NOT NULL, FK → users.id)',
              'productId (INTEGER, NOT NULL, FK → products.id)',
              'quantity (INTEGER, NOT NULL)',
              'totalPrice (REAL, NOT NULL)',
              'status (TEXT, DEFAULT "pending")',
              'notes (TEXT)',
              'createdAt (INTEGER, NOT NULL)',
              'updatedAt (INTEGER)',
              'deliveredAt (INTEGER)',
            ], [
              'INDEX: userId, createdAt',
              'INDEX: status',
              'FOREIGN KEY: userId → users(id) ON DELETE CASCADE',
              'FOREIGN KEY: productId → products(id) ON DELETE CASCADE',
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildTableInfo(String tableName, List<String> columns,
      [List<String>? indexes]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tableName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 8),
        ...columns.map((col) => Padding(
              padding: const EdgeInsets.only(left: 16, top: 2),
              child: Text(
                '• $col',
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            )),
        if (indexes != null && indexes.isNotEmpty) ...[
          const SizedBox(height: 4),
          ...indexes.map((idx) => Padding(
                padding: const EdgeInsets.only(left: 16, top: 2),
                child: Text(
                  '• $idx',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Colors.blue[700],
                  ),
                ),
              )),
        ],
      ],
    );
  }
}
