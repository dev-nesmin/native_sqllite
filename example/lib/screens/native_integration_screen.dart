import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/glass_app_bar.dart';

/// Demonstrates calling native code (Kotlin/Swift) that accesses the database
class NativeIntegrationScreen extends StatefulWidget {
  const NativeIntegrationScreen({super.key});

  @override
  State<NativeIntegrationScreen> createState() =>
      _NativeIntegrationScreenState();
}

class _NativeIntegrationScreenState extends State<NativeIntegrationScreen> {
  static const platform = MethodChannel(
    'com.example.native_sqlite_example/native',
  );
  String _output = 'Press a button to test native integration...';
  bool _isLoading = false;

  String get _nativeLanguage => switch (defaultTargetPlatform) {
    TargetPlatform.android => 'Kotlin',
    TargetPlatform.iOS => 'Swift',
    _ => 'native',
  };

  String get _platformName => switch (defaultTargetPlatform) {
    TargetPlatform.android => 'Android (Kotlin)',
    TargetPlatform.iOS => 'iOS (Swift)',
    _ => 'this platform',
  };

  void _setOutput(String output) {
    if (mounted) setState(() => _output = output);
  }

  Future<void> _testNativeAccess() async {
    setState(() => _isLoading = true);
    try {
      final result = await platform.invokeMethod<String>('testNativeAccess');
      if (result == null) throw StateError('Native code returned no result.');
      _setOutput(result);
    } catch (e) {
      _setOutput('Failed to test native access: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createUserFromNative() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const _UserInputDialog(),
    );

    if (result != null) {
      setState(() => _isLoading = true);
      try {
        final userId = await platform.invokeMethod<int>(
          'createUserFromNative',
          {'name': result['name'], 'email': result['email']},
        );
        if (userId == null) {
          throw StateError('Native code returned no user ID.');
        }
        _setOutput(
          'Success!\n\n'
          'Created user from native $_nativeLanguage code.\n\n'
          'User ID: $userId\n'
          'Name: ${result['name']}\n'
          'Email: ${result['email']}\n\n'
          'This demonstrates that native code can access '
          'the SQLite database directly without going through Flutter!',
        );
      } catch (e) {
        _setOutput('Failed to create user: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _getUsersFromNative() async {
    setState(() => _isLoading = true);
    try {
      final users =
          await platform.invokeListMethod<Map<Object?, Object?>>(
            'getUsersFromNative',
          ) ??
          const [];

      final buffer = StringBuffer();
      buffer.writeln('Users fetched from native $_nativeLanguage code:\n');
      buffer.writeln('Total: ${users.length} users\n');

      for (var i = 0; i < users.length && i < 10; i++) {
        final user = users[i];
        buffer.writeln('${i + 1}. ${user['name']}');
        buffer.writeln('   Email: ${user['email']}');
        buffer.writeln('   Age: ${user['age']}');
        buffer.writeln('   ID: ${user['id']}\n');
      }

      _setOutput(buffer.toString());
    } catch (e) {
      _setOutput('Failed to get users: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlassAppBar(title: 'Native Integration'),
      body: Column(
        children: [
          _buildInfoCard(_platformName),
          _buildButtonsSection(),
          const Divider(height: 1),
          _buildOutputSection(),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String platformName) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.all(16),
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(switch (defaultTargetPlatform) {
                  TargetPlatform.android => Icons.android,
                  TargetPlatform.iOS => Icons.apple,
                  _ => Icons.web,
                }, color: colors.onPrimaryContainer),
                const SizedBox(width: 8),
                Text(
                  'Native $platformName Integration',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'This demonstrates accessing the SQLite database directly from '
              'native $platformName code using the generated schema constants. '
              'The native code can perform all database operations independently '
              'of Flutter.',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonsSection() {
    if (kIsWeb) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Native Kotlin and Swift helpers are available on Android and '
            'iOS. The web build uses the same Dart API backed by SQLite WASM, '
            'so there are no platform-native actions to run here.',
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _testNativeAccess,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Run Native Access Tests'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _createUserFromNative,
            icon: const Icon(Icons.add),
            label: const Text('Create User from Native Code'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _getUsersFromNative,
            icon: const Icon(Icons.list),
            label: const Text('Get Users from Native Code'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutputSection() {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
    );
  }
}

class _UserInputDialog extends StatefulWidget {
  const _UserInputDialog();

  @override
  State<_UserInputDialog> createState() => _UserInputDialogState();
}

class _UserInputDialogState extends State<_UserInputDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create User from Native'),
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
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Please enter an email';
                if (!value!.contains('@')) return 'Please enter a valid email';
                return null;
              },
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
                'email': _emailController.text,
              });
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
