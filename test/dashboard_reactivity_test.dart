import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_expense_tracker/data/database/app_database.dart';
import 'package:ocr_expense_tracker/data/models/expense.dart';
import 'package:ocr_expense_tracker/data/repositories/expense_repository.dart';
import 'package:ocr_expense_tracker/features/dashboard/dashboard_page.dart';
import 'package:ocr_expense_tracker/state/expense_store.dart';

class _MemoryExpenseRepository extends ExpenseRepository {
  _MemoryExpenseRepository() : super(AppDatabase());

  final List<Expense> _items = [];

  @override
  Future<List<Expense>> findAll() async => List<Expense>.of(_items);

  @override
  Future<void> insert(Expense expense) async {
    _items.add(expense);
  }

  @override
  Future<void> update(Expense expense) async {
    final index = _items.indexWhere((item) => item.id == expense.id);
    if (index >= 0) {
      _items[index] = expense;
    }
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> deleteAll() async {
    _items.clear();
  }
}

void main() {
  testWidgets('dashboard updates immediately when an expense is saved',
      (tester) async {
    final store = ExpenseStore(_MemoryExpenseRepository());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardPage(store: store),
        ),
      ),
    );

    expect(find.text('Scan your first receipt'), findsOneWidget);

    final now = DateTime.now();
    await store.save(
      Expense(
        id: 'receipt-1',
        merchant: 'Demo Market',
        amount: 150000,
        date: now,
        category: 'Food',
        notes: '',
        rawText: 'Demo Market\nTOTAL 150.000 VND',
        imagePath: null,
        thumbnailPath: null,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Scan your first receipt'), findsNothing);
    expect(find.text('Demo Market'), findsOneWidget);
    expect(find.text('150.000 ₫'), findsWidgets);
  });
}
