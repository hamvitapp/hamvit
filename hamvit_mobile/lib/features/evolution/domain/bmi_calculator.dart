class BmiCalculator {
  static double? calculate({required double? weightKg, required int? heightCm}) {
    if (weightKg == null || heightCm == null || weightKg <= 0 || heightCm <= 0) {
      return null;
    }
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  static String classify(double? bmi) {
    if (bmi == null) return 'Nao disponivel';
    if (bmi < 18.5) return 'Abaixo do peso';
    if (bmi < 25) return 'Faixa considerada adequada';
    if (bmi < 30) return 'Sobrepeso';
    if (bmi < 35) return 'Obesidade grau 1';
    if (bmi < 40) return 'Obesidade grau 2';
    return 'Obesidade grau 3';
  }
}