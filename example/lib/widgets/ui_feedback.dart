import 'package:flutter/material.dart';

abstract final class UiFeedback {
  static void showMessage(
    BuildContext context,
    String message, {
    bool error = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? colors.error : colors.primary,
      ),
    );
  }

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }
}
