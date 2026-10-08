import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/expenses/expenses_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/scan/camera_page.dart';
import 'features/settings/settings_page.dart';
import 'state/expense_store.dart';

class OcrExpenseApp extends StatelessWidget {
  const OcrExpenseApp({super.key, required this.store});
  final ExpenseStore store;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'OCR Expense Tracker',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    home: AppShell(store: store),
  );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.store});
  final ExpenseStore store;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  void _openScanner() => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => CameraPage(store: widget.store)),
  );
  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardPage(store: widget.store, onOpenExpenses: () => setState(() => _index = 1)),
      ExpensesPage(store: widget.store),
      SettingsPage(store: widget.store),
    ];
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) => Scaffold(
        body: IndexedStack(index: _index, children: pages),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openScanner,
          icon: const Icon(Icons.document_scanner_outlined),
          label: const Text('Scan receipt'),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard), label: 'Overview'),
            NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Expenses'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}
