import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../privacy/app_blur_overlay.dart';
import '../../security/biometric_gate.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/hamvit_settings_components.dart';

class DataExportSettingsScreen extends ConsumerStatefulWidget {
  const DataExportSettingsScreen({super.key});

  @override
  ConsumerState<DataExportSettingsScreen> createState() => _DataExportSettingsScreenState();
}

class _DataExportSettingsScreenState extends ConsumerState<DataExportSettingsScreen> {
  bool _busy = false;

  String _fmtDateTime(DateTime? value) {
    if (value == null) return 'Não disponível';
    return DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(value.toLocal());
  }

  Future<void> _runAction(Future<void> Function() action, String success) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Não foi possível concluir: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runBiometricAction({
    required String reason,
    required Future<void> Function() action,
    required String success,
  }) async {
    final allowed = await requireBiometricForAction(
      context,
      ref,
      reason: reason,
    );
    if (!allowed) return;
    await _runAction(action, success);
  }

  Future<bool> _confirm(String title, String message, String confirmLabel) async {
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
    final isPremium = ref.watch(isPremiumProvider);
    final statusAsync = ref.watch(settingsDataExportStatusProvider);
    final reportsAsync = ref.watch(settingsGeneratedReportsProvider);

    return HamvitBiometricGate(
      reason: 'Confirme sua biometria para acessar dados e exportação.',
      child: HamvitProtectedScreenWrapper(
        child: HamvitSettingsScreen(
        title: 'Dados e exportação',
        subtitle:
            'Controle exportações, sincronização, cache local e solicitações sensíveis.',
        children: [
        HamvitSettingsSection(
          title: 'Exportar dados',
          children: [
            HamvitSettingsActionTile(
              icon: Icons.download_outlined,
              title: 'Exportar meus dados',
              subtitle: 'Solicitar pacote geral de dados',
              isLoading: _busy,
              onTap: () => _runBiometricAction(
                reason: 'Confirme sua biometria para exportar seus dados.',
                action: () => ref.read(settingsRepositoryProvider).requestDataExport('all_data'),
                success: 'Solicitação de exportação geral enviada.',
              ),
            ),
            HamvitSettingsActionTile(
              icon: Icons.checklist_outlined,
              title: 'Exportar histórico de hábitos',
              isLoading: _busy,
              onTap: () => _runBiometricAction(
                reason: 'Confirme sua biometria para exportar histórico de hábitos.',
                action: () => ref.read(settingsRepositoryProvider).requestDataExport('habits_history'),
                success: 'Solicitação de hábitos enviada.',
              ),
            ),
            HamvitSettingsActionTile(
              icon: Icons.restaurant_menu_outlined,
              title: 'Exportar histórico alimentar',
              isLoading: _busy,
              onTap: () => _runBiometricAction(
                reason: 'Confirme sua biometria para exportar histórico alimentar.',
                action: () => ref.read(settingsRepositoryProvider).requestDataExport('meal_history'),
                success: 'Solicitação alimentar enviada.',
              ),
            ),
            HamvitSettingsActionTile(
              icon: Icons.directions_walk_outlined,
              title: 'Exportar atividades',
              isLoading: _busy,
              onTap: () => _runBiometricAction(
                reason: 'Confirme sua biometria para exportar atividades.',
                action: () => ref.read(settingsRepositoryProvider).requestDataExport('activities_history'),
                success: 'Solicitação de atividades enviada.',
              ),
            ),
            HamvitSettingsActionTile(
              icon: Icons.show_chart_outlined,
              title: 'Exportar evolução corporal',
              isLoading: _busy,
              onTap: () => _runBiometricAction(
                reason: 'Confirme sua biometria para exportar evolução corporal.',
                action: () => ref.read(settingsRepositoryProvider).requestDataExport('body_progress'),
                success: 'Solicitação de evolução corporal enviada.',
              ),
            ),
          ],
        ),
        HamvitSettingsSection(
          title: 'Relatórios',
          children: [
            if (!isPremium) ...[
              const HamvitSettingsInfoCard(
                icon: Icons.lock_outline,
                title: 'PDF Premium',
                description: 'A exportação PDF de relatórios está disponível no Premium Vitalício.',
              ),
              const SizedBox(height: 8),
              HamvitSettingsActionTile(
                icon: Icons.workspace_premium_outlined,
                title: 'Conhecer Premium',
                subtitle: 'Sem mensalidade',
                onTap: () => context.push('/premium'),
              ),
            ] else ...[
              HamvitSettingsActionTile(
                icon: Icons.picture_as_pdf_outlined,
                title: 'Gerar relatório PDF',
                onTap: () => context.push('/reports/evolution'),
              ),
              HamvitSettingsActionTile(
                icon: Icons.folder_open_outlined,
                title: 'Ver relatórios gerados',
                onTap: () => context.push('/reports'),
              ),
            ],
            const SizedBox(height: 6),
            reportsAsync.when(
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (_, __) => const Text('Falha ao carregar histórico de relatórios.'),
              data: (rows) => Text(
                rows.isEmpty ? 'Nenhum relatório recente.' : '${rows.length} relatório(s) recente(s) encontrado(s).',
              ),
            ),
          ],
        ),
        HamvitSettingsSection(
          title: 'Sincronização',
          children: [
            statusAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(8.0),
                child: LinearProgressIndicator(minHeight: 2),
              ),
              error: (_, __) => const Text('Falha ao consultar status de sincronização.'),
              data: (status) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Última sincronização: ${_fmtDateTime(status.lastSyncAt)}'),
                  Text('Itens pendentes: ${status.pendingMutations}'),
                ],
              ),
            ),
            HamvitSettingsActionTile(
              icon: Icons.sync_outlined,
              title: 'Sincronizar agora',
              subtitle: 'Força revalidação dos status locais',
              isLoading: _busy,
              onTap: () => _runAction(() async {
                ref.invalidate(settingsDataExportStatusProvider);
                await ref.read(settingsRepositoryProvider).logAudit('manual_sync_requested', {'source': 'settings_data_export_screen'});
              }, 'Sincronização manual solicitada.'),
            ),
          ],
        ),
        HamvitSettingsSection(
          title: 'Cache local',
          children: [
            HamvitSettingsActionTile(
              icon: Icons.cleaning_services_outlined,
              title: 'Limpar cache local',
              subtitle: 'Não remove seus dados da conta',
              isLoading: _busy,
              onTap: () async {
                final ok = await _confirm(
                  'Limpar cache local',
                  'Tem certeza que deseja limpar o cache local? Seus dados sincronizados serão preservados.',
                  'Limpar cache',
                );
                if (!ok) return;
                await _runAction(() async {
                  PaintingBinding.instance.imageCache.clear();
                  PaintingBinding.instance.imageCache.clearLiveImages();
                }, 'Cache local limpo com sucesso.');
              },
            ),
          ],
        ),
        HamvitDangerZoneCard(
          title: 'Área de perigo',
          description: 'Solicitações sensíveis passam por confirmação e auditoria.',
          actions: [
            HamvitSettingsActionTile(
              icon: Icons.delete_sweep_outlined,
              title: 'Solicitar exclusão dos meus dados',
              isLoading: _busy,
              onTap: () async {
                final ok = await _confirm(
                  'Solicitar exclusão de dados',
                  'Confirma a solicitação de exclusão dos seus dados pessoais?',
                  'Solicitar',
                );
                if (!ok) return;
                await _runBiometricAction(
                  reason: 'Confirme sua biometria para solicitar exclusão de dados.',
                  action: () async {
                    await ref.read(settingsRepositoryProvider).requestDataExport('delete_data_request');
                  },
                  success: 'Solicitação de exclusão de dados registrada.',
                );
              },
            ),
            HamvitSettingsActionTile(
              icon: Icons.person_off_outlined,
              title: 'Solicitar exclusão da conta',
              isLoading: _busy,
              onTap: () async {
                final ok = await _confirm(
                  'Confirmação obrigatória',
                  'Tem certeza que deseja solicitar a exclusão da conta?',
                  'Solicitar exclusão',
                );
                if (!ok) return;
                await _runBiometricAction(
                  reason: 'Confirme sua biometria para solicitar exclusão da conta.',
                  action: () async {
                    await ref.read(settingsRepositoryProvider).requestAccountDeletion(reason: 'Solicitação pelo módulo de dados e exportação');
                  },
                  success: 'Solicitação de exclusão da conta registrada.',
                );
              },
            ),
          ],
        ),
        ],
        ),
      ),
    );
  }
}
