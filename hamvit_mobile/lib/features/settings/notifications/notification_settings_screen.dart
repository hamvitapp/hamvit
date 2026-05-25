import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/notification_preferences_provider.dart';
import '../widgets/hamvit_settings_components.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Não definido';
    return MaterialLocalizations.of(context).formatTimeOfDay(
      time,
      alwaysUse24HourFormat: true,
    );
  }

  String _label(String key) {
    switch (key) {
      case 'agua':
        return 'Água';
      case 'refeicoes':
        return 'Refeições';
      case 'habitos':
        return 'Hábitos';
      case 'treino_caminhada':
        return 'Treino / caminhada';
      case 'sono':
        return 'Sono';
      case 'relatorios':
        return 'Relatórios';
      case 'premium_pagamentos':
        return 'Premium e pagamentos';
      case 'ia_pendente':
        return 'Revisão de IA pendente';
      default:
        return key;
    }
  }

  Future<void> _pickTime(String category) async {
    final notifier = ref.read(notificationPreferencesProvider.notifier);
    final current = ref.read(notificationPreferencesProvider).valueOrNull;
    if (current == null) return;

    final initial = current.categories[category]?.reminderTime ?? const TimeOfDay(hour: 9, minute: 0);

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: 'Escolha o horário preferido',
      cancelText: 'Cancelar',
      confirmText: 'Salvar',
    );

    if (picked == null) return;

    try {
      await notifier.setReminderTime(category, picked);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Horário de ${_label(category)} atualizado.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar o horário.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(notificationPreferencesProvider);

    return HamvitSettingsScreen(
      title: 'Notificações',
      subtitle: 'Controle lembretes, categorias e horários com linguagem acolhedora.',
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
            title: 'Erro ao carregar notificações',
            description: error.toString(),
          ),
          data: (settings) {
            final notifier = ref.read(notificationPreferencesProvider.notifier);
            return Column(
              children: [
                HamvitSettingsSection(
                  title: 'Notificações gerais',
                  children: [
                    HamvitSettingsSwitchTile(
                      icon: Icons.notifications_active_outlined,
                      title: 'Ativar notificações',
                      subtitle: 'Liga ou desliga os lembretes do HAMVIT',
                      value: settings.enabled,
                      onChanged: (value) async {
                        try {
                          await notifier.setGeneralEnabled(value);
                        } catch (_) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(content: Text('Falha ao atualizar notificação geral.')),
                          );
                        }
                      },
                    ),
                  ],
                ),
                HamvitSettingsSection(
                  title: 'Categorias',
                  children: [
                    for (final entry in settings.categories.entries)
                      HamvitSettingsSwitchTile(
                        icon: Icons.notifications_none_outlined,
                        title: _label(entry.key),
                        value: entry.value.enabled,
                        onChanged: settings.enabled
                            ? (value) async {
                                try {
                                  await notifier.setCategoryEnabled(entry.key, value);
                                } catch (_) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(content: Text('Falha ao atualizar ${_label(entry.key)}.')),
                                  );
                                }
                              }
                            : null,
                      ),
                  ],
                ),
                HamvitSettingsSection(
                  title: 'Horários preferidos',
                  subtitle: 'Escolha pelo seletor de horário do sistema.',
                  children: [
                    HamvitSettingsActionTile(
                      icon: Icons.water_drop_outlined,
                      title: 'Lembrete de água',
                      subtitle: _formatTime(settings.categories['agua']?.reminderTime),
                      onTap: settings.enabled ? () => _pickTime('agua') : null,
                    ),
                    HamvitSettingsActionTile(
                      icon: Icons.restaurant_outlined,
                      title: 'Lembrete de refeição',
                      subtitle: _formatTime(settings.categories['refeicoes']?.reminderTime),
                      onTap: settings.enabled ? () => _pickTime('refeicoes') : null,
                    ),
                    HamvitSettingsActionTile(
                      icon: Icons.directions_walk_outlined,
                      title: 'Lembrete de treino',
                      subtitle: _formatTime(settings.categories['treino_caminhada']?.reminderTime),
                      onTap: settings.enabled ? () => _pickTime('treino_caminhada') : null,
                    ),
                    HamvitSettingsActionTile(
                      icon: Icons.bedtime_outlined,
                      title: 'Lembrete de sono',
                      subtitle: _formatTime(settings.categories['sono']?.reminderTime),
                      onTap: settings.enabled ? () => _pickTime('sono') : null,
                    ),
                  ],
                ),
                const HamvitSettingsInfoCard(
                  icon: Icons.favorite_outline,
                  title: 'Tom das notificações',
                  description: 'Os lembretes do HAMVIT usam linguagem acolhedora e sem culpa.',
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
