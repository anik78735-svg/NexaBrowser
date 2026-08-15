import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/saved_password.dart';

class PasswordService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'nexa_passwords.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE passwords(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            site TEXT,
            username TEXT,
            password TEXT
          )
        ''');
      },
    );
    return _db!;
  }

  static Future<List<SavedPassword>> getAll() async {
    final db = await database;
    final maps = await db.query('passwords', orderBy: 'site ASC');
    return maps.map((e) => SavedPassword.fromMap(e)).toList();
  }

  static Future<void> add(SavedPassword p) async {
    final db = await database;
    final map = p.toMap()..remove('id');
    await db.insert('passwords', map);
  }

  static Future<void> delete(int id) async {
    final db = await database;
    await db.delete('passwords', where: 'id = ?', whereArgs: [id]);
  }
}