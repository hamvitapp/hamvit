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
        _tile(context, 'Editar perfil', '/profile/edit'),
        _tile(context, 'Objetivos', '/profile/goals'),
        _tile(context, 'Dados corporais', '/profile/body-data'),
        _tile(context, 'Alimentação', '/nutrition/preferences'),
        _tile(context, 'Atividade Física', '/activities/preferences'),
        _tile(context, 'Hábitos', '/habits'),
        _tile(context, 'Sono', '/sleep/settings'),
        _tile(context, 'Hidratação', '/hydration/settings'),
        _tile(context, 'Preferências', '/settings/preferences'),
      ],
    );
  }
}
