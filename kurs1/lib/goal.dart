import 'package:sqflite/sqlite_api.dart';
import 'database.dart';

class Goal {
  int? id;
  String? title;
  String? description;
  bool status;
  bool deleted;
  final DatabaseHelper databaseHelper;

  Goal({
    this.id = 0,
    this.title,
    this.description,
    this.status = false,
    this.deleted = false,
    required this.databaseHelper,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status ? 1 : 0,
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      status: map['status'] == 1,
      deleted: false,
      databaseHelper: DatabaseHelper.instance,
    );
  }

  Future<void> insert() async {
    final db = await databaseHelper.database;
    final maxIdResult = await db.rawQuery('SELECT MAX(id) as maxId FROM goals');
    final int maxId = maxIdResult.first['maxId'] as int? ?? 0;
    id = maxId + 1;
    await db.insert('goals', toMap());
  }

  Future<void> update() async {
    final db = await databaseHelper.database;
    await db.update(
      'goals',
      toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );

    final List<Map<String, dynamic>> maps = await db.query('goals');
    final int completedGoals = maps.where((goal) => goal['status'] == 1).length;

    await databaseHelper.updateCompletedGoals(completedGoals);
  }


  Future<void> updateTitleAndDescription(String newTitle, String newDescription) async {
    title = newTitle;
    description = newDescription;
    await update();
  }

  Future<void> delete() async {
    final db = await databaseHelper.database;
    await db.delete(DatabaseHelper.table, where: 'id = ?', whereArgs: [id]);
  }


}
