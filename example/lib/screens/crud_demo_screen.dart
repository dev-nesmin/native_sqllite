import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/category.dart';
import '../models/product.dart';

class CrudDemoScreen extends StatefulWidget {
  const CrudDemoScreen({super.key});

  @override
  State<CrudDemoScreen> createState() => _CrudDemoScreenState();
}

class _CrudDemoScreenState extends State<CrudDemoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CRUD Operations'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Users', icon: Icon(Icons.person)),
            Tab(text: 'Categories', icon: Icon(Icons.category)),
            Tab(text: 'Products', icon: Icon(Icons.shopping_bag)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          UserCrudTab(),
          CategoryCrudTab(),
          ProductCrudTab(),
        ],
      ),
    );
  }
}

// ==================== USER CRUD TAB ====================
class UserCrudTab extends StatefulWidget {
  const UserCrudTab({super.key});

  @override
  State<UserCrudTab> createState() => _UserCrudTabState();
}

class _UserCrudTabState extends State<UserCrudTab> {
  final _userRepository = UserRepository('example_app');
  List<User> _users = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userRepository.findAll();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error loading users: $e');
    }
  }

  Future<void> _addUser() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const UserFormDialog(),
    );

    if (result != null) {
      try {
        final user = User(
          name: result['name'] as String,
          email: result['email'] as String,
          phoneNumber: result['phoneNumber'] as String?,
          age: result['age'] as int,
        );

        await _userRepository.insert(user);
        _showSuccess('User added successfully');
        _loadUsers();
      } catch (e) {
        _showError('Error adding user: $e');
      }
    }
  }

  Future<void> _updateUser(User user) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => UserFormDialog(user: user),
    );

    if (result != null) {
      try {
        final updatedUser = user.copyWith(
          name: result['name'] as String,
          email: result['email'] as String,
          phoneNumber: result['phoneNumber'] as String?,
          age: result['age'] as int,
          updatedAt: DateTime.now(),
        );

        await _userRepository.update(updatedUser);
        _showSuccess('User updated successfully');
        _loadUsers();
      } catch (e) {
        _showError('Error updating user: $e');
      }
    }
  }

  Future<void> _deleteUser(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _userRepository.delete(id);
        _showSuccess('User deleted successfully');
        _loadUsers();
      } catch (e) {
        _showError('Error deleting user: $e');
      }
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Users: ${_users.length}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addUser,
                icon: const Icon(Icons.add),
                label: const Text('Add User'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _users.isEmpty
                  ? const Center(
                      child: Text(
                        'No users yet.\nTap "Add User" to create one.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(user.name[0].toUpperCase()),
                            ),
                            title: Text(user.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.email),
                                Text('Age: ${user.age} • Active: ${user.isActive}'),
                              ],
                            ),
                            trailing: PopupMenuButton(
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 20),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, size: 20, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _updateUser(user);
                                } else if (value == 'delete' && user.id != null) {
                                  _deleteUser(user.id!);
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

// ==================== USER FORM DIALOG ====================
class UserFormDialog extends StatefulWidget {
  final User? user;

  const UserFormDialog({super.key, this.user});

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _ageController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name);
    _emailController = TextEditingController(text: widget.user?.email);
    _phoneController = TextEditingController(text: widget.user?.phoneNumber);
    _ageController = TextEditingController(text: widget.user?.age.toString() ?? '18');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.user == null ? 'Add User' : 'Edit User'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter an email';
                  if (!value!.contains('@')) return 'Please enter a valid email';
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone (optional)'),
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter age';
                  final age = int.tryParse(value!);
                  if (age == null || age < 1) return 'Please enter valid age';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'name': _nameController.text,
                'email': _emailController.text,
                'phoneNumber': _phoneController.text.isEmpty
                    ? null
                    : _phoneController.text,
                'age': int.parse(_ageController.text),
              });
            }
          },
          child: Text(widget.user == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}

// ==================== CATEGORY CRUD TAB ====================
class CategoryCrudTab extends StatefulWidget {
  const CategoryCrudTab({super.key});

  @override
  State<CategoryCrudTab> createState() => _CategoryCrudTabState();
}

