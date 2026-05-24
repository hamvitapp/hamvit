class AppUser {
  final String id;
  final String? name;
  final String plan;

  const AppUser({required this.id, this.name, required this.plan});

  bool get isPremium => plan == 'premium_lifetime';
}
