import 'package:flutter/foundation.dart';

import '../core/utils/date_utils.dart';
import '../data/models/expense.dart';
import '../data/repositories/expense_repository.dart';
import '../data/services/image_storage_service.dart';

class ExpenseStore extends ChangeNotifier {
  ExpenseStore(this._repository);

  final ExpenseRepository _repository;
  List<Expense> _expenses = [];
  bool _loading = false;
  String? _error;

  List<Expense> get expenses => List.unmodifiable(_expenses);
  bool get loading => _loading;
  String? get error => _error;

  Future<void> initialize() => reload();

  Future<void> reload() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _expenses = await _repository.findAll();
    } catch (error) {
      _error = error.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> save(Expense expense, {Expense? previous}) async {
    if (previous == null) {
      await _repository.insert(expense);
    } else {
      await _repository.update(expense);
    }
    await reload();
  }

  Future<void> remove(Expense expense) async {
    await _repository.delete(expense.id);
    _expenses = _expenses.where((item) => item.id != expense.id).toList();
    notifyListeners();

    // The database row is already deleted; cleanup should not undo the UI
    // update if a stale or locked image file cannot be removed.
    try {
      await ImageStorageService.removeForExpense(
        imagePath: expense.imagePath,
        thumbnailPath: expense.thumbnailPath,
      );
    } catch (error) {
      debugPrint(
        'Could not remove receipt files for expense ${expense.id}: $error',
      );
    }
  }

  Future<void> clearAll() async {
    await _repository.deleteAll();
    _expenses = [];
    notifyListeners();
  }

  int get totalSpent =>
      _expenses.fold<int>(0, (sum, expense) => sum + expense.amount);

  int get thisMonthSpent => _sumFrom(startOfMonth(DateTime.now()));

  int get thisWeekSpent {
    final today = DateTime.now();
    final monday = startOfDay(
      today.subtract(Duration(days: today.weekday - 1)),
    );
    return _sumFrom(monday);
  }

  int _sumFrom(DateTime start) => _expenses
      .where((expense) => !expense.date.isBefore(start))
      .fold<int>(0, (sum, expense) => sum + expense.amount);

  List<CategoryTotal> get categoryTotals {
    final totals = <String, int>{};

    for (final expense in _expenses) {
      totals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    return totals.entries
        .map(
          (entry) => CategoryTotal(
            category: entry.key,
            amount: entry.value,
          ),
        )
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  List<DailyTotal> get lastSevenDays {
    final today = startOfDay(DateTime.now());

    return List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      final amount = _expenses
          .where(
            (expense) =>
                expense.date.year == date.year &&
                expense.date.month == date.month &&
                expense.date.day == date.day,
          )
          .fold<int>(0, (sum, expense) => sum + expense.amount);

      return DailyTotal(date: date, amount: amount);
    });
  }
}
