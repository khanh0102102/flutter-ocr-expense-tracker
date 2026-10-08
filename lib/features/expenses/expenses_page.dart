import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_utils.dart';
import '../../state/expense_store.dart';
import 'widgets/expense_card.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key, required this.store});

  final ExpenseStore store;

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  String _query = '';
  ExpenseCategory? _category;

  @override
  Widget build(BuildContext context) {
    final items = widget.store.expenses.where((expense) {
      final query = _query.trim().toLowerCase();
      return (query.isEmpty ||
              expense.merchant.toLowerCase().contains(query) ||
              expense.notes.toLowerCase().contains(query)) &&
          (_category == null || expense.category == _category!.label);
    }).toList();

    final total = items.fold<int>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
        children: [
          Text(
            'Expenses',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              hintText: 'Search merchant or notes',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _category == null,
                  onSelected: (_) => setState(() => _category = null),
                ),
                const SizedBox(width: 8),
                ...ExpenseCategory.values.map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category.label),
                      selected: _category == category,
                      onSelected: (_) => setState(
                        () => _category =
                            _category == category ? null : category,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${items.length} transaction(s) • ${formatVnd(total)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No matching expenses.')),
            )
          else
            ...items.map(
              (expense) => Dismissible(
                key: ValueKey(expense.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => widget.store.remove(expense),
                child: ExpenseCard(expense: expense),
              ),
            ),
        ],
      ),
    );
  }
}