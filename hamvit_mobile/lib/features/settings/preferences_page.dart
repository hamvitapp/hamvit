import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/hamvit_module_widgets.dart';

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({super.key});

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  bool _darkTheme = false;
  bool _notifications = true;
  bool _privacyMode = true;
  bool _highContrast = false;
  String _unit = 'Métrico';
  String _language = 'Português (Brasil)';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const HamvitSectionHeader(
          title: 'Preferências',
          subtitle: 'Configurações gerais do app, lembretes, privacidade e acessibilidade.',
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          value: _darkTheme,
          onChanged: (value) => setState(() => _darkTheme = value),
          title: const Text('Aparência/Tema'),
          subtitle: const Text('Alternar entre modo claro e modo escuro.'),
        ),
        SwitchListTile(
          value: _notifications,
          onChanged: (value) => setState(() => _notifications = value),
          title: const Text('Notificações'),
          subtitle: const Text('Lembretes de refeições, água, sono e atividades.'),
        ),
        ListTile(
          title: const Text('Unidades de medida'),
          subtitle: Text(_unit),
          trailing: DropdownButton<String>(
            value: _unit,
            items: const [
              DropdownMenuItem(value: 'Métrico', child: Text('Métrico')),
              DropdownMenuItem(value: 'Imperial', child: Text('Imperial')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _unit = value);
              }
            },
          ),
        ),
        ListTile(
          title: const Text('Idioma'),
          subtitle: Text(_language),
          trailing: DropdownButton<String>(
            value: _language,
            items: const [
              DropdownMenuItem(value: 'Português (Brasil)', child: Text('Português (Brasil)')),
              DropdownMenuItem(value: 'English', child: Text('English')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _language = value);
              }
            },
          ),
        ),
        SwitchListTile(
          value: _privacyMode,
          onChanged: (value) => setState(() => _privacyMode = value),
          title: const Text('Preferências de privacidade'),
          subtitle: const Text('Controle compartilhamento de dados para recomendações.'),
        ),
        ListTile(
          title: const Text('Preferências alimentares'),
          subtitle: const Text('Editar preferências e restrições usadas nas sugestões.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go('/nutrition/preferences'),
        ),
        ListTile(
          title: const Text('Preferências de lembretes'),
          subtitle: const Text('Gerenciar horários de notificações por módulo.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        SwitchListTile(
          value: _highContrast,
          onChanged: (value) => setState(() => _highContrast = value),
          title: const Text('Acessibilidade'),
          subtitle: const Text('Alto contraste e ajustes de leitura.'),
        ),
        ListTile(
          title: const Text('Meta de água'),
          subtitle: const Text('Ajuste a meta no módulo de hidratação.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go('/hydration'),
        ),
      ],
    );
  }
}
