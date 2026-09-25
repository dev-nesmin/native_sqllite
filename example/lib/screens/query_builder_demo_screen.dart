import 'package:flutter/material.dart';
import 'package:native_sqlite_example/models/order.dart';
import 'package:native_sqlite_example/models/user.dart';

import '../generated/database_manager.dart';
import '../widgets/async_view.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/ui_feedback.dart';

typedef _ConfigureQuery = UserQueryBuilder Function(UserQueryBuilder query);

class _QueryExample {
  const _QueryExample(this.label, this.description, this.configure);

  final String label;
  final String description;
  final _ConfigureQuery configure;
}

final List<_QueryExample> _filterExamples = [
  _QueryExample('No filter', 'All rows', (query) => query),
  _QueryExample(
    'EqualTo',
    'nameEqualTo("Alice")',
    (query) => query.nameEqualTo('Alice'),
  ),
  _QueryExample(
    'GreaterThan',
    'ageGreaterThan(25)',
    (query) => query.ageGreaterThan(25),
  ),
  _QueryExample(
    'LessThan',
    'ageLessThan(40)',
    (query) => query.ageLessThan(40),
  ),
  _QueryExample(
    'Between',
    'ageBetween(20, 40)',
    (query) => query.ageBetween(20, 40),
  ),
  _QueryExample(
    'Contains',
    'nameContains("a")',
    (query) => query.nameContains('a'),
  ),
  _QueryExample(
    'StartsWith',
    'emailStartsWith("alice")',
    (query) => query.emailStartsWith('alice'),
  ),
  _QueryExample(
    'EndsWith',
    'emailEndsWith("example.com")',
    (query) => query.emailEndsWith('example.com'),
  ),
  _QueryExample(
    'IsNull',
    'phoneNumberIsNull()',
    (query) => query.phoneNumberIsNull(),
  ),
  _QueryExample(
    'IsNotNull',
    'phoneNumberIsNotNull()',
    (query) => query.phoneNumberIsNotNull(),
  ),
  _QueryExample(
    'IsTrue',
    'isActiveIsTrue()',
    (query) => query.isActiveIsTrue(),
  ),
  _QueryExample(
    'IsFalse',
    'isActiveIsFalse()',
    (query) => query.isActiveIsFalse(),
  ),
  _QueryExample(
    'DateTime EqualTo',
    'createdAtEqualTo(2024-01-15)',
    (query) => query.createdAtEqualTo(DateTime.utc(2024, 1, 15)),
  ),
  _QueryExample(
    'DateTime After',
    'createdAtAfter(2024-01-01)',
    (query) => query.createdAtAfter(DateTime.utc(2024)),
  ),
  _QueryExample(
    'DateTime Before',
    'createdAtBefore(2025-01-01)',
    (query) => query.createdAtBefore(DateTime.utc(2025)),
  ),
  _QueryExample(
    'DateTime Between',
    'createdAtBetween(2024-01-01, 2024-12-31)',
    (query) => query.createdAtBetween(
      DateTime.utc(2024),
      DateTime.utc(2024, 12, 31, 23, 59, 59),
    ),
  ),
  _QueryExample(
    'Combined AND',
    'isActiveIsTrue().ageBetween(20, 40)',
    (query) => query.isActiveIsTrue().ageBetween(20, 40),
  ),
];

final List<_QueryExample> _sortExamples = [
  _QueryExample('No sorting', 'Database order', (query) => query),
  _QueryExample(
    'Name ascending',
    'sortByNameAsc()',
    (query) => query.sortByNameAsc(),
  ),
  _QueryExample(
    'Name descending',
    'sortByNameDesc()',
    (query) => query.sortByNameDesc(),
  ),
  _QueryExample(
    'Age, then name',
    'sortByAgeAsc().thenByNameAsc()',
    (query) => query.sortByAgeAsc().thenByNameAsc(),
  ),
  _QueryExample(
    'Newest first',
    'sortByCreatedAtDesc()',
    (query) => query.sortByCreatedAtDesc(),
  ),
];

