import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../widgets/glass_app_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const GlassAppBar(title: 'Native SQLite Example'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildSectionLabel('Core Features'),
          const SizedBox(height: 12),
          _buildFeatureCard(
            context,
            title: 'CRUD Operations',
            description:
                'Create, Read, Update, Delete for Users, Categories & Products',
            icon: Icons.edit_note,
            color: colors.primary,
            onTap: () => context.push('/crud'),
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            context,
            title: 'Order Management',
            description:
                'Full order lifecycle with status tracking and filtering',
            icon: Icons.receipt_long,
            color: colors.tertiary,
            onTap: () => context.push('/orders'),
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            context,
            title: 'Query Builder',
            description:
                'Type-safe queries with filters, sorting, and pagination',
            icon: Icons.search,
            color: colors.secondary,
            onTap: () => context.push('/query'),
          ),
          const SizedBox(height: 24),
          _buildSectionLabel('Advanced Features'),
          const SizedBox(height: 12),
          _buildFeatureCard(
            context,
            title: 'Advanced Features',
            description:
                'Transactions, foreign keys, indexes, and complex queries',
            icon: Icons.code,
            color: colors.tertiary,
            onTap: () => context.push('/advanced'),
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            context,
            title: 'Background Sync',
            description:
                'WorkManager and BackgroundTasks write through native helpers',
            icon: Icons.sync,
            color: colors.primary,
            onTap: () => context.push('/background'),
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            context,
            title: 'Model Gallery',
            description:
                'Round-trip every supported type, annotation, and converter',
            icon: Icons.data_object,
            color: colors.error,
            onTap: () => context.push('/models'),
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            context,
            title: 'Raw API & Errors',
            description:
                'Every low-level method plus typed SQLite error contracts',
            icon: Icons.api,
            color: colors.secondary,
            onTap: () => context.push('/raw'),
          ),
          const SizedBox(height: 24),
          _buildSectionLabel('Platform & Diagnostics'),
          const SizedBox(height: 12),
          _buildFeatureCard(
            context,
            title: 'Native Code Integration',
            description:
                'Access the database from Kotlin/Swift without Flutter',
            icon: Icons.integration_instructions,
            color: colors.primary,
            onTap: () => context.push('/native'),
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            context,
            title: 'Database Statistics',
            description:
                'Table counts, schema info, and sample data generation',
            icon: Icons.analytics,
            color: colors.tertiary,
            onTap: () => context.push('/statistics'),
          ),
          if (kIsWeb) ...[
            const SizedBox(height: 12),
            _buildFeatureCard(
              context,
              title: 'Web Persistence',
              description:
                  'IndexedDB persistence, reload counter, and one-tab guard',
              icon: Icons.public,
              color: colors.primary,
              onTap: () => context.push('/web'),
            ),
          ],
          if (kDebugMode) ...[
            const SizedBox(height: 12),
            _buildFeatureCard(
              context,
              title: 'Database Inspector',
              description: 'Open the bundled extension in Flutter DevTools',
              icon: Icons.developer_mode,
              color: colors.secondary,
              onTap: () => context.push('/inspector'),
            ),
          ],
          if (!kReleaseMode) ...[
            const SizedBox(height: 12),
            _buildFeatureCard(
              context,
              title: 'SQLite Benchmarks',
              description:
                  'Compare loop, transaction, native batch, and query plans',
              icon: Icons.speed,
              color: colors.tertiary,
              onTap: () => context.push('/benchmarks'),
            ),
          ],
          const SizedBox(height: 24),
          _buildInfoSection(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.storage, size: 60, color: colors.primary),
            const SizedBox(height: 16),
            const Text(
              'Native SQLite Plugin',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'A comprehensive example demonstrating all features',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
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
    final colors = Theme.of(context).colorScheme;
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
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: colors.onPrimaryContainer),
                const SizedBox(width: 8),
                Text(
                  'Key Features',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(context, 'Cross-platform: Android, iOS, and Web'),
            _buildFeatureItem(context, 'Type-safe with code generation'),
            _buildFeatureItem(context, 'Native code access (Kotlin/Swift)'),
            _buildFeatureItem(context, 'Foreign keys, indexes & migrations'),
            _buildFeatureItem(context, 'Transactions and WAL mode'),
            _buildFeatureItem(context, 'JSON fields & custom type converters'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String text) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: colors.onPrimaryContainer),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
