import 'package:adhd_tracker/models/goals.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  String? currentUserId;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('adhd_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = join(directory.path, filePath);

      // Ensure directory exists
      await Directory(dirname(path)).create(recursive: true);

      return await openDatabase(
        path,
        version: 2, // Increased version for schema update
        onCreate: _createDB,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
      );
    } catch (e) {
      throw Exception('Failed to initialize database: $e');
    }
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';

    await db.execute('''
      CREATE TABLE goals (
        id $idType,
        userId $textType,
        name $textType,
        frequency $textType,
        startDate $textType,
        notes $textTypeNullable,
        createdAt $textType,
        updatedAt $textType
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add userId column to existing goals table
      await db.execute('ALTER TABLE goals ADD COLUMN userId TEXT NOT NULL DEFAULT "legacy"');
    }
  }

  // User management methods
  void setCurrentUser(String userId) {
    currentUserId = userId;
  }

  Future<void> clearCurrentUser() async {
    currentUserId = null;
    await close();
  }

  // Create
  Future<int> insertGoal(Goal goal) async {
    if (currentUserId == null) {
      throw Exception('No user logged in');
    }

    try {
      final db = await instance.database;
      final now = DateTime.now().toIso8601String();
      
      final Map<String, dynamic> data = goal.toMap()
        ..addAll({
          'userId': currentUserId,
          'createdAt': now,
          'updatedAt': now,
        });

      return await db.insert(
        'goals',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw Exception('Failed to insert goal: $e');
    }
  }

  // Read
  Future<Goal?> getGoal(int id) async {
    if (currentUserId == null) return null;

    try {
      final db = await instance.database;
      final maps = await db.query(
        'goals',
        columns: ['id', 'userId', 'name', 'frequency', 'startDate', 'notes', 'createdAt', 'updatedAt'],
        where: 'id = ? AND userId = ?',
        whereArgs: [id, currentUserId],
      );

      if (maps.isNotEmpty) {
        return Goal.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get goal: $e');
    }
  }

  Future<List<Goal>> getAllGoals() async {
    if (currentUserId == null) return [];

    try {
      final db = await instance.database;
      final result = await db.query(
        'goals',
        where: 'userId = ?',
        whereArgs: [currentUserId],
        orderBy: 'createdAt DESC',
      );
      
      return result.map((map) => Goal.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get all goals: $e');
    }
  }

  // Update
  Future<int> updateGoal(Goal goal) async {
    if (currentUserId == null) throw Exception('No user logged in');

    try {
      final db = await instance.database;
      
      final Map<String, dynamic> data = goal.toMap()
        ..addAll({
          'updatedAt': DateTime.now().toIso8601String(),
        });

      return await db.update(
        'goals',
        data,
        where: 'id = ? AND userId = ?',
        whereArgs: [goal.id, currentUserId],
      );
    } catch (e) {
      throw Exception('Failed to update goal: $e');
    }
  }

  // Delete
  Future<int> deleteGoal(int id) async {
    if (currentUserId == null) throw Exception('No user logged in');

    try {
      final db = await instance.database;
      return await db.delete(
        'goals',
        where: 'id = ? AND userId = ?',
        whereArgs: [id, currentUserId],
      );
    } catch (e) {
      throw Exception('Failed to delete goal: $e');
    }
  }

  // Delete all goals for current user
  Future<int> deleteAllGoals() async {
    if (currentUserId == null) throw Exception('No user logged in');

    try {
      final db = await instance.database;
      return await db.delete(
        'goals',
        where: 'userId = ?',
        whereArgs: [currentUserId],
      );
    } catch (e) {
      throw Exception('Failed to delete all goals: $e');
    }
  }

  // Search goals for current user
  Future<List<Goal>> searchGoals(String query) async {
    if (currentUserId == null) return [];

    try {
      final db = await instance.database;
      final result = await db.query(
        'goals',
        where: '(name LIKE ? OR notes LIKE ?) AND userId = ?',
        whereArgs: ['%$query%', '%$query%', currentUserId],
        orderBy: 'createdAt DESC',
      );

      return result.map((map) => Goal.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to search goals: $e');
    }
  }

  Future<bool> goalExists(int id) async {
    if (currentUserId == null) return false;

    try {
      final db = await instance.database;
      final result = await db.query(
        'goals',
        where: 'id = ? AND userId = ?',
        whereArgs: [id, currentUserId],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check if goal exists: $e');
    }
  }

  // Close database
  Future<void> close() async {
    try {
      if (_database != null) {
        final db = await instance.database;
        await db.close();
        _database = null;
      }
    } catch (e) {
      throw Exception('Failed to close database: $e');
    }
  }
}