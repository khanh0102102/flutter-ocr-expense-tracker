import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../data/services/image_storage_service.dart';
import '../../state/expense_store.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.store});

  final ExpenseStore store;

  Future<void> _clear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
          'Delete all expenses and cached receipt images from this device?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await store.clearAll();
      await ImageStorageService.clearAll();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Local data cleared.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
        children: [
          Text(
            'Settings',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          Card(
            color: Colors.white,
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.offline_bolt),
                  title: Text('Offline-first'),
                  subtitle: Text(
                    'OCR and expense data stay on the device.',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.storage),
                  title: const Text('Database'),
                  subtitle: Text(
                    '${AppConstants.databaseName} • SQLite',
                  ),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.auto_awesome),
                  title: Text('OCR engine'),
                  subtitle: Text('Google ML Kit Text Recognition'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            color: Colors.white,
            child: ListTile(
              leading: Icon(Icons.insights),
              title: Text('Analytics'),
              subtitle: Text(
                'Animated CustomPainter donut and weekly bar charts',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.redAccent,
            child: ListTile(
              onTap: () => _clear(context),
              leading: const Icon(Icons.delete_sweep, color: Colors.white),
              title: const Text(
                'Clear local data',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Delete expenses and receipt cache.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }
}