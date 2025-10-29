import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../services/sensor_service.dart';
import '../services/location_service.dart';
import '../screens/task_form_screen.dart';
import '../widgets/task_card.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  String _filter = 'all';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _setupShakeDetection();
    _checkOverdueTasks();
  }

  @override
  void dispose() {
    SensorService.instance.stop();
    super.dispose();
  }

  void _setupShakeDetection() {
    SensorService.instance.startShakeDetection(() {
      _showShakeDialog();
    });
  }

  // NOVO: Verificar tarefas vencidas ao iniciar
  void _checkOverdueTasks() async {
    await Future.delayed(const Duration(seconds: 1)); // Aguardar carregamento
    
    final overdueTasks = await DatabaseService.instance.getOverdueTasks();
    
    if (overdueTasks.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ ${overdueTasks.length} tarefa(s) vencida(s)'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Ver',
            textColor: Colors.white,
            onPressed: () {
              setState(() => _filter = 'pending');
            },
          ),
        ),
      );
    }
  }

  void _showShakeDialog() {
    final List<Task> pendingTasks = _tasks.where((t) => !t.completed).toList();
    
    if (pendingTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Nenhuma tarefa pendente!'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.vibration, color: Colors.blue),
            SizedBox(width: 8),
            Text('Shake detectado!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selecione uma tarefa para completar:'),
            const SizedBox(height: 16),
            ...pendingTasks.take(3).map((task) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                task.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: task.dueDate != null ? Text(
                'Vence: ${_formatDate(task.dueDate!)}',
                style: TextStyle(
                  color: task.isOverdue ? Colors.red : null,
                ),
              ) : null,
              trailing: IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: () => _completeTaskByShake(task),
              ),
            )),
            if (pendingTasks.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+ ${pendingTasks.length - 3} outras',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeTaskByShake(Task task) async {
    try {
      final Task updated = task.copyWith(
        completed: true,
        completedAt: DateTime.now(),
        completedBy: 'shake',
      );

      await DatabaseService.instance.update(updated);
      Navigator.pop(context);
      await _loadTasks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ "${task.title}" completa via shake!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);

    try {
      final List<Task> tasks = await DatabaseService.instance.readAll();
      
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Task> get _filteredTasks {
    switch (_filter) {
      case 'pending':
        return _tasks.where((t) => !t.completed).toList();
      case 'completed':
        return _tasks.where((t) => t.completed).toList();
      default:
        return _tasks;
    }
  }

  Map<String, int> get _statistics {
    final int total = _tasks.length;
    final int completed = _tasks.where((t) => t.completed).length;
    final int pending = total - completed;
    final int overdue = _tasks.where((t) => t.isOverdue).length;
    
    return {
      'total': total,
      'completed': completed,
      'pending': pending,
      'overdue': overdue, // NOVO
    };
  }

  Future<void> _deleteTask(Task task) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja deletar "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await DatabaseService.instance.delete(task.id!);
        await _loadTasks();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🗑️ Tarefa deletada'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleComplete(Task task) async {
    try {
      final Task updated = task.copyWith(
        completed: !task.completed,
        completedAt: !task.completed ? DateTime.now() : null,
        completedBy: !task.completed ? 'manual' : null,
      );

      await DatabaseService.instance.update(updated);
      await _loadTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openTaskForm([Task? task]) async {
    final bool? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskFormScreen(task: task),
      ),
    );

    if (result == true) {
      await _loadTasks();
    }
  }

  // NOVO: Formatar data
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, int> stats = _statistics;
    final List<Task> filteredTasks = _filteredTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager Pro'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // NOVO: Indicador de tarefas vencidas
          if (stats['overdue']! > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Badge.count(
                count: stats['overdue']!,
                backgroundColor: Colors.red,
                textColor: Colors.white,
                child: const Icon(Icons.warning_amber),
              ),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (String value) {
              setState(() => _filter = value);
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.list_alt),
                    SizedBox(width: 8),
                    Text('Todas'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pending',
                child: Row(
                  children: [
                    Icon(Icons.pending_outlined),
                    SizedBox(width: 8),
                    Text('Pendentes'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'completed',
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline),
                    SizedBox(width: 8),
                    Text('Concluídas'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTasks,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // CARD DE ESTATÍSTICAS (ATUALIZADO)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade700],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          label: 'Total',
                          value: stats['total'].toString(),
                          icon: Icons.list_alt,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        _StatItem(
                          label: 'Concluídas',
                          value: stats['completed'].toString(),
                          icon: Icons.check_circle,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        _StatItem(
                          label: 'Pendentes',
                          value: stats['pending'].toString(),
                          icon: Icons.pending_actions,
                        ),
                        // NOVO: Estatística de vencidas
                        if (stats['overdue']! > 0) ...[
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          _StatItem(
                            label: 'Vencidas',
                            value: stats['overdue'].toString(),
                            icon: Icons.warning_amber,
                            isWarning: true,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // LISTA DE TAREFAS
                  Expanded(
                    child: filteredTasks.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredTasks.length,
                            itemBuilder: (context, int index) {
                              final Task task = filteredTasks[index];
                              return TaskCard(
                                task: task,
                                onTap: () => _openTaskForm(task),
                                onDelete: () => _deleteTask(task),
                                onCheckboxChanged: (bool? value) => _toggleComplete(task),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTaskForm(),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nova Tarefa'),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;

    switch (_filter) {
      case 'pending':
        message = '🎉 Nenhuma tarefa pendente!';
        icon = Icons.check_circle_outline;
        break;
      case 'completed':
        message = '📋 Nenhuma tarefa concluída ainda';
        icon = Icons.pending_outlined;
        break;
      default:
        message = '📝 Nenhuma tarefa ainda.\nToque em + para criar!';
        icon = Icons.add_task;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isWarning;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon, 
          color: isWarning ? Colors.amber : Colors.white, 
          size: 28
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: isWarning ? Colors.amber : Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isWarning ? Colors.amber.shade200 : Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}