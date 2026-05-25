import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../privacy/privacy_settings_screen.dart';
import '../../security/biometric_gate.dart';
import '../providers/settings_provider.dart';
import '../widgets/hamvit_settings_components.dart';

class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  bool _saving = false;

  Future<void> _toggleAiConsent(bool value) async {
    setState(() => _saving = true);
    try {
      await ref.read(settingsRepositoryProvider).setAiFoodPhotoConsent(value);
      ref.invalidate(settingsPrivacyProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(value ? 'Uso de fotos para IA ativado.' : 'Uso de fotos para IA desativado.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível atualizar consentimento: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _revokeProfessionalAccess() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revogar acesso profissional'),
        content: const Text('Deseja revogar os vínculos de profissionais com acesso aos seus dados?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Revogar')),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _saving = true);
    try {
      await ref.read(settingsRepositoryProvider).revokeProfessionalLinks();
      ref.invalidate(settingsPrivacyProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Acessos profissionais revogados.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao revogar acesso: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(settingsPrivacyProvider);

    return HamvitBiometricGate(
      reason: 'Confirme sua biometria para acessar configurações de privacidade.',
      child: HamvitSettingsScreen(
        title: 'Privacidade',
        subtitle:
            'Controle o uso de dados sensíveis, compartilhamentos e consentimentos.',
        children: [
        const HamvitSettingsSection(
          title: 'Dados sensíveis',
          children: [
            HamvitSettingsTile(
              icon: Icons.lock_outline,
              title: 'Dados protegidos',
              subtitle: 'Alimentação, peso, medidas, fotos, atividades, sono e relatórios.',
              trailing: SizedBox.shrink(),
            ),
          ],
        ),
        async.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => HamvitSettingsInfoCard(
            icon: Icons.error_outline,
            title: 'Erro ao carregar privacidade',
            description: error.toString(),
          ),
          data: (privacy) {
            return Column(
              children: [
                const HamvitPrivacySettingsCard(),
                HamvitSettingsSection(
                  title: 'Compartilhamento',
                  children: [
                    HamvitSettingsTile(
                      icon: Icons.share_outlined,
                      title: 'Relatórios compartilhados',
                      subtitle: '${privacy.sharedReports} compartilhamentos registrados',
                      trailing: const SizedBox.shrink(),
                    ),
                    HamvitSettingsTile(
                      icon: Icons.medical_services_outlined,
                      title: 'Profissionais com acesso',
                      subtitle: '${privacy.linkedProfessionals} vínculo(s) ativo(s)',
                      trailing: const SizedBox.shrink(),
                    ),
                    HamvitSettingsActionTile(
                      icon: Icons.description_outlined,
                      title: 'Ver relatórios compartilhados',
                      subtitle: 'Abrir módulo de relatórios',
                      onTap: () => context.push('/reports'),
                    ),
                    HamvitSettingsActionTile(
                      icon: Icons.link_off_outlined,
                      title: 'Revogar acesso profissional',
                      subtitle: 'Remover vínculos existentes',
                      isLoading: _saving,
                      onTap: _revokeProfessionalAccess,
                    ),
                  ],
                ),
                HamvitSettingsSection(
                  title: 'IA de comida',
                  children: [
                    HamvitSettingsSwitchTile(
                      icon: Icons.camera_alt_outlined,
                      title: 'Permitir uso de foto da comida para análise por IA',
                      subtitle:
                          'As imagens são usadas para estimar alimentos e macros. Você sempre revisa antes de salvar.',
                      value: privacy.aiFoodPhotoConsent,
                      onChanged: _saving ? null : _toggleAiConsent,
                    ),
                  ],
                ),
                const HamvitSettingsSection(
                  title: 'Fotos corporais',
                  children: [
                    HamvitSettingsTile(
                      icon: Icons.photo_library_outlined,
                      title: 'Fotos privadas',
                      subtitle:
                          'Suas fotos corporais são privadas. Você controla a visualização e não existe comparação pública.',
                      trailing: SizedBox.shrink(),
                    ),
                  ],
                ),
                HamvitSettingsSection(
                  title: 'Documentos legais',
                  children: [
                    HamvitSettingsActionTile(
                      icon: Icons.policy_outlined,
                      title: 'Política de privacidade',
                      subtitle: 'Abrir documento legal completo',
                      onTap: () => context.push('/legal/privacy'),
                    ),
                    HamvitSettingsActionTile(
                      icon: Icons.gavel_outlined,
                      title: 'Termos de uso',
                      subtitle: 'Abrir termos completos',
                      onTap: () => context.push('/legal/terms'),
                    ),
                  ],
                ),
                const HamvitSettingsInfoCard(
                  icon: Icons.verified_user_outlined,
                  title: 'Consentimentos',
                  description:
                      'Seus consentimentos ficam registrados com data de aceite e revogação para auditoria e transparência.',
                ),
              ],
            );
          },
        ),
      ],
      ),
    );
  }
}
