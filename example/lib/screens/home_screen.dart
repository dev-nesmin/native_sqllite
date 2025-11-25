import 'package:flutter/material.dart';

import '../widgets/glass_app_bar.dart';
import 'advanced_features_screen.dart';
import 'crud_demo_screen.dart';
import 'manual_api_screen.dart';
import 'native_integration_screen.dart';
import 'statistics_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(title: 'Native SQLite Example'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 16),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildFeatureCard(
            context,
            title: 'CRUD Operations',
            description:
                'Create, Read, Update, Delete operations with generated repositories',
            icon: Icons.edit_note,
            color: Colors.blue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CrudDemoScreen()),
            ),
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            context,
            title: 'Advanced Features',
            description:
                'Transactions, migrations, foreign keys, and complex queries',
            icon: Icons.code,
            color: Colors.purple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdvancedFeaturesScreen()),
            ),
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            context,
            title: 'Manual API Demo',
            description:
                'Use native SQLite API directly without code generation',
            icon: Icons.api,
            color: Colors.orange,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManualApiScreen()),
            ),
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            context,
            title: 'Native Code Integration',
            description: 'Access database from Kotlin/Swift without Flutter',
            icon: Icons.integration_instructions,
            color: Colors.teal,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NativeIntegrationScreen(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            context,
            title: 'Database Statistics',
            description:
                'View database info, table counts, and performance metrics',
            icon: Icons.analytics,
            color: Colors.green,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StatisticsScreen()),
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.storage, size: 60, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'Native SQLite Plugin',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'A comprehensive example demonstrating all features',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Key Features',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildFeatureItem('Cross-platform: Android, iOS, and Web'),
            _buildFeatureItem('Type-safe with code generation'),
            _buildFeatureItem('Native code access (Kotlin/Swift)'),
            _buildFeatureItem('Foreign keys and indexes'),
            _buildFeatureItem('Transactions and migrations'),
            _buildFeatureItem('WAL mode for concurrent access'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
