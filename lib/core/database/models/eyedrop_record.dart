class EyedropRecord {
  final int? id;
  final String date;
  final bool completed;
  final String? completedAt;
  final String createdAt;
  final String updatedAt;

  EyedropRecord({
    this.id,
    required this.date,
    required this.completed,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'completed': completed ? 1 : 0,
      'completed_at': completedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory EyedropRecord.fromMap(Map<String, dynamic> map) {
    return EyedropRecord(
      id: map['id'],
      date: map['date'],
      completed: map['completed'] == 1,
      completedAt: map['completed_at'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  EyedropRecord copyWith({
    int? id,
    String? date,
    bool? completed,
    String? completedAt,
    String? createdAt,
    String? updatedAt,
  }) {
    return EyedropRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
