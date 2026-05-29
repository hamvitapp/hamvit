class RecipeIngredient {
  final String id;
  final String recipeId;
  final String? foodId;
  final String? ingredientText;
  final double? quantity;
  final double? grams;
  final String? portionLabel;

  const RecipeIngredient({
    required this.id,
    required this.recipeId,
    this.foodId,
    this.ingredientText,
    this.quantity,
    this.grams,
    this.portionLabel,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      id: json['id']?.toString() ?? '',
      recipeId: json['recipe_id']?.toString() ?? '',
      foodId: json['food_id']?.toString(),
      ingredientText: json['ingredient_text']?.toString(),
      quantity: _toDouble(json['quantity']),
      grams: _toDouble(json['grams']),
      portionLabel: json['portion_label']?.toString(),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    final normalized = value.toString().replaceAll(',', '.');
    return double.tryParse(normalized);
  }
}