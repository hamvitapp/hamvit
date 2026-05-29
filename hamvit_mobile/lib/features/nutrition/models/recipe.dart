class Recipe {
  final String id;
  final String name;
  final String? description;
  final String? category;
  final int? prepTimeMinutes;
  final int? servings;
  final String? imageUrl;
  final double? caloriesKcal;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final bool premiumOnly;
  final String? difficulty;
  final String? source;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? matchReason;
  final double? score;
  final List<String> tags;
  final bool isFavorited;

  const Recipe({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.prepTimeMinutes,
    this.servings,
    this.imageUrl,
    this.caloriesKcal,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.premiumOnly = false,
    this.difficulty,
    this.source,
    this.createdAt,
    this.updatedAt,
    this.matchReason,
    this.score,
    this.tags = const [],
    this.isFavorited = false,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      category: json['category']?.toString(),
      prepTimeMinutes: _toInt(json['prep_time_minutes'] ?? json['prep_time_min']),
      servings: _toInt(json['servings']),
      imageUrl: json['image_url']?.toString(),
      caloriesKcal: _toDouble(json['calories_kcal']),
      proteinG: _toDouble(json['protein_g']),
      carbsG: _toDouble(json['carbs_g']),
      fatG: _toDouble(json['fat_g']),
      premiumOnly: json['premium_only'] == true,
      difficulty: json['difficulty']?.toString(),
      source: json['source']?.toString(),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      matchReason: json['match_reason']?.toString(),
      score: _toDouble(json['score']),
      tags: json['tags'] != null
          ? (json['tags'] as List<dynamic>).map((e) => e.toString()).toList()
          : const [],
      isFavorited: json['is_favorited'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'category': category,
    'prep_time_minutes': prepTimeMinutes,
    'servings': servings,
    'image_url': imageUrl,
    'calories_kcal': caloriesKcal,
    'protein_g': proteinG,
    'carbs_g': carbsG,
    'fat_g': fatG,
    'premium_only': premiumOnly,
    'difficulty': difficulty,
    'source': source,
  };

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.round();
    final parsed = double.tryParse(value.toString().replaceAll(',', '.'));
    return parsed?.round() ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    final normalized = value.toString().replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0.0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  Recipe copyWith({
    bool? isFavorited,
    double? score,
    String? matchReason,
  }) {
    return Recipe(
      id: id,
      name: name,
      description: description,
      category: category,
      prepTimeMinutes: prepTimeMinutes,
      servings: servings,
      imageUrl: imageUrl,
      caloriesKcal: caloriesKcal,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      premiumOnly: premiumOnly,
      difficulty: difficulty,
      source: source,
      createdAt: createdAt,
      updatedAt: updatedAt,
      matchReason: matchReason ?? this.matchReason,
      score: score ?? this.score,
      tags: tags,
      isFavorited: isFavorited ?? this.isFavorited,
    );
  }
}