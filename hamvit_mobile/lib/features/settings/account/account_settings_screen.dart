import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/hamvit_date_utils.dart';
import '../../auth/providers/auth_provider.dart';
import '../../security/biometric_gate.dart';
import '../providers/settings_provider.dart';
import '../widgets/hamvit_settings_components.dart';
import '../../profile/widgets/profile_photo_widget.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  bool _busy = false;

  Future<void> _runAction(Future<void> Function() action, String successMessage) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível concluir: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _editName(String currentName) async {
    final controller = TextEditingController(text: currentName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar nome'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nome exibido'),
          textInputAction: TextInputAction.done,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    await _runAction(() async {
      await ref.read(settingsRepositoryProvider).updateDisplayName(result);
      ref.invalidate(settingsAccountProvider);
    }, 'Nome atualizado com sucesso.');
  }

  Future<bool> _confirm(String title, String message, {String confirmLabel = 'Confirmar'}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(confirmLabel)),
        ],
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final accountAsync = ref.watch(settingsAccountProvider);
    final profile = ref.watch(currentProfileProvider);

    return HamvitSettingsScreen(
      title: 'Conta',
      subtitle: 'Gerencie seus dados principais e o plano da sua conta HAMVIT.',
      children: [
        accountAsync.when(
          loading: () => const Center(child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          )),
          error: (error, _) => HamvitSettingsInfoCard(
            icon: Icons.error_outline,
            title: 'Erro ao carregar conta',
            description: error.toString(),
          ),
          data: (account) {
            final createdAt = account.createdAt == null
                ? 'Não disponível'
                : HamvitDateUtils.formatDateBr(account.createdAt!.toLocal());
            final initials = account.name.trim().isEmpty
                ? 'H'
                : account.name
                    .trim()
                    .split(RegExp(r'\s+'))
                    .take(2)
                    .map((part) => part[0].toUpperCase())
                    .join();

            return Column(
              children: [
                HamvitSettingsSection(
                  title: 'Perfil',
                  children: [
                    Row(
                      children: [
                        ProfilePhotoWidget(
                          photoUrl: profile?.photoUrl,
                          displayName: account.name,
                          size: 56,
                          editable: false,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(account.name, style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 2),
                              Text(account.email, style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: 2),
                              Text('Plano: ${account.planLabel}', style: Theme.of(context).textTheme.bodySmall),
                              Text('Conta criada em: $createdAt', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        )
                      ],
                    ),
                  ],
                ),
                HamvitSettingsSection(
                  title: 'Dados pessoais',
                  children: [
                    HamvitSettingsActionTile(
                      icon: Icons.person_outline,
                      title: 'Nome',
                      subtitle: account.name,
                      isLoading: _busy,
                      onTap: () => _editName(account.name),
                    ),
                    HamvitSettingsTile(
                      icon: Icons.email_outlined,
                      title: 'E-mail',
                      subtitle: account.email,
                      trailing: const SizedBox.shrink(),
                    ),
                    HamvitSettingsTile(
                      icon: Icons.flag_outlined,
                      title: 'Objetivo principal',
                      subtitle: (account.objective == null || account.objective!.trim().isEmpty)
                          ? 'Não definido ainda'
                          : account.objective,
                      trailing: const SizedBox.shrink(),
                    ),
                    HamvitSettingsActionTile(
                      icon: Icons.photo_camera_outlined,
                      title: 'Alterar avatar/foto',
                      subtitle: 'Ajuste na tela de edição de perfil',
                      onTap: () => context.push('/profile/edit'),
                    ),
                    HamvitSettingsActionTile(
                      icon: Icons.edit_outlined,
                      title: 'Editar perfil',
                      subtitle: 'Abrir edição completa',
                      onTap: () => context.push('/profile/edit'),
                    ),
                    HamvitSettingsActionTile(
                      icon: Icons.track_changes_outlined,
                      title: 'Objetivo principal',
                      subtitle: 'Abrir tela de objetivos',
                      onTap: () => context.push('/profile/goals'),
                    ),
                  ],
                ),
                HamvitSettingsSection(
                  title: 'Plano',
                  children: [
                    HamvitSettingsTile(
                      icon: Icons.workspace_premium_outlined,
                      title: 'Plano atual',
                      subtitle: account.planLabel,
                      trailing: const SizedBox.shrink(),
                    ),
                    if (account.planLabel == 'Free')
                      HamvitSettingsActionTile(
                        icon: Icons.auto_awesome_outlined,
                        title: 'Conhecer Premium',
                        subtitle: 'Sem mensalidade, Premium Vitalício',
                        onTap: () => context.push('/premium'),
                      )
                    else
                      const HamvitSettingsInfoCard(
                        icon: Icons.verified_outlined,
                        title: 'Premium Vitalício ativo',
                        description: 'Todos os recursos premium estão habilitados para esta conta.',
                      ),
                  ],
                ),
                HamvitSettingsSection(
                  title: 'Conta',
                  children: [
                    HamvitSettingsActionTile(
                      icon: Icons.logout,
                      title: 'Sair da conta',
                      subtitle: 'Encerrar sessão neste dispositivo',
                      isLoading: _busy,
                      onTap: () async {
                        final ok = await _confirm('Sair da conta', 'Deseja sair da sua conta neste dispositivo?');
                        if (!ok) return;
                        await _runAction(() async {
                          await ref.read(authStateProvider.notifier).logout();
                          if (mounted) this.context.go('/login');
                        }, 'Sessão encerrada.');
                      },
                    ),
                  ],
                ),
                HamvitDangerZoneCard(
                  title: 'Área de perigo',
                  description:
                      'A exclusão da conta é irreversível após processamento. Primeiro registramos sua solicitação para análise.',
                  actions: [
                    HamvitSettingsActionTile(
                      icon: Icons.delete_forever_outlined,
                      title: 'Excluir conta',
                      subtitle: 'Solicitar exclusão com confirmação',
                      isLoading: _busy,
                      onTap: () async {
                        final ok = await _confirm(
                          'Confirmação obrigatória',
                          'Tem certeza que deseja solicitar a exclusão da conta?',
                          confirmLabel: 'Solicitar exclusão',
                        );
                        if (!ok) return;

                        final allowed = await requireBiometricForAction(
                          context,
                          ref,
                          reason:
                              'Confirme sua biometria para solicitar exclusão da conta.',
                        );
                        if (!allowed) return;

                        await _runAction(() async {
                          await ref.read(settingsRepositoryProvider).requestAccountDeletion();
                          await ref.read(settingsRepositoryProvider).logAudit(
                            'account_deletion_requested',
                            {'source': 'settings_account_screen'},
                          );
                        }, 'Solicitação de exclusão registrada com sucesso.');
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
