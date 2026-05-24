import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MyProfileHubScreen extends StatelessWidget {
  const MyProfileHubScreen({super.key});

  Widget _tile(BuildContext context, String title, String route) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go(route),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Meu Perfil', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 10),
        _tile(context, 'Objetivos', '/onboarding/objectives'),
        _tile(context, 'Alimentação', '/onboarding/food'),
        _tile(context, 'Atividade Física', '/onboarding/activity'),
        _tile(context, 'Hábitos', '/habits'),
        _tile(context, 'Sono', '/onboarding/sleep'),
        _tile(context, 'Preferências', '/onboarding/hydration'),
      ],
    );
  }
}
