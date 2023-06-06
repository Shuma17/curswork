import 'package:flutter/material.dart';
import 'package:sqflite/sqlite_api.dart';
import 'database.dart';
import 'goal.dart';

void main() {
  runApp(MotivatorApp());
}

class MotivatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Motivator',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: GoalsScreen(),
    );
  }
}

class GoalsScreen extends StatefulWidget {
  @override
  _GoalsScreenState createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  List<Goal> _goals = [];

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final Database db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('goals');
    setState(() {
      _goals = List.generate(maps.length, (i) {
        return Goal.fromMap(maps[i]);
      });
    });
  }

  Future<void> _addGoal() async {
    final Goal goal = Goal(
      title: _titleController.text,
      description: _descriptionController.text,
      status: false,
      databaseHelper: _databaseHelper,
    );
    await goal.insert();
    _clearTextFields();

    // Update goals statistics
    final int totalGoals = _goals.length + 1;
    final int completedGoals = _goals.where((goal) => goal.status).length;
    final int uncompletedGoals = totalGoals - completedGoals;
    await _databaseHelper.updateGoalsStatistics(totalGoals, completedGoals, uncompletedGoals);

    _loadGoals();
  }

  void _deleteGoal(Goal goal) async {
    await goal.delete();

    _loadGoals();
  }

  void _clearTextFields() {
    _titleController.clear();
    _descriptionController.clear();
  }

  Future<void> _updateGoalStatus(Goal goal, bool newStatus) async {
    goal.status = newStatus;
    await goal.update();

    // Обновление статистики
    final int completedGoals = _goals.where((goal) => goal.status).length;
    final int totalGoals = _goals.length;
    final int uncompletedGoals = totalGoals - completedGoals;
    await _databaseHelper.updateGoalsStatistics(totalGoals, completedGoals, uncompletedGoals);

    _loadGoals();
  }

  Future<void> _editGoal(Goal goal) async {
    _titleController.text = goal.title!;
    _descriptionController.text = goal.description!;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await goal.updateTitleAndDescription(
                  _titleController.text,
                  _descriptionController.text,
                );
                _clearTextFields();
                Navigator.of(context).pop();
                _loadGoals();
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGoalItem(Goal goal) {
    return ListTile(
      title: Text(
        goal.title!,
        style: TextStyle(
          decoration: goal.status ? TextDecoration.lineThrough : TextDecoration.none,
        ),
      ),
      subtitle: Text(
        goal.description!,
        style: TextStyle(
          decoration: goal.status ? TextDecoration.lineThrough : TextDecoration.none,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _deleteGoal(goal),
          ),
          Checkbox(
            value: goal.status,
            onChanged: (value) async {
              await _updateGoalStatus(goal, value!);
            },
          ),
        ],
      ),
      onTap: () {
        _editGoal(goal);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Мотиватор'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _goals.length,
              itemBuilder: (context, index) {
                final goal = _goals[index];
                return _buildGoalItem(goal);
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(16.0),
            color: Colors.deepOrange,
            width: double.infinity,
            child: FutureBuilder<Map<String, dynamic>>(
              future: _databaseHelper.getGoalsStatistics(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  final totalGoals = snapshot.data!['total_goals'];
                  final completedGoals = snapshot.data!['completed_goals'];
                  final uncompletedGoals = snapshot.data!['uncompleted_goals'];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Всего целей: $totalGoals', style: TextStyle(color: Colors.white)),
                      Text('Выполненных целей: $completedGoals', style: TextStyle(color: Colors.white)),
                      Text('Невыполненных целей: $uncompletedGoals', style: TextStyle(color: Colors.white)),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Add Goal'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(labelText: 'Title'),
                    ),
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(labelText: 'Description'),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await _addGoal();
                      Navigator.of(context).pop();
                    },
                    child: Text('Add'),
                  ),
                ],
              );
            },
          );
          _loadGoals();
        },
          backgroundColor: Colors.yellow,
        child: Icon(Icons.add),
      ),
    );
  }
}
