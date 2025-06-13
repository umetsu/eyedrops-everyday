class PressureRecord {
  final int? id;
  final String date;
  final double pressureValue;
  final String eyeType;
  final String measuredAt;
  final String createdAt;
  final String updatedAt;

  PressureRecord({
    this.id,
    required this.date,
    required this.pressureValue,
    required this.eyeType,
    required this.measuredAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'pressure_value': pressureValue,
      'eye_type': eyeType,
      'measured_at': measuredAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory PressureRecord.fromMap(Map<String, dynamic> map) {
    return PressureRecord(
      id: map['id'],
      date: map['date'],
      pressureValue: map['pressure_value']?.toDouble() ?? 0.0,
      eyeType: map['eye_type'],
      measuredAt: map['measured_at'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  PressureRecord copyWith({
    int? id,
    String? date,
    double? pressureValue,
    String? eyeType,
    String? measuredAt,
    String? createdAt,
    String? updatedAt,
  }) {
    return PressureRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      pressureValue: pressureValue ?? this.pressureValue,
      eyeType: eyeType ?? this.eyeType,
      measuredAt: measuredAt ?? this.measuredAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
