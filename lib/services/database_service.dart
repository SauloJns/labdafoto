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
      version: 3, // ATUALIZADO: nova versão
      onCreate: _createDB,
      onUpgrade: _migrateDB,
      onDowngrade: onDatabaseDowngradeDelete, // NOVO: permite downgrade
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        priority TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        photo_path TEXT,
        completed_at INTEGER,
        completed_by TEXT,
        latitude REAL,
        longitude REAL,
        location_name TEXT,
        due_date INTEGER -- NOVO CAMPO
      )
    ''');

    await _insertSampleTasks(db);
  }

  Future<void> _migrateDB(Database db, int oldVersion, int newVersion) async {
    // Migração da versão 1 para 2
    if (oldVersion < 2) {
      try {
        await _addColumnIfNotExists(db, 'tasks', 'photo_path', 'TEXT');
        await _addColumnIfNotExists(db, 'tasks', 'completed_at', 'INTEGER');
        await _addColumnIfNotExists(db, 'tasks', 'completed_by', 'TEXT');
        await _addColumnIfNotExists(db, 'tasks', 'latitude', 'REAL');
        await _addColumnIfNotExists(db, 'tasks', 'longitude', 'REAL');
        await _addColumnIfNotExists(db, 'tasks', 'location_name', 'TEXT');
      } catch (e) {
        print('Erro na migração v1->v2: $e');
      }
    }
    
    // Migração da versão 2 para 3
    if (oldVersion < 3) {
      try {
        await _addColumnIfNotExists(db, 'tasks', 'due_date', 'INTEGER');
      } catch (e) {
        print('Erro na migração v2->v3: $e');
      }
    }
  }

  // NOVO: Método auxiliar para adicionar colunas apenas se não existirem
  Future<void> _addColumnIfNotExists(
    Database db, 
    String table, 
    String column, 
    String type
  ) async {
    // Verifica se a coluna já existe
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final columnExists = columns.any((col) => col['name'] == column);
    
    if (!columnExists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
      print('Coluna $column adicionada à tabela $table');
    } else {
      print('Coluna $column já existe na tabela $table');
    }
  }

  Future<void> _insertSampleTasks(Database db) async {
    final sampleTasks = [
      Task(
        title: 'Bem-vindo ao Task Manager Pro!',
        description: 'Esta é sua primeira tarefa. Toque para editar ou marcar como concluída.',
        priority: 'medium',
        dueDate: DateTime.now().add(const Duration(days: 7)), // EXEMPLO
      ),
      Task(
        title: 'Estudar Flutter - Recursos Nativos',
        description: 'Aprender sobre câmera, sensores e GPS',
        priority: 'high',
        dueDate: DateTime.now().add(const Duration(days: 2)),
      ),
      Task(
        title: 'Testar funcionalidade de Shake',
        description: 'Sacuda o celular para completar tarefas rapidamente!',
        priority: 'urgent',
        dueDate: DateTime.now().add(const Duration(days: 1)),
      ),
    ];

    for (final task in sampleTasks) {
      await db.insert('tasks', task.toMap());
    }
  }

  // MÉTODOS EXISTENTES (mantidos iguais)...
  Future<Task> create(Task task) async {
    final db = await database;
    final id = await db.insert('tasks', task.toMap());
    return task.copyWith(id: id);
  }

  Future<Task?> read(int id) async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Task.fromMap(maps.first);
    }
    return null;
  }

  // NOVO: Ordenar por data de vencimento
  Future<List<Task>> readAll() async {
    final db = await database;
    final orderBy = '''
      CASE 
        WHEN completed = 1 THEN 2
        WHEN due_date IS NULL THEN 1
        ELSE 0
      END,
      due_date ASC,
      created_at DESC
    ''';
    
    final result = await db.query('tasks', orderBy: orderBy);
    return result.map((json) => Task.fromMap(json)).toList();
  }

  Future<List<Task>> readByStatus(bool completed) async {
    final db = await database;
    final orderBy = completed 
        ? 'completed_at DESC'
        : 'due_date ASC, created_at DESC';
        
    final result = await db.query(
      'tasks',
      where: 'completed = ?',
      whereArgs: [completed ? 1 : 0],
      orderBy: orderBy,
    );
    return result.map((json) => Task.fromMap(json)).toList();
  }

  // NOVO: Buscar tarefas vencidas
  Future<List<Task>> getOverdueTasks() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final result = await db.query(
      'tasks',
      where: 'completed = 0 AND due_date IS NOT NULL AND due_date < ?',
      whereArgs: [now],
      orderBy: 'due_date ASC',
    );
    return result.map((json) => Task.fromMap(json)).toList();
  }

  // NOVO: Buscar tarefas que vencem hoje
  Future<List<Task>> getDueTodayTasks() async {
    final db = await database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).millisecondsSinceEpoch;
    
    final result = await db.query(
      'tasks',
      where: 'completed = 0 AND due_date IS NOT NULL AND due_date BETWEEN ? AND ?',
      whereArgs: [startOfDay, endOfDay],
      orderBy: 'due_date ASC',
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

  // NOVO: Contar tarefas vencidas
  Future<int> getOverdueCount() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM tasks WHERE completed = 0 AND due_date IS NOT NULL AND due_date < ?',
      [now]
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Task>> getTasksNearLocation({
    required double latitude,
    required double longitude,
    double radiusInMeters = 1000,
  }) async {
    final allTasks = await readAll();
    
    return allTasks.where((task) {
      if (!task.hasLocation) return false;
      
      final latDiff = (task.latitude! - latitude).abs();
      final lonDiff = (task.longitude! - longitude).abs();
      final distance = ((latDiff * 111000) + (lonDiff * 111000)) / 2;
      
      return distance <= radiusInMeters;
    }).toList();
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}