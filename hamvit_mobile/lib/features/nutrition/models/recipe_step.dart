class RecipeStep {
  final String id;
  final String recipeId;
  final int stepOrder;
  final String instruction;

  const RecipeStep({
    required this.id,
    required this.recipeId,
    required this.stepOrder,
    required this.instruction,
  });

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      id: json['id']?.toString() ?? '',
      recipeId: json['recipe_id']?.toString() ?? '',
      stepOrder: _toInt(json['step_order']),
      instruction: json['instruction']?.toString() ?? '',
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}