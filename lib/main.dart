import 'package:flutter/material.dart';
import 'app.dart';
import 'data/database/app_database.dart';
import 'data/repositories/expense_repository.dart';
import 'state/expense_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = AppDatabase();
  final repository = ExpenseRepository(database);
  final store = ExpenseStore(repository);
  await store.initialize();
  runApp(OcrExpenseApp(store: store));
}
