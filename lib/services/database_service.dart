import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tasks.db');
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
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        completed INTEGER NOT NULL DEFAULT 0,
        priority TEXT NOT NULL DEFAULT 'medium',
        created_at INTEGER NOT NULL
      )
    ''');

    // Inserir tarefas de exemplo
    await _insertSampleTasks(db);
  }

  Future<void> _insertSampleTasks(Database db) async {
    final sampleTasks = [
      Task(
        title: 'Bem-vindo ao Task Manager!',
        description: 'Esta é sua primeira tarefa. Toque para editar ou marcar como concluída.',
        priority: 'medium',
      ),
      Task(
        title: 'Estudar Flutter',
        description: 'Aprender sobre widgets e estado',
        priority: 'high',
      ),
      Task(
        title: 'Fazer compras',
        description: 'Comprar itens para casa',
        priority: 'low',
        completed: true,
      ),
    ];

    for (final task in sampleTasks) {
      await db.insert('tasks', task.toMap());
    }
  }

  Future<Task> create(Task task) async {
    final db = await database;
    final id = await db.insert('tasks', task.toMap());
    return task.copyWith(id: id);
  }

  Future<Task> read(int id) async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Task.fromMap(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<Task>> readAll() async {
    final db = await database;
    final orderBy = 'created_at DESC';
    final result = await db.query('tasks', orderBy: orderBy);
    return result.map((json) => Task.fromMap(json)).toList();
  }

  Future<List<Task>> readByStatus(bool completed) async {
    final db = await database;
    final result = await db.query(
      'tasks',
      where: 'completed = ?',
      whereArgs: [completed ? 1 : 0],
      orderBy: 'created_at DESC',
    );
    return result.map((json) => Task.fromMap(json)).toList();
  }

  Future<int> update(Task task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAll() async {
    final db = await database;
    return await db.delete('tasks');
  }

  Future<int> getTaskCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM tasks');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getCompletedCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM tasks WHERE completed = 1'
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}