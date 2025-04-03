import 'package:adhd_tracker/models/reminder_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ReminderDatabaseHelper {
  static final ReminderDatabaseHelper instance = ReminderDatabaseHelper._init();
  static Database? _database;

  static const String tableReminders = 'reminders';
  ReminderDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('reminder.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableReminders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        frequency TEXT NOT NULL,
        startDate TEXT NOT NULL,
        notes TEXT,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        scheduledTime TEXT NOT NULL,
        sound TEXT
      )
    ''');
  }

  Future<int> insertReminder(Reminder reminder) async {
    final db = await instance.database;
    return await db.insert(tableReminders, reminder.toMap());
  }

  Future<List<Reminder>> getAllReminder() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(tableReminders);
    return List.generate(maps.length, (i) => Reminder.fromMap(maps[i]));
  }

  Future<int> updateReminderCompletion(int id, bool isCompleted) async {
    final db = await instance.database;
    return await db.update(
      tableReminders,
      {'isCompleted': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteReminder(int id) async {
    final db = await instance.database;
    return await db.delete(
      tableReminders,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // New method to clear the entire database when logging out
  Future<void> clearDatabase() async {
    final db = await instance.database;
    
    // Delete all rows from the reminders table
    await db.delete(tableReminders);
  }

  // Optional: Close the database connection
  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}