import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hedieaty4.0.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future<void> _createDB(Database db, int version) async {
    // Create Users table
    await db.execute('''
      CREATE TABLE Users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      );
    ''');

    // Create Events table
    await db.execute('''
      CREATE TABLE Events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        date TEXT,
        location TEXT,
        user_id INTEGER,
        FOREIGN KEY (user_id) REFERENCES Users (id)
      );
    ''');

    // Create Gifts table with an image column
    await db.execute('''
      CREATE TABLE Gifts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        image TEXT, -- This will store the image path or base64 string
        event_id INTEGER,
        FOREIGN KEY (event_id) REFERENCES Events (id)
      );
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add the image column to the Gifts table
      await db.execute('ALTER TABLE Gifts ADD COLUMN image TEXT');
      print('Database upgraded to version $newVersion: Added "image" column to Gifts table.');
    }
  }

  Future<void> dropAllTables() async {
    final db = await database;

    await db.execute('DROP TABLE IF EXISTS Users');
    await db.execute('DROP TABLE IF EXISTS Events');
    await db.execute('DROP TABLE IF EXISTS Gifts');

    print('All tables dropped successfully.');
  }

  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    try {
      int id = await db.insert(table, values, conflictAlgorithm: ConflictAlgorithm.replace);
      print("Inserted into $table: $values, Row ID: $id");
      return id;
    } catch (e) {
      print("Error inserting into $table: $e");
      return -1; // Indicate failure
    }
  }

  Future<List<Map<String, dynamic>>> query(String table,
      {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    return await db.query(table, where: where, whereArgs: whereArgs);
  }

  Future<int> update(String table, Map<String, dynamic> values,
      {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    return await db.update(table, values, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(String table,
      {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }
}
