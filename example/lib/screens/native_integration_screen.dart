import 'dart:io';

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

  Future<void> _testNativeAccess() async {
    setState(() => _isLoading = true);
    try {
      final String result = await platform.invokeMethod('testNativeAccess');
      setState(() {
        _output = result;
        _isLoading = false;
      });
    } on PlatformException catch (e) {
      setState(() {
        _output = 'Failed to test native access: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _output = 'Error: $e';
        _isLoading = false;
      });
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
        final int userId = await platform.invokeMethod('createUserFromNative', {
          'name': result['name'],
          'email': result['email'],
        });
        setState(() {
          _output =
              'Success!\n\n'
              'Created user from native ${Platform.isAndroid ? 'Kotlin' : 'Swift'} code.\n\n'
              'User ID: $userId\n'
              'Name: ${result['name']}\n'
              'Email: ${result['email']}\n\n'
              'This demonstrates that native code can access '
              'the SQLite database directly without going through Flutter!';
          _isLoading = false;
        });
      } on PlatformException catch (e) {
        setState(() {
          _output = 'Failed to create user: ${e.message}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getUsersFromNative() async {
    setState(() => _isLoading = true);
    try {
      final List<dynamic> users = await platform.invokeMethod(
        'getUsersFromNative',
      );

      final buffer = StringBuffer();
      buffer.writeln(
        'Users fetched from native ${Platform.isAndroid ? 'Kotlin' : 'Swift'} code:\n',
      );
      buffer.writeln('Total: ${users.length} users\n');

      for (var i = 0; i < users.length && i < 10; i++) {
        final user = users[i] as Map;
        buffer.writeln('${i + 1}. ${user['name']}');
        buffer.writeln('   Email: ${user['email']}');
        buffer.writeln('   Age: ${user['age']}');
        buffer.writeln('   ID: ${user['id']}\n');
      }

      setState(() {
        _output = buffer.toString();
        _isLoading = false;
      });
    } on PlatformException catch (e) {
      setState(() {
        _output = 'Failed to get users: ${e.message}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final platformName = Platform.isAndroid
        ? 'Android (Kotlin)'
        : 'iOS (Swift)';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(title: 'Native Integration'),
      body: Column(
        children: [
          const SizedBox(height: kToolbarHeight),
          _buildInfoCard(platformName),
          _buildButtonsSection(),
          const Divider(height: 1),
          _buildOutputSection(),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String platformName) {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Platform.isAndroid ? Icons.android : Icons.apple,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'Native $platformName Integration',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
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
    return Expanded(
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
