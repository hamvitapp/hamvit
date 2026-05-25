import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';
import '../../security/biometric_settings_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/hamvit_settings_components.dart';

class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends ConsumerState<SecuritySettingsScreen> {
  bool _busy = false;

  Future<void> _runAction(Future<void> Function() action, String successMessage) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Não foi possível concluir: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changePassword() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar senha'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nova senha'),
          obscureText: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: const Text('Salvar')),
        ],
      ),
    );

    if (value == null || value.isEmpty) return;
    if (value.length < 6) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A senha precisa ter ao menos 6 caracteres.')),
      );
      return;
    }

    await _runAction(() async {
      await ref.read(settingsRepositoryProvider).updatePassword(value);
      await ref.read(settingsRepositoryProvider).logAudit('password_updated', {'source': 'settings_security_screen'});
    }, 'Senha atualizada com sucesso.');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final email = user?.email ?? '-';
    final lastAccess = user?.lastSignInAt;
    final biometricAvailableAsync = ref.watch(biometricAvailableProvider);
    final biometricSettingsAsync = ref.watch(biometricSettingsProvider);

    return HamvitSettingsScreen(
      title: 'Segurança',
      subtitle: 'Gerencie senha, sessão ativa e medidas de proteção da sua conta.',
      children: [
        HamvitSettingsSection(
          title: 'Senha',
          children: [
            HamvitSettingsActionTile(
              icon: Icons.key_outlined,
              title: 'Alterar senha',
              subtitle: 'Defina uma nova senha para sua conta',
              isLoading: _busy,
              onTap: _changePassword,
            ),
            HamvitSettingsActionTile(
              icon: Icons.mark_email_read_outlined,
              title: 'Enviar link de recuperação',
              subtitle: email,
              isLoading: _busy,
              onTap: () => _runAction(
                () => ref.read(settingsRepositoryProvider).sendPasswordRecoveryLink(),
                'Enviamos um link de recuperação para $email.',
              ),
            ),
          ],
        ),
        HamvitSettingsSection(
          title: 'Sessão',
          children: [
            HamvitSettingsActionTile(
              icon: Icons.logout,
              title: 'Sair deste dispositivo',
              subtitle: 'Encerrar sessão atual neste aparelho',
              isLoading: _busy,
              onTap: () => _runAction(() async {
                await ref.read(authStateProvider.notifier).logout();
                if (mounted) context.go('/login');
              }, 'Sessão encerrada neste dispositivo.'),
            ),
            HamvitSettingsActionTile(
              icon: Icons.devices_other_outlined,
              title: 'Sair de todos os dispositivos',
              subtitle: 'Encerrar sessões ativas da conta',
              isLoading: _busy,
              onTap: () => _runAction(() async {
                await ref.read(settingsRepositoryProvider).signOutAllDevices();
                await ref.read(authStateProvider.notifier).logout();
                if (mounted) context.go('/login');
              }, 'Sessões encerradas com sucesso.'),
            ),
            HamvitSettingsTile(
              icon: Icons.schedule_outlined,
              title: 'Último acesso',
              subtitle: (lastAccess == null || lastAccess.isEmpty)
                  ? 'Não disponível'
                  : DateTime.tryParse(lastAccess)?.toLocal().toString() ?? 'Não disponível',
              trailing: const SizedBox.shrink(),
            ),
          ],
        ),
        HamvitSettingsSection(
          title: 'Biometria',
          subtitle:
              'Use biometria do seu dispositivo para desbloquear o HAMVIT com mais segurança.',
          children: [
            biometricAvailableAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(12),
                child: LinearProgressIndicator(minHeight: 2),
              ),
              error: (_, __) => const Text('Biometria não disponível neste dispositivo.'),
              data: (available) {
                if (!available) {
                  return const ListTile(
                    leading: Icon(Icons.fingerprint_outlined),
                    title: Text('Biometria não disponível neste dispositivo.'),
                  );
                }

                return biometricSettingsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(12),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                  error: (error, _) => Text('Falha ao carregar biometria: $error'),
                  data: (settings) {
                    return Column(
                      children: [
                        HamvitSettingsSwitchTile(
                          icon: Icons.fingerprint,
                          title: 'Ativar desbloqueio por biometria',
                          value: settings.biometricUnlockEnabled,
                          onChanged: _busy
                              ? null
                              : (value) async {
                                  try {
                                    await ref
                                        .read(biometricSettingsProvider.notifier)
                                        .setBiometricUnlockEnabled(value);
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          value
                                              ? 'Biometria ativada com sucesso.'
                                              : 'Biometria desativada.',
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString())),
                                    );
                                  }
                                },
                        ),
                        HamvitSettingsSwitchTile(
                          icon: Icons.admin_panel_settings_outlined,
                          title: 'Usar biometria em telas sensíveis',
                          value: settings.biometricSensitiveScreensEnabled,
                          onChanged: _busy
                              ? null
                              : (value) async {
                                  try {
                                    await ref
                                        .read(biometricSettingsProvider.notifier)
                                        .setSensitiveScreensEnabled(value);
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          value
                                              ? 'Proteção biométrica de telas sensíveis ativada.'
                                              : 'Proteção biométrica de telas sensíveis desativada.',
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString())),
                                    );
                                  }
                                },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
        const HamvitSettingsInfoCard(
          icon: Icons.security_outlined,
          title: 'Aviso de segurança',
          description:
              'Nunca compartilhe sua senha. O HAMVIT nunca solicita sua senha fora do aplicativo.',
        ),
      ],
    );
  }
}
