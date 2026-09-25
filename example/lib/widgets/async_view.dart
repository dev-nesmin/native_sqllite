import 'package:flutter/material.dart';

/// Shared loading, empty, error, and data presentation for example screens.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.dataBuilder,
    this.emptyBuilder,
    this.loading = false,
    this.error,
    this.onRetry,
    this.isEmpty,
  });

  final T? value;
  final Widget Function(BuildContext context, T value) dataBuilder;
  final WidgetBuilder? emptyBuilder;
  final bool loading;
  final Object? error;
  final VoidCallback? onRetry;
  final bool Function(T value)? isEmpty;

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 12),
            Text(error.toString(), textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ],
        ),
      );
    }

    final current = value;
    if (current == null || (isEmpty?.call(current) ?? false)) {
      return emptyBuilder?.call(context) ??
          const Center(child: Text('Nothing to show yet.'));
    }
    return dataBuilder(context, current);
  }
}
