import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_constants.dart';
class AppDatabase {
  Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    final path=p.join(await getDatabasesPath(),AppConstants.databaseName);
    _database=await openDatabase(path,version:AppConstants.databaseVersion,onCreate:(db,_)async{
      await db.execute("CREATE TABLE expenses (id TEXT PRIMARY KEY, merchant TEXT NOT NULL, amount INTEGER NOT NULL, date TEXT NOT NULL, category TEXT NOT NULL, notes TEXT NOT NULL DEFAULT '', raw_text TEXT NOT NULL DEFAULT '', image_path TEXT, thumbnail_path TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)");
      await db.execute('CREATE INDEX idx_expenses_date ON expenses(date DESC)');
      await db.execute('CREATE INDEX idx_expenses_category ON expenses(category)');
    });
    return _database!;
  }
  Future<void> close() async { final db=_database; _database=null; await db?.close(); }
}