/// Interactive playground for the generated, type-safe [UserQueryBuilder].
class QueryBuilderDemoScreen extends StatefulWidget {
  const QueryBuilderDemoScreen({super.key});

  @override
  State<QueryBuilderDemoScreen> createState() => _QueryBuilderDemoScreenState();
}

class _QueryBuilderDemoScreenState extends State<QueryBuilderDemoScreen> {
  final _limitController = TextEditingController(text: '10');
  final _offsetController = TextEditingController(text: '0');

  int _filterIndex = 0;
  int _sortIndex = 0;
  OrderStatus _orderStatus = OrderStatus.pending;
  bool _loading = false;
  bool _hasRun = false;
  Object? _error;
  List<User> _users = const [];
  String _sql = '';
  List<Object?> _arguments = const [];
  String _resultSummary = 'Choose a query, then run it.';

  @override
  void initState() {
    super.initState();
    _updatePreview();
  }

  @override
  void dispose() {
    _limitController.dispose();
    _offsetController.dispose();
    super.dispose();
  }

  UserQueryBuilder _buildQuery() {
    var query = UserQueryBuilder(DatabaseManager.currentDatabase);
    query = _filterExamples[_filterIndex].configure(query);
    query = _sortExamples[_sortIndex].configure(query);

    final limitText = _limitController.text.trim();
    final offsetText = _offsetController.text.trim();
    if (limitText.isNotEmpty) query.limit(int.parse(limitText));
    if (offsetText.isNotEmpty) query.offset(int.parse(offsetText));
    return query;
  }

  void _updatePreview() {
    try {
      final query = _buildQuery();
      _sql = query.toSql();
      _arguments = query.arguments;
      _error = null;
    } on FormatException {
      _error = const FormatException('Limit and offset must be whole numbers.');
    } on ArgumentError catch (error) {
      _error = error;
    }
  }

  void _configurationChanged() {
    setState(() {
      _hasRun = false;
      _users = const [];
      _resultSummary = 'Query changed. Run it to refresh the results.';
      _updatePreview();
    });
  }

  Future<void> _findAll() async {
    await _runQuery((query) async {
      final users = await query.findAll();
      return (users, 'findAll returned ${users.length} row(s).');
    });
  }

  Future<void> _findFirst() async {
    await _runQuery((query) async {
      final user = await query.findFirst();
      return (
        user == null ? <User>[] : <User>[user],
        user == null ? 'findFirst returned null.' : 'findFirst returned 1 row.',
      );
    });
  }

  Future<void> _count() async {
    await _runQuery((query) async {
      final count = await query.count();
      return (<User>[], 'count returned $count.');
    });
  }

  Future<void> _deleteAll() async {
    final confirmed = await UiFeedback.confirm(
      context,
      title: 'Delete matching users?',
      message:
          'This runs deleteAll using the current filters. Sorting and pagination '
          'do not limit rows deleted.',
      confirmLabel: 'Delete rows',
    );
    if (!confirmed || !mounted) return;

    await _runQuery((query) async {
      final count = await query.deleteAll();
      return (<User>[], 'deleteAll removed $count row(s).');
    });
  }

  Future<void> _countOrdersByStatus() async {
    final query = OrderQueryBuilder(
      DatabaseManager.currentDatabase,
    ).statusEqualTo(_orderStatus);
    try {
      final count = await query.count();
      if (!mounted) return;
      UiFeedback.showMessage(
        context,
        '${_orderStatus.name}: $count matching order(s).',
      );
    } on Object catch (error) {
      if (!mounted) return;
      UiFeedback.showMessage(context, error.toString(), error: true);
    }
  }

