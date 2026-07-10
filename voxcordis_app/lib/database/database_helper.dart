import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../core/constants/app_constants.dart';
import '../models/analysis_result.dart';
import '../models/user.dart';

/// Singleton SQLite – historique local + donnees utilisateur
/// (cf. Resume Technique, sections 3 et 5)
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), AppConstants.dbName);
    return openDatabase(
      path,
      version: 2,                  // ← 1 → 2
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,       // ← ajouter
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE users ADD COLUMN password TEXT NOT NULL DEFAULT ""'
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE users (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    firstName TEXT NOT NULL,
    lastName  TEXT NOT NULL,
    email     TEXT NOT NULL UNIQUE,
    password  TEXT NOT NULL
  )
''');

    await db.execute('''
      CREATE TABLE analysis_results (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        date           TEXT    NOT NULL,
        predictedClass INTEGER NOT NULL,
        confidence     REAL    NOT NULL,
        riskLevel      INTEGER NOT NULL,
        isSynced       INTEGER NOT NULL DEFAULT 0,
        modelVersion   TEXT
      )
    ''');
  }

  // ── Users ─────────────────────────────────────────────────────────────────

  Future<int> insertUser(UserModel user) async {
    final db = await database;
    return db.insert('users', user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<UserModel?> getUser(int id) async {
    final db = await database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final db = await database;
    final rows = await db.query('users',
        where: 'email = ?', whereArgs: [email]);
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }

  Future<void> deleteUser(int id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // ── Analysis results ──────────────────────────────────────────────────────

  Future<int> insertResult(AnalysisResult result) async {
    final db = await database;
    return db.insert('analysis_results', result.toMap());
  }

  Future<List<AnalysisResult>> getAllResults() async {
    final db = await database;
    final rows =
        await db.query('analysis_results', orderBy: 'date DESC');
    return rows.map(AnalysisResult.fromMap).toList();
  }

  Future<AnalysisResult?> getLatestResult() async {
    final db = await database;
    final rows = await db.query('analysis_results',
        orderBy: 'date DESC', limit: 1);
    if (rows.isEmpty) return null;
    return AnalysisResult.fromMap(rows.first);
  }

  Future<List<AnalysisResult>> getUnsynced() async {
    final db = await database;
    final rows = await db.query('analysis_results',
        where: 'isSynced = ?', whereArgs: [0], orderBy: 'date DESC');
    return rows.map(AnalysisResult.fromMap).toList();
  }

  Future<void> markSynced(int id) async {
    final db = await database;
    await db.update('analysis_results', {'isSynced': 1},
        where: 'id = ?', whereArgs: [id]);
  }
}