class _CategoryCrudTabState extends State<CategoryCrudTab> {
  final _categoryRepository = CategoryRepository('example_app');
  List<Category> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final categories = await _categoryRepository.findAll();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error loading categories: $e');
    }
  }

  Future<void> _addCategory() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const CategoryFormDialog(),
    );

    if (result != null) {
      try {
        final category = Category(
          name: result['name'] as String,
          description: result['description'] as String?,
        );

        await _categoryRepository.insert(category);
        _showSuccess('Category added successfully');
        _loadCategories();
      } catch (e) {
        _showError('Error adding category: $e');
      }
    }
  }

  Future<void> _deleteCategory(int id) async {
    try {
      await _categoryRepository.delete(id);
      _showSuccess('Category deleted successfully');
      _loadCategories();
    } catch (e) {
      _showError('Error deleting category: $e');
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Categories: ${_categories.length}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addCategory,
                icon: const Icon(Icons.add),
                label: const Text('Add Category'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _categories.isEmpty
                  ? const Center(
                      child: Text(
                        'No categories yet.\nTap "Add Category" to create one.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const Icon(Icons.category),
                            title: Text(category.name),
                            subtitle: category.description != null
                                ? Text(category.description!)
                                : null,
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                if (category.id != null) {
                                  _deleteCategory(category.id!);
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

// ==================== CATEGORY FORM DIALOG ====================
class CategoryFormDialog extends StatefulWidget {
  const CategoryFormDialog({super.key});

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Category'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter a name' : null,
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'name': _nameController.text,
                'description': _descriptionController.text.isEmpty
                    ? null
                    : _descriptionController.text,
              });
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

// ==================== PRODUCT CRUD TAB ====================
class ProductCrudTab extends StatefulWidget {
  const ProductCrudTab({super.key});

  @override
  State<ProductCrudTab> createState() => _ProductCrudTabState();
}

class _ProductCrudTabState extends State<ProductCrudTab> {
  final _productRepository = ProductRepository('example_app');
  final _categoryRepository = CategoryRepository('example_app');
  List<Product> _products = [];
  List<Category> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final products = await _productRepository.findAll();
      final categories = await _categoryRepository.findAll();
      setState(() {
        _products = products;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error loading data: $e');
    }
  }

  Future<void> _addProduct() async {
    if (_categories.isEmpty) {
      _showError('Please create at least one category first');
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ProductFormDialog(categories: _categories),
    );

    if (result != null) {
      try {
        final product = Product(
          name: result['name'] as String,
          description: result['description'] as String?,
          price: result['price'] as double,
          stock: result['stock'] as int,
          categoryId: result['categoryId'] as int,
        );

        await _productRepository.insert(product);
        _showSuccess('Product added successfully');
        _loadData();
      } catch (e) {
        _showError('Error adding product: $e');
      }
    }
  }

  Future<void> _deleteProduct(int id) async {
    try {
      await _productRepository.delete(id);
      _showSuccess('Product deleted successfully');
      _loadData();
    } catch (e) {
      _showError('Error deleting product: $e');
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

  String _getCategoryName(int categoryId) {
    final category = _categories.where((c) => c.id == categoryId).firstOrNull;
    return category?.name ?? 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Products: ${_products.length}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addProduct,
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _products.isEmpty
                  ? const Center(
                      child: Text(
                        'No products yet.\nTap "Add Product" to create one.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        final product = _products[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const Icon(Icons.shopping_bag),
                            title: Text(product.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (product.description != null)
                                  Text(product.description!),
                                Text(
                                  '\$${product.price.toStringAsFixed(2)} • '
                                  'Stock: ${product.stock} • '
                                  'Category: ${_getCategoryName(product.categoryId)}',
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                if (product.id != null) {
                                  _deleteProduct(product.id!);
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

// ==================== PRODUCT FORM DIALOG ====================
class ProductFormDialog extends StatefulWidget {
  final List<Category> categories;

  const ProductFormDialog({super.key, required this.categories});

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  int? _selectedCategoryId;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _stockController = TextEditingController(text: '0');
    _selectedCategoryId = widget.categories.first.id;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Product'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
                maxLines: 2,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter price';
                  final price = double.tryParse(value!);
                  if (price == null || price < 0) return 'Please enter valid price';
                  return null;
                },
              ),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter stock';
                  final stock = int.tryParse(value!);
                  if (stock == null || stock < 0) return 'Please enter valid stock';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: widget.categories.map((category) {
                  return DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategoryId = value);
                },
                validator: (value) =>
                    value == null ? 'Please select a category' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'name': _nameController.text,
                'description': _descriptionController.text.isEmpty
                    ? null
                    : _descriptionController.text,
                'price': double.parse(_priceController.text),
                'stock': int.parse(_stockController.text),
                'categoryId': _selectedCategoryId!,
              });
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