  Future<void> _runQuery(
    Future<(List<User>, String)> Function(UserQueryBuilder query) action,
  ) async {
    setState(() {
      _loading = true;
      _error = null;
      _hasRun = true;
    });

    try {
      final query = _buildQuery();
      final sql = query.toSql();
      final arguments = query.arguments;
      final (users, summary) = await action(query);
      if (!mounted) return;
      setState(() {
        _users = users;
        _resultSummary = summary;
        _sql = sql;
        _arguments = arguments;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: GlassAppBar(title: 'Query Builder Playground'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Compose a generated query',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Each preset maps directly to a type-safe builder method. The SQL '
            'preview remains parameterized; values stay in the arguments list.',
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final filter = _selectionField(
                label: 'Filter operator',
                value: _filterIndex,
                examples: _filterExamples,
                onChanged: (value) {
                  _filterIndex = value;
                  _configurationChanged();
                },
              );
              final sort = _selectionField(
                label: 'Sort',
                value: _sortIndex,
                examples: _sortExamples,
                onChanged: (value) {
                  _sortIndex = value;
                  _configurationChanged();
                },
              );
              if (constraints.maxWidth < 700) {
                return Column(
                  children: [filter, const SizedBox(height: 12), sort],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: filter),
                  const SizedBox(width: 12),
                  Expanded(child: sort),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _limitController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Limit',
                    helperText: 'Empty means unlimited',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _configurationChanged(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _offsetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Offset',
                    helperText: 'Empty means no offset',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _configurationChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            color: colors.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Parameterized SQL',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SelectableText(_sql.isEmpty ? 'Invalid configuration' : _sql),
                  const SizedBox(height: 12),
                  Text('Arguments: $_arguments'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _enumFilterCard(context),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _loading || _error != null ? null : _findAll,
                icon: const Icon(Icons.list),
                label: const Text('findAll'),
              ),
              OutlinedButton.icon(
                onPressed: _loading || _error != null ? null : _findFirst,
                icon: const Icon(Icons.looks_one_outlined),
                label: const Text('findFirst'),
              ),
              OutlinedButton.icon(
                onPressed: _loading || _error != null ? null : _count,
                icon: const Icon(Icons.calculate_outlined),
                label: const Text('count'),
              ),
              OutlinedButton.icon(
                onPressed: _loading || _error != null ? null : _deleteAll,
                icon: const Icon(Icons.delete_outline),
                label: const Text('deleteAll'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(_resultSummary, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SizedBox(
            height: 320,
            child: AsyncView<List<User>>(
              value: _hasRun ? _users : null,
              loading: _loading,
              error: _error,
              isEmpty: (users) => users.isEmpty,
              emptyBuilder: (context) => Center(
                child: Text(
                  _hasRun
                      ? 'The operation returned no rows.'
                      : 'The query has not been run yet.',
                ),
              ),
              dataBuilder: (context, users) => ListView.separated(
                itemCount: users.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final user = users[index];
                  return ListTile(
                    leading: CircleAvatar(child: Text('${user.id}')),
                    title: Text(user.name),
                    subtitle: Text(
                      '${user.email}\nAge ${user.age} · '
                      '${user.isActive ? 'active' : 'inactive'}',
                    ),
                    isThreeLine: true,
                    trailing: Text(user.phoneNumber ?? 'no phone'),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _enumFilterCard(BuildContext context) {
    final query = OrderQueryBuilder(
      DatabaseManager.currentDatabase,
    ).statusEqualTo(_orderStatus);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enum operator',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<OrderStatus>(
              initialValue: _orderStatus,
              decoration: const InputDecoration(
                labelText: 'Order statusEqualTo',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final status in OrderStatus.values)
                  DropdownMenuItem(value: status, child: Text(status.name)),
              ],
              onChanged: (status) {
                if (status != null) setState(() => _orderStatus = status);
              },
            ),
            const SizedBox(height: 8),
            SelectableText(query.toSql()),
            Text('Arguments: ${query.arguments}'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _countOrdersByStatus,
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('Count matching orders'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectionField({
    required String label,
    required int value,
    required List<_QueryExample> examples,
    required ValueChanged<int> onChanged,
  }) {
    final selected = examples[value];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<int>(
          initialValue: value,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          items: [
            for (var index = 0; index < examples.length; index++)
              DropdownMenuItem(
                value: index,
                child: Text(examples[index].label),
              ),
          ],
          onChanged: (newValue) {
            if (newValue != null) onChanged(newValue);
          },
        ),
        const SizedBox(height: 4),
        Text(selected.description),
      ],
    );
  }
}
