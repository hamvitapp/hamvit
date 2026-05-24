class FoodPreferencesModel {
  final String? id;
  final List<String> eatingStyles;
  final List<String> restrictions;
  final List<String> dislikedFoods;
  final List<String> favoriteFoods;
  final int? mealsPerDay;
  final String? cookingFrequency;
  final String? prepTimePreference;
  final String? lunchboxHabit;
  final List<String> foodGoals;
  final List<String> usualMeals;
  final Map<String, String> mealTimes;
  final List<String> suggestionStyle;

  const FoodPreferencesModel({
    this.id,
    this.eatingStyles = const [],
    this.restrictions = const [],
    this.dislikedFoods = const [],
    this.favoriteFoods = const [],
    this.mealsPerDay,
    this.cookingFrequency,
    this.prepTimePreference,
    this.lunchboxHabit,
    this.foodGoals = const [],
    this.usualMeals = const [],
    this.mealTimes = const {},
    this.suggestionStyle = const [],
  });

  static const empty = FoodPreferencesModel();

  FoodPreferencesModel copyWith({
    String? id,
    List<String>? eatingStyles,
    List<String>? restrictions,
    List<String>? dislikedFoods,
    List<String>? favoriteFoods,
    int? mealsPerDay,
    String? cookingFrequency,
    String? prepTimePreference,
    String? lunchboxHabit,
    List<String>? foodGoals,
    List<String>? usualMeals,
    Map<String, String>? mealTimes,
    List<String>? suggestionStyle,
  }) {
    return FoodPreferencesModel(
      id: id ?? this.id,
      eatingStyles: eatingStyles ?? this.eatingStyles,
      restrictions: restrictions ?? this.restrictions,
      dislikedFoods: dislikedFoods ?? this.dislikedFoods,
      favoriteFoods: favoriteFoods ?? this.favoriteFoods,
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
      cookingFrequency: cookingFrequency ?? this.cookingFrequency,
      prepTimePreference: prepTimePreference ?? this.prepTimePreference,
      lunchboxHabit: lunchboxHabit ?? this.lunchboxHabit,
      foodGoals: foodGoals ?? this.foodGoals,
      usualMeals: usualMeals ?? this.usualMeals,
      mealTimes: mealTimes ?? this.mealTimes,
      suggestionStyle: suggestionStyle ?? this.suggestionStyle,
    );
  }

  Map<String, dynamic> toDbMap(String userId) {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'eating_styles': eatingStyles,
      'restrictions': restrictions,
      'disliked_foods': dislikedFoods,
      'favorite_foods': favoriteFoods,
      'meals_per_day': mealsPerDay,
      'cooking_frequency': cookingFrequency,
      'prep_time_preference': prepTimePreference,
      'lunchbox_habit': lunchboxHabit,
      'food_goals': foodGoals,
      'usual_meals': usualMeals,
      'meal_times': mealTimes,
      'suggestion_style': suggestionStyle,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory FoodPreferencesModel.fromMap(Map<String, dynamic> map) {
    return FoodPreferencesModel(
      id: map['id']?.toString(),
      eatingStyles: _asStringList(map['eating_styles']),
      restrictions: _asStringList(map['restrictions']),
      dislikedFoods: _asStringList(map['disliked_foods']),
      favoriteFoods: _asStringList(map['favorite_foods']),
      mealsPerDay: _asInt(map['meals_per_day']),
      cookingFrequency: _asString(map['cooking_frequency']),
      prepTimePreference: _asString(map['prep_time_preference']),
      lunchboxHabit: _asString(map['lunchbox_habit']),
      foodGoals: _asStringList(map['food_goals']),
      usualMeals: _asStringList(map['usual_meals']),
      mealTimes: _asStringMap(map['meal_times']),
      suggestionStyle: _asStringList(map['suggestion_style']),
    );
  }

  static List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString().trim()).where((item) => item.isNotEmpty).toList();
    }
    return const [];
  }

  static Map<String, String> _asStringMap(dynamic value) {
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item.toString()));
    }
    return const {};
  }

  static String? _asString(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
