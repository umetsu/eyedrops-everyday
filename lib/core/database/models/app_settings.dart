class AppSettings {
  final String key;
  final String value;
  final String updatedAt;

  AppSettings({
    required this.key,
    required this.value,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'value': value,
      'updated_at': updatedAt,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      key: map['key'],
      value: map['value'],
      updatedAt: map['updated_at'],
    );
  }

  AppSettings copyWith({
    String? key,
    String? value,
    String? updatedAt,
  }) {
    return AppSettings(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
