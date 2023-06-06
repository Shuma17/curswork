import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final _databaseName = 'motivator.db';
  static final _databaseVersion = 1;

  static final table = 'goals';

  static final columnId = 'id';
  static final columnTitle = 'title';
  static final columnDescription = 'description';
  static final columnStatus = 'status';

  static final tableStatistics = 'goals_statistics';

  static final columnStatisticsId = 'id';
  static final columnTotalGoals = 'total_goals';
  static final columnCompletedGoals = 'completed_goals';
  static final columnUncompletedGoals = 'uncompleted_goals';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> updateGoalsStatistics(int totalGoals, int completedGoals, int uncompletedGoals) async {
    final Database db = await database;
    await db.update(
      'statistics',
      {
        'total_goals': totalGoals,
        'completed_goals': completedGoals,
        'uncompleted_goals': uncompletedGoals,
      },
    );
  }

  Future<Map<String, dynamic>> getGoalsStatistics() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('statistics');
    return maps.isNotEmpty ? maps.first : {'total_goals': 0, 'completed_goals': 0, 'uncompleted_goals': 0};
  }


  Future<void> updateCompletedGoals(int completedGoals) async {
    final db = await database;
    await db.update(
      'statistics',
      {'completed_goals': completedGoals},
    );
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  Future<void> insertGoalHistory(int goalId, String action) async {
    final db = await database;
  }

  void _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        description TEXT,
        status INTEGER
      )
      ''');

    await db.execute('''
      CREATE TABLE statistics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        total_goals INTEGER,
        completed_goals INTEGER,
        uncompleted_goals INTEGER
      )
      ''');

    await db.rawInsert('''
      INSERT INTO statistics (total_goals, completed_goals, uncompleted_goals)
      VALUES (0, 0, 0)
      ''');
  }
}
