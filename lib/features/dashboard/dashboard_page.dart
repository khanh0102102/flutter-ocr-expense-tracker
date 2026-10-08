import 'package:flutter/material.dart';

import '../../core/utils/currency_utils.dart';
import '../../state/expense_store.dart';
import '../../widgets/charts/category_donut_chart.dart';
import '../../widgets/charts/weekly_bar_chart.dart';
import '../expenses/widgets/expense_card.dart';
import '../scan/camera_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.store, this.onOpenExpenses});

  final ExpenseStore store;
  final VoidCallback? onOpenExpenses;

  @override
  Widget build(BuildContext context) {
    final recent = store.expenses.take(5).toList();
    final children = <Widget>[
      Row(
        children: [
          Expanded(
            child: Text(
              'Your finances',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          IconButton(
            onPressed: () => _scan(context),
            icon: const Icon(Icons.document_scanner_outlined),
          ),
        ],
      ),
      Text(
        'Offline-first • OCR on device',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 20),
      _summary(context, 'This month', store.thisMonthSpent, Icons.calendar_month),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _mini(context, 'This week', store.thisWeekSpent, Icons.date_range),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _mini(context, 'All time', store.totalSpent, Icons.wallet),
          ),
        ],
      ),
      const SizedBox(height: 26),
      const Text(
        'Category distribution',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 10),
      Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: CategoryDonutChart(data: store.categoryTotals),
        ),
      ),
      const SizedBox(height: 26),
      const Text(
        'Last 7 days',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 10),
      Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: WeeklyBarChart(data: store.lastSevenDays),
        ),
      ),
      const SizedBox(height: 26),
      Row(
        children: [
          const Expanded(
            child: Text(
              'Recent expenses',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          TextButton(onPressed: onOpenExpenses, child: const Text('See all')),
        ],
      ),
    ];

    if (recent.isEmpty) {
      children.add(
        Card(
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: ListTile(
            onTap: () => _scan(context),
            leading: const Icon(Icons.center_focus_strong),
            title: const Text('Scan your first receipt'),
            subtitle: const Text('Extract merchant, total and date locally.'),
          ),
        ),
      );
    } else {
      children.addAll(
        recent.map(
          (expense) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ExpenseCard(expense: expense),
          ),
        ),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: store.reload,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
          children: children,
        ),
      ),
    );
  }

  void _scan(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CameraPage(store: store)),
    );
  }

  Widget _summary(BuildContext context, String title, int amount, IconData icon) {
    return Card(
      color: Theme.of(context).colorScheme.primary,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(color: Colors.white70)),
        subtitle: Text(
          formatVnd(amount),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _mini(BuildContext context, String title, int amount, IconData icon) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(height: 12),
            Text(title),
            const SizedBox(height: 4),
            Text(
              formatVnd(amount),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}