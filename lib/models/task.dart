class Task {
  final int? id;
  final String title;
  final String description;
  final bool completed;
  final String priority;
  final DateTime createdAt;
  
  // NOVOS CAMPOS AULA 3
  final String? photoPath;
  final DateTime? completedAt;
  final String? completedBy;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  
  // NOVO CAMPO: Data de vencimento
  final DateTime? dueDate;

  Task({
    this.id,
    required this.title,
    this.description = '',
    this.completed = false,
    this.priority = 'medium',
    DateTime? createdAt,
    this.photoPath,
    this.completedAt,
    this.completedBy,
    this.latitude,
    this.longitude,
    this.locationName,
    this.dueDate, // NOVO
  }) : createdAt = createdAt ?? DateTime.now();

  // GETTERS AUXILIARES
  bool get hasPhoto => photoPath != null && photoPath!.isNotEmpty;
  bool get hasLocation => latitude != null && longitude != null;
  bool get wasCompletedByShake => completedBy == 'shake';
  
  // NOVOS GETTERS
  bool get isOverdue => !completed && dueDate != null && dueDate!.isBefore(DateTime.now());
  bool get isDueToday => !completed && dueDate != null && 
      dueDate!.year == DateTime.now().year &&
      dueDate!.month == DateTime.now().month &&
      dueDate!.day == DateTime.now().day;
  bool get isDueSoon => !completed && dueDate != null && 
      dueDate!.isAfter(DateTime.now()) &&
      dueDate!.difference(DateTime.now()).inDays <= 3;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'completed': completed ? 1 : 0,
      'priority': priority,
      'created_at': createdAt.millisecondsSinceEpoch,
      'photo_path': photoPath,
      'completed_at': completedAt?.millisecondsSinceEpoch,
      'completed_by': completedBy,
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'due_date': dueDate?.millisecondsSinceEpoch, // NOVO
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      completed: map['completed'] == 1,
      priority: map['priority'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      photoPath: map['photo_path'],
      completedAt: map['completed_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['completed_at'])
          : null,
      completedBy: map['completed_by'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      locationName: map['location_name'],
      dueDate: map['due_date'] != null // NOVO
          ? DateTime.fromMillisecondsSinceEpoch(map['due_date'])
          : null,
    );
  }

  Task copyWith({
    int? id,
    String? title,
    String? description,
    bool? completed,
    String? priority,
    DateTime? createdAt,
    String? photoPath,
    DateTime? completedAt,
    String? completedBy,
    double? latitude,
    double? longitude,
    String? locationName,
    DateTime? dueDate, // NOVO
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      photoPath: photoPath ?? this.photoPath,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      dueDate: dueDate ?? this.dueDate, // NOVO
    );
  }

  // MÉTODO PARA COMPARTILHAR
  String get shareText {
    final buffer = StringBuffer();
    
    buffer.writeln('📋 $title');
    buffer.writeln();
    
    if (description.isNotEmpty) {
      buffer.writeln('📝 $description');
      buffer.writeln();
    }
    
    buffer.writeln('📊 Status: ${completed ? '✅ Concluída' : '⏳ Pendente'}');
    buffer.writeln('🎯 Prioridade: ${_getPriorityLabel()}');
    
    if (dueDate != null) {
      final now = DateTime.now();
      final difference = dueDate!.difference(now);
      
      String status;
      if (completed) {
        status = '✅ Concluída';
      } else if (dueDate!.isBefore(now)) {
        status = '🔴 Vencida';
      } else if (difference.inDays == 0) {
        status = '🟡 Vence hoje';
      } else if (difference.inDays <= 3) {
        status = '🟠 Vence em ${difference.inDays} dias';
      } else {
        status = '🟢 Vence em ${difference.inDays} dias';
      }
      
      buffer.writeln('📅 Vencimento: ${_formatDate(dueDate!)} ($status)');
    }
    
    if (hasLocation && locationName != null) {
      buffer.writeln('📍 Local: $locationName');
    }
    
    if (completed && completedAt != null) {
      buffer.writeln('✅ Concluída em: ${_formatDate(completedAt!)}');
    }
    
    buffer.writeln();
    buffer.writeln('Criado com Task Manager Pro 📱');
    
    return buffer.toString();
  }

  String _getPriorityLabel() {
    switch (priority) {
      case 'urgent': return '🔴 Urgente';
      case 'high': return '🟠 Alta';
      case 'medium': return '🟡 Média';
      case 'low': return '🟢 Baixa';
      default: return 'Normal';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, completed: $completed, priority: $priority, dueDate: $dueDate)';
  }
}