import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart'; // NOVO
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Function(bool?) onCheckboxChanged;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onDelete,
    required this.onCheckboxChanged,
  });

  Color _getPriorityColor() {
    switch (task.priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon() {
    switch (task.priority) {
      case 'urgent':
        return Icons.priority_high;
      case 'high':
        return Icons.arrow_upward;
      case 'medium':
        return Icons.remove;
      case 'low':
        return Icons.arrow_downward;
      default:
        return Icons.flag;
    }
  }

  String _getPriorityLabel() {
    switch (task.priority) {
      case 'urgent':
        return 'Urgente';
      case 'high':
        return 'Alta';
      case 'medium':
        return 'Média';
      case 'low':
        return 'Baixa';
      default:
        return 'Normal';
    }
  }

  // NOVO: Método para compartilhar
  Future<void> _shareTask() async {
    try {
      await Share.share(task.shareText);
    } catch (e) {
      // Erro silencioso - não mostra mensagem
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color priorityColor = _getPriorityColor();
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: task.completed 
            ? Colors.grey.shade300 
            : (task.isOverdue ? Colors.red : priorityColor.withOpacity(0.3)),
          width: task.isOverdue ? 3 : 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: task.completed,
                    onChanged: onCheckboxChanged,
                    activeColor: Colors.green,
                  ),
                  
                  const SizedBox(width: 8),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TÍTULO COM INDICADOR DE VENCIMENTO
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                task.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  decoration: task.completed 
                                    ? TextDecoration.lineThrough 
                                    : null,
                                  color: task.completed 
                                    ? Colors.grey 
                                    : (task.isOverdue ? Colors.red : Colors.black87),
                                ),
                              ),
                            ),
                            if (task.isOverdue)
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(
                                  Icons.warning_amber,
                                  color: Colors.red,
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                        
                        if (task.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: task.completed 
                                ? Colors.grey 
                                : Colors.black54,
                            ),
                          ),
                        ],
                        
                        // NOVO: INFO DE VENCIMENTO
                        if (task.dueDate != null && !task.completed) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getDueDateColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getDueDateColor().withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 12,
                                  color: _getDueDateColor(),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getDueDateText(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _getDueDateColor(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 8),
                        
                        // BADGES
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // Prioridade
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: priorityColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: priorityColor.withOpacity(0.5),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getPriorityIcon(),
                                    size: 14,
                                    color: priorityColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getPriorityLabel(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: priorityColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Foto
                            if (task.hasPhoto)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.5),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.photo_camera,
                                      size: 14,
                                      color: Colors.blue,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Foto',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            // Localização
                            if (task.hasLocation)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.purple.withOpacity(0.5),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 14,
                                      color: Colors.purple,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Local',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.purple,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            // Shake
                            if (task.completed && task.wasCompletedByShake)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.5),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.vibration,
                                      size: 14,
                                      color: Colors.green,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Shake',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // BOTÕES DE AÇÃO
                  Column(
                    children: [
                      // NOVO: Botão de compartilhar
                      IconButton(
                        onPressed: _shareTask,
                        icon: const Icon(Icons.share),
                        color: Colors.blue,
                        tooltip: 'Compartilhar',
                        iconSize: 20,
                      ),
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.red,
                        tooltip: 'Deletar',
                        iconSize: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // PREVIEW DA FOTO
            if (task.hasPhoto)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: Image.file(
                  File(task.photoPath!),
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 180,
                      color: Colors.grey[200],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Foto não encontrada',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // NOVO: Cor baseada na data de vencimento
  Color _getDueDateColor() {
    if (task.completed) return Colors.green;
    if (task.isOverdue) return Colors.red;
    if (task.isDueToday) return Colors.orange;
    if (task.isDueSoon) return Colors.amber;
    return Colors.green;
  }

  // NOVO: Texto baseado na data de vencimento
  String _getDueDateText() {
    if (task.completed) return 'Concluída';
    if (task.isOverdue) {
      final days = DateTime.now().difference(task.dueDate!).inDays;
      return 'Vencida há ${days + 1} dias';
    }
    if (task.isDueToday) return 'Vence hoje';
    
    final days = task.dueDate!.difference(DateTime.now()).inDays;
    return 'Vence em $days dias';
  }
}