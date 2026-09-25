import 'dart:async';

import 'package:flutter/material.dart';

import '../generated/database_manager.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../services/order_demo_service.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/ui_feedback.dart';

const List<OrderStatus> _statusOptions = OrderStatus.values;

String _statusLabel(OrderStatus status) {
  final name = status.name;
  return '${name[0].toUpperCase()}${name.substring(1)}';
}

Color _statusColor(BuildContext context, OrderStatus status) {
  final colors = Theme.of(context).colorScheme;
  switch (status) {
    case OrderStatus.pending:
      return colors.secondary;
    case OrderStatus.processing:
      return colors.primary;
    case OrderStatus.shipped:
      return colors.tertiary;
    case OrderStatus.delivered:
      return colors.primary;
    case OrderStatus.cancelled:
      return colors.error;
  }
}

IconData _statusIcon(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return Icons.schedule;
    case OrderStatus.processing:
      return Icons.autorenew;
    case OrderStatus.shipped:
      return Icons.local_shipping;
    case OrderStatus.delivered:
      return Icons.check_circle;
    case OrderStatus.cancelled:
      return Icons.cancel;
  }
}

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final _orderRepository = OrderRepository(DatabaseManager.currentDatabase);
  final _userRepository = UserRepository(DatabaseManager.currentDatabase);
  final _productRepository = ProductRepository(DatabaseManager.currentDatabase);
  final _orderDemo = OrderDemoService(DatabaseManager.currentDatabase);

  List<Order> _orders = [];
  List<User> _users = [];
  List<Product> _products = [];
  bool _isLoading = false;
  OrderStatus? _filterStatus;
  int _orderCount = 0;
  double _orderTotal = 0;
  Map<OrderStatus, int> _statusCounts = const {};

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _orderRepository.findAll();
      final users = await _userRepository.findAll();
      final products = await _productRepository.findAll();
      final summary = await DatabaseManager.currentDatabase.query(
        'SELECT "${OrderSchema.STATUS}" AS status, COUNT(*) AS count, '
        'COALESCE(SUM("${OrderSchema.TOTAL_PRICE}"), 0) AS total '
        'FROM "${OrderSchema.tableName}" GROUP BY "${OrderSchema.STATUS}"',
      );
      final statusCounts = <OrderStatus, int>{};
      var total = 0.0;
      var count = 0;
      for (final row in summary.toMapList()) {
        final status = OrderStatus.values.byName(row['status'] as String);
        final statusCount = row['count'] as int;
        statusCounts[status] = statusCount;
        count += statusCount;
        total += (row['total'] as num).toDouble();
      }
      setState(() {
        _orders = orders;
        _users = users;
        _products = products;
        _orderCount = count;
        _orderTotal = total;
        _statusCounts = statusCounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error loading data: $e');
    }
  }

  List<Order> get _filteredOrders {
    if (_filterStatus == null) return _orders;
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
      builder: (context) => OrderFormDialog(users: _users, products: _products),
    );

    if (result != null) {
      try {
        final order = Order(
          userId: result['userId'] as int,
          productId: result['productId'] as int,
          quantity: result['quantity'] as int,
          totalPrice: result['totalPrice'] as double,
          status: result['status'] as OrderStatus,
          notes: result['notes'] as String?,
        );
        await _orderDemo.placeOrder(
          userId: order.userId,
          productId: order.productId,
          quantity: order.quantity,
          totalPrice: order.totalPrice,
          status: order.status,
          notes: order.notes,
        );
        _showSuccess('Order created successfully');
        await _loadData();
      } catch (e) {
        _showError('Error creating order: $e');
      }
    }
  }

  Future<void> _updateOrder(Order order) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) =>
          OrderFormDialog(users: _users, products: _products, order: order),
    );

    if (result != null) {
      try {
        final updated = order.copyWith(
          userId: result['userId'] as int,
          productId: result['productId'] as int,
          quantity: result['quantity'] as int,
          totalPrice: result['totalPrice'] as double,
          status: result['status'] as OrderStatus,
          notes: result['notes'] as String?,
          updatedAt: DateTime.now(),
          deliveredAt: result['status'] == OrderStatus.delivered
              ? (order.deliveredAt ?? DateTime.now())
              : order.deliveredAt,
        );
        await _orderRepository.update(updated);
        _showSuccess('Order updated successfully');
        await _loadData();
      } catch (e) {
        _showError('Error updating order: $e');
      }
    }
  }

  Future<void> _updateStatus(Order order, OrderStatus newStatus) async {
    try {
      final updated = order.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
        deliveredAt: newStatus == OrderStatus.delivered
            ? DateTime.now()
            : order.deliveredAt,
      );
      await _orderRepository.update(updated);
      _showSuccess('Status updated to "${newStatus.name}"');
      await _loadData();
    } catch (e) {
      _showError('Error updating status: $e');
    }
  }

  Future<void> _deleteOrder(int id) async {
    final confirmed = await UiFeedback.confirm(
      context,
      title: 'Confirm delete',
      message: 'Are you sure you want to delete this order?',
      confirmLabel: 'Delete',
    );

    if (confirmed) {
      try {
        await _orderRepository.delete(id);
        _showSuccess('Order deleted');
        await _loadData();
      } catch (e) {
        _showError('Error deleting order: $e');
      }
    }
  }

  void _showSuccess(String message) {
    UiFeedback.showMessage(context, message);
  }

  void _showError(String message) {
    UiFeedback.showMessage(context, message, error: true);
  }

  String _userName(int userId) =>
      _users.where((u) => u.id == userId).firstOrNull?.name ?? '#$userId';

  String _productName(int productId) =>
      _products.where((p) => p.id == productId).firstOrNull?.name ??
      '#$productId';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _filterStatus == null
                              ? 'No orders yet.\nTap + to create one.'
                              : 'No "${_statusLabel(_filterStatus!)}" orders.',
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_orderCount Orders',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '\$${_orderTotal.toStringAsFixed(2)} total',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          ...[
            OrderStatus.pending,
            OrderStatus.processing,
            OrderStatus.delivered,
          ].map(
            (s) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Chip(
                avatar: Icon(
                  _statusIcon(s),
                  size: 14,
                  color: _statusColor(context, s),
                ),
                label: Text(
                  '${_statusCounts[s] ?? 0}',
                  style: const TextStyle(fontSize: 12),
                ),
                visualDensity: VisualDensity.compact,
                backgroundColor: _statusColor(
                  context,
                  s,
                ).withValues(alpha: 0.1),
              ),
            ),
          ),
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
          _filterChip(null, 'All'),
          ..._statusOptions.map(
            (status) => _filterChip(status, _statusLabel(status)),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(OrderStatus? value, String label) {
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
    final color = _statusColor(context, order.status);
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
                Text(
                  'Order #${order.id}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusLabel(order.status),
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_productName(order.productId)} × ${order.quantity}'),
                Text('Customer: ${_userName(order.userId)}'),
                if (order.notes != null && order.notes!.isNotEmpty)
                  Text(
                    'Note: ${order.notes}',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
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
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  _formatDate(order.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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
          ...nextStatuses.map(
            (s) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: TextButton.icon(
                onPressed: () => _updateStatus(order, s),
                icon: Icon(_statusIcon(s), size: 14),
                label: Text(
                  _statusLabel(s),
                  style: const TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: _statusColor(context, s),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            tooltip: 'Edit',
            onPressed: () => unawaited(_updateOrder(order)),
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: Icon(
              Icons.delete,
              size: 18,
              color: Theme.of(context).colorScheme.error,
            ),
            tooltip: 'Delete',
            onPressed: () {
              if (order.id != null) unawaited(_deleteOrder(order.id!));
            },
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  List<OrderStatus> _nextStatuses(OrderStatus current) {
    switch (current) {
      case OrderStatus.pending:
        return [OrderStatus.processing, OrderStatus.cancelled];
      case OrderStatus.processing:
        return [OrderStatus.shipped, OrderStatus.cancelled];
      case OrderStatus.shipped:
        return [OrderStatus.delivered];
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
        return [];
    }
  }

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
  OrderStatus _selectedStatus = OrderStatus.pending;
  bool _recalculateTotal = false;
  final _formKey = GlobalKey<FormState>();

  Product? get _selectedProduct =>
      widget.products.where((p) => p.id == _selectedProductId).firstOrNull;

  double get _computedTotal {
    final existing = widget.order;
    if (existing != null && !_recalculateTotal) return existing.totalPrice;
    final qty = int.tryParse(_quantityController.text) ?? 0;
    return (_selectedProduct?.price ?? 0) * qty;
  }

  @override
  void initState() {
    super.initState();
    final o = widget.order;
    _selectedUserId = o == null
        ? widget.users.firstOrNull?.id
        : widget.users.any((user) => user.id == o.userId)
        ? o.userId
        : null;
    _selectedProductId = o == null
        ? widget.products.firstOrNull?.id
        : widget.products.any((product) => product.id == o.productId)
        ? o.productId
        : null;
    _quantityController = TextEditingController(
      text: o?.quantity.toString() ?? '1',
    );
    _notesController = TextEditingController(text: o?.notes);
    _selectedStatus = o?.status ?? OrderStatus.pending;
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
                  labelText: 'Customer',
                  prefixIcon: Icon(Icons.person),
                ),
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
                  prefixIcon: Icon(Icons.shopping_bag),
                ),
                items: widget.products.map((p) {
                  return DropdownMenuItem(
                    value: p.id,
                    child: Text('${p.name} (\$${p.price.toStringAsFixed(2)})'),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedProductId = v),
                validator: (v) => v == null ? 'Select a product' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
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
                    Text(
                      isEdit && !_recalculateTotal
                          ? 'Stored Total Price'
                          : 'Total Price',
                    ),
                    Text(
                      '\$${_computedTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              if (isEdit)
                TextButton(
                  onPressed: () => setState(() => _recalculateTotal = true),
                  child: const Text('Recalculate from current product price'),
                ),
              const SizedBox(height: 8),
              DropdownButtonFormField<OrderStatus>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: _statusOptions.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Row(
                      children: [
                        Icon(
                          _statusIcon(s),
                          size: 16,
                          color: _statusColor(context, s),
                        ),
                        const SizedBox(width: 8),
                        Text(_statusLabel(s)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) =>
                    setState(() => _selectedStatus = v ?? OrderStatus.pending),
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
