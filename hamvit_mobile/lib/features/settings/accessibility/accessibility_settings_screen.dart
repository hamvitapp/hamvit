import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_repository.dart';
import '../providers/accessibility_preferences_provider.dart';
import '../widgets/hamvit_settings_components.dart';

class AccessibilitySettingsScreen extends ConsumerStatefulWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  ConsumerState<AccessibilitySettingsScreen> createState() => _AccessibilitySettingsScreenState();
}

class _AccessibilitySettingsScreenState extends ConsumerState<AccessibilitySettingsScreen> {
  Future<void> _save(AccessibilitySettingsData next) async {
    try {
      await ref.read(accessibilityPreferencesProvider.notifier).save(next);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferência de acessibilidade salva.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar preferência.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(accessibilityPreferencesProvider);

    return HamvitSettingsScreen(
      title: 'Acessibilidade',
      subtitle: 'Ajuste leitura, contraste, movimento e simplificação para uma experiência mais confortável.',
      children: [
        async.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => HamvitSettingsInfoCard(
            icon: Icons.error_outline,
            title: 'Erro ao carregar acessibilidade',
            description: error.toString(),
          ),
          data: (prefs) {
            return Column(
              children: [
                HamvitSettingsSection(
                  title: 'Tamanho do texto',
                  children: [
                    RadioListTile<String>(
                      value: 'padrao',
                      groupValue: prefs.textSize,
                      onChanged: (value) {
                        if (value == null) return;
                        _save(prefs.copyWith(textSize: value));
                      },
                      title: const Text('Padrão'),
                    ),
                    RadioListTile<String>(
                      value: 'grande',
                      groupValue: prefs.textSize,
                      onChanged: (value) {
                        if (value == null) return;
                        _save(prefs.copyWith(textSize: value));
                      },
                      title: const Text('Grande'),
                    ),
                    RadioListTile<String>(
                      value: 'muito_grande',
                      groupValue: prefs.textSize,
                      onChanged: (value) {
                        if (value == null) return;
                        _save(prefs.copyWith(textSize: value));
                      },
                      title: const Text('Muito grande'),
                    ),
                  ],
                ),
                HamvitSettingsSection(
                  title: 'Leitura e navegação',
                  children: [
                    HamvitSettingsSwitchTile(
                      icon: Icons.contrast_outlined,
                      title: 'Alto contraste',
                      value: prefs.highContrast,
                      onChanged: (v) => _save(prefs.copyWith(highContrast: v)),
                    ),
                    HamvitSettingsSwitchTile(
                      icon: Icons.animation_outlined,
                      title: 'Reduzir animações',
                      value: prefs.reduceMotion,
                      onChanged: (v) => _save(prefs.copyWith(reduceMotion: v)),
                    ),
                    HamvitSettingsSwitchTile(
                      icon: Icons.view_agenda_outlined,
                      title: 'Modo simples',
                      subtitle: 'Mostra menos informações por tela e prioriza botões maiores.',
                      value: prefs.simpleMode,
                      onChanged: (v) => _save(prefs.copyWith(simpleMode: v)),
                    ),
                    HamvitSettingsSwitchTile(
                      icon: Icons.smart_button_outlined,
                      title: 'Botões maiores',
                      value: prefs.largerButtons,
                      onChanged: (v) => _save(prefs.copyWith(largerButtons: v)),
                    ),
                    HamvitSettingsSwitchTile(
                      icon: Icons.short_text_outlined,
                      title: 'Descrições mais simples',
                      value: prefs.simplifiedLanguage,
                      onChanged: (v) => _save(prefs.copyWith(simplifiedLanguage: v)),
                    ),
                  ],
                ),
                const HamvitSettingsInfoCard(
                  icon: Icons.info_outline,
                  title: 'Aplicação global',
                  description:
                      'As preferências já são salvas no perfil. A aplicação completa em todas as telas será ampliada nas próximas iterações.',
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
