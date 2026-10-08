import '../database/app_database.dart';
import '../models/expense.dart';
class ExpenseRepository {
  const ExpenseRepository(this._database);
  final AppDatabase _database;
  Future<List<Expense>> findAll() async { final rows=await (await _database.database).query('expenses',orderBy:'date DESC, created_at DESC'); return rows.map(Expense.fromMap).toList(); }
  Future<void> insert(Expense e) async => (await _database.database).insert('expenses',e.toMap());
  Future<void> update(Expense e) async => (await _database.database).update('expenses',e.toMap(),where:'id = ?',whereArgs:[e.id]);
  Future<void> delete(String id) async => (await _database.database).delete('expenses',where:'id = ?',whereArgs:[id]);
  Future<void> deleteAll() async => (await _database.database).delete('expenses');
}
