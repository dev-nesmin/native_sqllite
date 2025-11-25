import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:native_sqlite/native_sqlite.dart';
import 'package:native_sqlite_example/models/profile.dart';

import '../widgets/glass_app_bar.dart';

/// Demo screen for JSON field support
class JsonFieldsDemoScreen extends StatefulWidget {
  const JsonFieldsDemoScreen({super.key});

  @override
  State<JsonFieldsDemoScreen> createState() => _JsonFieldsDemoScreenState();
}

class _JsonFieldsDemoScreenState extends State<JsonFieldsDemoScreen> {
  static const String _databaseName = 'json_demo.db';
  final ProfileRepository _repository = const ProfileRepository(_databaseName);
  List<Profile> _profiles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    setState(() => _isLoading = true);
    try {
      // Open/create database
      await NativeSqlite.open(
        config: DatabaseConfig(
          name: _databaseName,
          version: 1,
          onCreate: [ProfileSchema.createTableSql],
        ),
      );

      await _loadProfiles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing database: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProfiles() async {
    final profiles = await _repository.findAll();
    setState(() => _profiles = profiles);
  }

  Future<void> _insertSampleProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = Profile(
        name: 'John Doe ${DateTime.now().millisecond}',
        email: 'john.doe${DateTime.now().millisecond}@example.com',
        settings: {
          'theme': 'dark',
          'notifications': true,
          'language': 'en',
          'fontSize': 14.0,
        },
        tags: ['developer', 'flutter', 'dart'],
        address: const Address(
          street: '123 Main St',
          city: 'San Francisco',
          zipCode: '94102',
          country: 'USA',
        ),
        addresses: [
          const Address(
            street: '123 Main St',
            city: 'San Francisco',
            zipCode: '94102',
            country: 'USA',
          ),
          const Address(
            street: '456 Oak Ave',
            city: 'Los Angeles',
            zipCode: '90001',
            country: 'USA',
          ),
        ],
        metadata: {
          'createdAt': DateTime.now().toIso8601String(),
          'source': 'mobile',
          'version': 1,
        },
      );

      await _repository.insert(profile);
      await _loadProfiles();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile inserted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAll() async {
    setState(() => _isLoading = true);
    try {
      await _repository.deleteAll();
      await _loadProfiles();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('All profiles deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: 'JSON Fields Demo',
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Delete All',
            onPressed: _isLoading ? null : _deleteAll,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profiles.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: kToolbarHeight),
                  const Icon(Icons.data_object, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No profiles yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap + to create a sample profile',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _profiles.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final profile = _profiles[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ExpansionTile(
                    leading: CircleAvatar(child: Text('${profile.id ?? 0}')),
                    title: Text(
                      profile.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(profile.email),
                    children: [
                      const Divider(),
                      _buildJsonSection(
                        'Settings (Map<String, dynamic>)',
                        profile.settings,
                      ),
                      _buildJsonSection('Tags (List<String>)', profile.tags),
                      _buildJsonSection(
                        'Address (Custom Object)',
                        profile.address,
                      ),
                      _buildJsonSection(
                        'Addresses (List<Custom Object>)',
                        profile.addresses,
                      ),
                      _buildJsonSection('Metadata (dynamic)', profile.metadata),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _insertSampleProfile,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildJsonSection(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              _formatValue(value),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'null';
    if (value is Address) {
      return 'Address(\n'
          '  street: ${value.street},\n'
          '  city: ${value.city},\n'
          '  zipCode: ${value.zipCode},\n'
          '  country: ${value.country}\n'
          ')';
    }
    try {
      // Try to pretty print JSON
      final encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(value);
    } catch (e) {
      return value.toString();
    }
  }
}
