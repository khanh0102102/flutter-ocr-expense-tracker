class AppConstants {
  const AppConstants._();
  static const appName = 'OCR Expense Tracker';
  static const currencySymbol = '₫';
  static const databaseName = 'ocr_expense_tracker.db';
  static const databaseVersion = 1;
}
enum ExpenseCategory {
  food('Food', 'Meals, groceries, drinks'),
  study('Study', 'Books, printing, tuition supplies'),
  travel('Travel', 'Fuel, tickets, transport'),
  gear('Gear', 'Electronics, equipment, accessories'),
  entertainment('Entertainment', 'Movies, games, leisure');
  const ExpenseCategory(this.label, this.description);
  final String label, description;
  static ExpenseCategory fromValue(String value) => ExpenseCategory.values.firstWhere(
    (item) => item.label.toLowerCase() == value.toLowerCase(),
    orElse: () => ExpenseCategory.food,
  );
}
