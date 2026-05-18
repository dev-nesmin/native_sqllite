import 'package:flutter/material.dart';

import '../models/order.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../widgets/glass_app_bar.dart';

const List<String> _statusOptions = [
  'pending',
  'processing',
  'shipped',
  'delivered',
  'cancelled',
];

Color _statusColor(String status) {
  switch (status) {
    case 'pending':
      return Colors.orange;
    case 'processing':
      return Colors.blue;
    case 'shipped':
      return Colors.indigo;
    case 'delivered':
      return Colors.green;
    case 'cancelled':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

IconData _statusIcon(String status) {
  switch (status) {
    case 'pending':
      return Icons.schedule;
    case 'processing':
      return Icons.autorenew;
    case 'shipped':
      return Icons.local_shipping;
    case 'delivered':
      return Icons.check_circle;
    case 'cancelled':
      return Icons.cancel;
    default:
      return Icons.help_outline;
  }
}

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final _orderRepository = OrderRepository();
  final _userRepository = UserRepository();
  final _productRepository = ProductRepository();

  List<Order> _orders = [];
  List<User> _users = [];
  List<Product> _products = [];
  bool _isLoading = false;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _orderRepository.findAll();
      final users = await _userRepository.findAll();
      final products = await _productRepository.findAll();
      setState(() {
        _orders = orders;
        _users = users;
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error loading data: $e');
    }
  }

  List<Order> get _filteredOrders {
    if (_filterStatus == 'all') return _orders;
    return _orders.where((o) => o.status == _filterStatus).toList();
  }

  Future<void> _addOrder() async {
    if (_users.isEmpty) {
      _showError('No users available. Please add a user first.');
      return;
    }
    if (_products.isEmpty) {
      _showError('No products available. Please add a product first.');
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) =>
          OrderFormDialog(users: _users, products: _products),
    );

    if (result != null) {
      try {
        final order = Order(
          userId: result['userId'] as int,
          productId: result['productId'] as int,
          quantity: result['quantity'] as int,
          totalPrice: result['totalPrice'] as double,
          status: result['status'] as String,
          notes: result['notes'] as String?,
        );
        await _orderRepository.insert(order);
        _showSuccess('Order created successfully');
        _loadData();
      } catch (e) {
        _showError('Error creating order: $e');
      }
    }
  }

  Future<void> _updateOrder(Order order) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => OrderFormDialog(
        users: _users,
        products: _products,
        order: order,
      ),
    );

    if (result != null) {
      try {
        final updated = order.copyWith(
          userId: result['userId'] as int,
          productId: result['productId'] as int,
          quantity: result['quantity'] as int,
          totalPrice: result['totalPrice'] as double,
          status: result['status'] as String,
          notes: result['notes'] as String?,
          updatedAt: DateTime.now(),
          deliveredAt: result['status'] == 'delivered'
              ? (order.deliveredAt ?? DateTime.now())
              : order.deliveredAt,
        );
        await _orderRepository.update(updated);
        _showSuccess('Order updated successfully');
        _loadData();
      } catch (e) {
        _showError('Error updating order: $e');
      }
    }
  }

  Future<void> _updateStatus(Order order, String newStatus) async {
    try {
      final updated = order.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
        deliveredAt: newStatus == 'delivered' ? DateTime.now() : order.deliveredAt,
      );
      await _orderRepository.update(updated);
      _showSuccess('Status updated to "$newStatus"');
      _loadData();
    } catch (e) {
      _showError('Error updating status: $e');
    }
  }

  Future<void> _deleteOrder(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this order?'),
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
        await _orderRepository.delete(id);
        _showSuccess('Order deleted');
        _loadData();
      } catch (e) {
        _showError('Error deleting order: $e');
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

  String _userName(int userId) =>
      _users.where((u) => u.id == userId).firstOrNull?.name ?? '#$userId';

  String _productName(int productId) =>
      _products.where((p) => p.id == productId).firstOrNull?.name ??
      '#$productId';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: 'Order Management',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: kToolbarHeight),
          _buildSummaryBar(),
          _buildStatusFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredOrders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _filterStatus == 'all'
                              ? 'No orders yet.\nTap + to create one.'
                              : 'No "$_filterStatus" orders.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    itemCount: _filteredOrders.length,
                    itemBuilder: (context, index) {
                      return _buildOrderCard(_filteredOrders[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addOrder,
        icon: const Icon(Icons.add),
        label: const Text('New Order'),
      ),
    );
  }

  Widget _buildSummaryBar() {
    final counts = <String, int>{};
    for (final s in _statusOptions) {
      counts[s] = _orders.where((o) => o.status == s).length;
    }
    final total =
        _orders.fold<double>(0, (sum, o) => sum + o.totalPrice);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_orders.length} Orders',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text('\$${total.toStringAsFixed(2)} total',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
          ...['pending', 'processing', 'delivered'].map((s) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Chip(
                  avatar: Icon(_statusIcon(s),
                      size: 14, color: _statusColor(s)),
                  label: Text('${counts[s]}',
                      style: const TextStyle(fontSize: 12)),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: _statusColor(s).withValues(alpha: 0.1),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _filterChip('all', 'All'),
          ..._statusOptions.map((s) => _filterChip(s, _capitalize(s))),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final isSelected = _filterStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (_) => setState(() => _filterStatus = value),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final color = _statusColor(order.status);
    final icon = _statusIcon(order.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            title: Row(
              children: [
                Text('Order #${order.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _capitalize(order.status),
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${_productName(order.productId)} × ${order.quantity}'),
                Text('Customer: ${_userName(order.userId)}'),
                if (order.notes != null && order.notes!.isNotEmpty)
                  Text('Note: ${order.notes}',
                      style: const TextStyle(fontStyle: FontStyle.italic)),
              ],
            ),
            isThreeLine: true,
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${order.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  _formatDate(order.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildOrderActions(order),
        ],
      ),
    );
  }

  Widget _buildOrderActions(Order order) {
    final nextStatuses = _nextStatuses(order.status);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          ...nextStatuses.map((s) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: TextButton.icon(
                  onPressed: () => _updateStatus(order, s),
                  icon: Icon(_statusIcon(s), size: 14),
                  label: Text(_capitalize(s),
                      style: const TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: _statusColor(s),
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              )),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            tooltip: 'Edit',
            onPressed: () => _updateOrder(order),
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
            tooltip: 'Delete',
            onPressed: () {
              if (order.id != null) _deleteOrder(order.id!);
            },
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  List<String> _nextStatuses(String current) {
    switch (current) {
      case 'pending':
        return ['processing', 'cancelled'];
      case 'processing':
        return ['shipped', 'cancelled'];
      case 'shipped':
        return ['delivered'];
      default:
        return [];
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

// ==================== ORDER FORM DIALOG ====================
class OrderFormDialog extends StatefulWidget {
  final List<User> users;
  final List<Product> products;
  final Order? order;

  const OrderFormDialog({
    super.key,
    required this.users,
    required this.products,
    this.order,
  });

  @override
  State<OrderFormDialog> createState() => _OrderFormDialogState();
}

class _OrderFormDialogState extends State<OrderFormDialog> {
  int? _selectedUserId;
  int? _selectedProductId;
  late TextEditingController _quantityController;
  late TextEditingController _notesController;
  String _selectedStatus = 'pending';
  final _formKey = GlobalKey<FormState>();

  Product? get _selectedProduct =>
      widget.products.where((p) => p.id == _selectedProductId).firstOrNull;

  double get _computedTotal {
    final qty = int.tryParse(_quantityController.text) ?? 0;
    return (_selectedProduct?.price ?? 0) * qty;
  }

  @override
  void initState() {
    super.initState();
    final o = widget.order;
    _selectedUserId = o?.userId ?? widget.users.first.id;
    _selectedProductId = o?.productId ?? widget.products.first.id;
    _quantityController =
        TextEditingController(text: o?.quantity.toString() ?? '1');
    _notesController = TextEditingController(text: o?.notes);
    _selectedStatus = o?.status ?? 'pending';
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.order != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Order' : 'New Order'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: _selectedUserId,
                decoration: const InputDecoration(
                    labelText: 'Customer', prefixIcon: Icon(Icons.person)),
                items: widget.users.map((u) {
                  return DropdownMenuItem(value: u.id, child: Text(u.name));
                }).toList(),
                onChanged: (v) => setState(() => _selectedUserId = v),
                validator: (v) => v == null ? 'Select a customer' : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _selectedProductId,
                decoration: const InputDecoration(
                    labelText: 'Product',
                    prefixIcon: Icon(Icons.shopping_bag)),
                items: widget.products.map((p) {
                  return DropdownMenuItem(
                    value: p.id,
                    child: Text('${p.name} (\$${p.price.toStringAsFixed(2)})'),
                  );
                }).toList(),
                onChanged: (v) =>
                    setState(() => _selectedProductId = v),
                validator: (v) => v == null ? 'Select a product' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _quantityController,
                decoration:
                    const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Enter quantity';
                  final qty = int.tryParse(v!);
                  if (qty == null || qty < 1) return 'Must be at least 1';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Price'),
                    Text(
                      '\$${_computedTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: _statusOptions.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Row(
                      children: [
                        Icon(_statusIcon(s),
                            size: 16, color: _statusColor(s)),
                        const SizedBox(width: 8),
                        Text(s[0].toUpperCase() + s.substring(1)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) =>
                    setState(() => _selectedStatus = v ?? 'pending'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                ),
                maxLines: 2,
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
                'userId': _selectedUserId!,
                'productId': _selectedProductId!,
                'quantity': int.parse(_quantityController.text),
                'totalPrice': _computedTotal,
                'status': _selectedStatus,
                'notes': _notesController.text.isEmpty
                    ? null
                    : _notesController.text,
              });
            }
          },
          child: Text(isEdit ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}
