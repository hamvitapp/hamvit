class HabitModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String frequency;
  final bool active;
  final bool doneToday;
  final int currentStreak;
  final int bestStreak;

  const HabitModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.frequency,
    required this.active,
    required this.doneToday,
    required this.currentStreak,
    required this.bestStreak,
  });

  HabitModel copyWith({
    String? title,
    String? description,
    String? category,
    String? frequency,
    bool? active,
    bool? doneToday,
    int? currentStreak,
    int? bestStreak,
  }) {
    return HabitModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      active: active ?? this.active,
      doneToday: doneToday ?? this.doneToday,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
    );
  }

  static HabitModel fromMap(Map<String, dynamic> map) {
    return HabitModel(
      id: map['id'].toString(),
      title: (map['title'] ?? map['name'] ?? 'Hábito').toString(),
      description: (map['description'] ?? '').toString(),
      category: (map['category'] ?? 'Saúde').toString(),
      frequency: (map['frequency'] ?? 'Diário').toString(),
      active: map['active'] is bool ? map['active'] as bool : true,
      doneToday: false,
      currentStreak: (map['current_streak'] as num?)?.toInt() ?? 0,
      bestStreak: (map['best_streak'] as num?)?.toInt() ?? 0,
    );
  }
}

class HabitTemplate {
  final String title;
  final String category;
  final String description;
  final String frequency;

  const HabitTemplate({
    required this.title,
    required this.category,
    required this.description,
    required this.frequency,
  });
}

class HabitsDailySummary {
  final int total;
  final int completed;
  final int currentStreak;
  final int bestStreak;

  const HabitsDailySummary({
    required this.total,
    required this.completed,
    required this.currentStreak,
    required this.bestStreak,
  });

  double get progress => total == 0 ? 0 : completed / total;
}
