import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase_provider.dart';
import '../../shared/widgets/hamvit_components.dart';
import '../premium/premium_page.dart';
import '../reports/reports_service.dart';

enum DrawerSubItemType {
  premiumBenefits,
  premiumBuy,
  premiumPaymentHistory,
  premiumCoupons,
  reportsSummary,
  reportsExportPdf,
  reportsSendNutritionist,
  reportsHistory,
  proLink,
  proMy,
  proCoupon,
  proShareReport,
  challengesActive,
  challengesAchievements,
  challengesStreaks,
  challengesHistory,
  settingsAccount,
  settingsSecurity,
  settingsNotifications,
  settingsPrivacy,
  settingsAccessibility,
  settingsDataExport,
  supportHelp,
  supportContact,
  supportTerms,
  supportPrivacyPolicy,
}

String drawerSubItemTitle(DrawerSubItemType type) {
  return switch (type) {
    DrawerSubItemType.premiumBenefits => 'Benefícios',
    DrawerSubItemType.premiumBuy => 'Comprar Premium',
    DrawerSubItemType.premiumPaymentHistory => 'Histórico de pagamento',
    DrawerSubItemType.premiumCoupons => 'Cupons',
    DrawerSubItemType.reportsSummary => 'Resumo de evolução',
    DrawerSubItemType.reportsExportPdf => 'Exportar PDF',
    DrawerSubItemType.reportsSendNutritionist => 'Enviar ao nutricionista',
    DrawerSubItemType.reportsHistory => 'Histórico de relatórios',
    DrawerSubItemType.proLink => 'Vincular profissional',
    DrawerSubItemType.proMy => 'Meu nutricionista',
    DrawerSubItemType.proCoupon => 'Cupom do profissional',
    DrawerSubItemType.proShareReport => 'Compartilhar relatório',
    DrawerSubItemType.challengesActive => 'Desafios ativos',
    DrawerSubItemType.challengesAchievements => 'Conquistas',
    DrawerSubItemType.challengesStreaks => 'Frequências',
    DrawerSubItemType.challengesHistory => 'Histórico',
    DrawerSubItemType.settingsAccount => 'Conta',
    DrawerSubItemType.settingsSecurity => 'Segurança',
    DrawerSubItemType.settingsNotifications => 'Notificações',
    DrawerSubItemType.settingsPrivacy => 'Privacidade',
    DrawerSubItemType.settingsAccessibility => 'Acessibilidade',
    DrawerSubItemType.settingsDataExport => 'Dados e exportação',
    DrawerSubItemType.supportHelp => 'Central de ajuda',
    DrawerSubItemType.supportContact => 'Falar com suporte',
    DrawerSubItemType.supportTerms => 'Termos',
    DrawerSubItemType.supportPrivacyPolicy => 'Política de privacidade',
  };
}

class DrawerSubItemPage extends ConsumerStatefulWidget {
  final DrawerSubItemType type;
  final bool isPremium;
  const DrawerSubItemPage({super.key, required this.type, required this.isPremium});

  @override
  ConsumerState<DrawerSubItemPage> createState() => _DrawerSubItemPageState();
}

class _DrawerSubItemPageState extends ConsumerState<DrawerSubItemPage> {
  final TextEditingController _textCtrl = TextEditingController();
  String _feedback = '';

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _query(String table, {String? orderBy}) async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) return const [];
    final user = client.auth.currentUser;
    if (user == null) return const [];
    dynamic q = client.from(table).select('*').eq('user_id', user.id);
    if (orderBy != null) q = q.order(orderBy, ascending: false);
    final rows = await q;
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _audit(String action, Map<String, dynamic> payload) async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) return;
    final user = client.auth.currentUser;
    if (user == null) return;
    await client.from('audit_logs').insert({'actor_user_id': user.id, 'action': action, 'payload': payload});
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.type;

    if (type == DrawerSubItemType.premiumBuy) return const PremiumPage();

    if (type == DrawerSubItemType.premiumBenefits) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          HamvitHeader(title: 'Benefícios Premium', subtitle: 'Recomendação alimentar, IA de foto e relatórios avançados.'),
          SizedBox(height: 12),
          HamvitIconCard(assetPath: 'assets/icons/alimentacao.png', label: 'Sugestões automáticas por refeição'),
          SizedBox(height: 8),
          HamvitIconCard(assetPath: 'assets/icons/alimentacao.png', label: 'Foto da comida com revisão antes de salvar'),
          SizedBox(height: 8),
          HamvitIconCard(assetPath: 'assets/icons/relatorios.png', label: 'PDF com compartilhamento para profissional'),
        ],
      );
    }

    if (type == DrawerSubItemType.premiumPaymentHistory) {
      return FutureBuilder(
        future: _query('payments', orderBy: 'created_at'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const HamvitLoading();
          final rows = snapshot.data!;
          if (rows.isEmpty) return const HamvitEmptyState(message: 'Nenhum pagamento registrado.');
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const HamvitHeader(title: 'Histórico de Pagamento'),
              const SizedBox(height: 12),
              for (final r in rows) ...[
                HamvitCard(child: Text('ID: ${r['id']}\nStatus: ${r['status'] ?? '-'}\nValor: R\$ ${r['amount_brl'] ?? '-'}')),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      );
    }

    if (type == DrawerSubItemType.premiumCoupons) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const HamvitHeader(title: 'Cupons', subtitle: 'Cupom sempre em UPPERCASE.'),
          const SizedBox(height: 12),
          HamvitTextField(controller: _textCtrl, label: 'Cupom'),
          const SizedBox(height: 8),
          HamvitButton(
            label: 'Salvar cupom',
            onPressed: () async {
              final code = _textCtrl.text.trim().toUpperCase();
              if (code.isEmpty) return;
              await _audit('coupon_saved_local', {'code': code});
              if (!mounted) return;
              setState(() => _feedback = 'Cupom registrado para uso: $code');
            },
          ),
          if (_feedback.isNotEmpty) ...[const SizedBox(height: 8), Text(_feedback)],
        ],
      );
    }

    if (type == DrawerSubItemType.reportsSummary) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          HamvitHeader(title: 'Resumo de Evolução', subtitle: 'Visão consolidada para acompanhamento profissional.'),
          SizedBox(height: 12),
          HamvitIconCard(assetPath: 'assets/icons/progresso.png', label: 'Evolução corporal'),
          SizedBox(height: 8),
          HamvitIconCard(assetPath: 'assets/icons/hidratacao.png', label: 'Constância de hidratação'),
          SizedBox(height: 8),
          HamvitIconCard(assetPath: 'assets/icons/habitos.png', label: 'Checklist de hábitos'),
        ],
      );
    }

    if (type == DrawerSubItemType.reportsExportPdf) {
      final svc = ref.watch(reportsServiceProvider);
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const HamvitHeader(title: 'Exportar PDF', subtitle: 'Disponível apenas no Premium.'),
          const SizedBox(height: 12),
          HamvitButton(
            label: widget.isPremium ? 'Gerar PDF agora' : 'Plano Free: PDF bloqueado',
            onPressed: () async {
              final result = await svc.createReport(
                start: DateTime.now().subtract(const Duration(days: 7)),
                end: DateTime.now(),
                premium: widget.isPremium,
              );
              if (!mounted) return;
              setState(() => _feedback = result?['mode'] == 'pdf' ? 'Relatório gerado: ${result?['report']['id']}' : (result?['message'] ?? 'Sem retorno'));
            },
          ),
          if (_feedback.isNotEmpty) ...[const SizedBox(height: 8), Text(_feedback)],
        ],
      );
    }

    if (type == DrawerSubItemType.reportsSendNutritionist || type == DrawerSubItemType.proShareReport) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const HamvitHeader(title: 'Compartilhar Relatório', subtitle: 'Canal orientado para nutricionista/profissional.'),
          const SizedBox(height: 12),
          HamvitTextField(controller: _textCtrl, label: 'Contato do profissional (e-mail/WhatsApp)'),
          const SizedBox(height: 8),
          HamvitButton(
            label: 'Registrar compartilhamento',
            onPressed: () async {
              await _audit('report_share_requested', {'target': _textCtrl.text.trim()});
              if (!mounted) return;
              setState(() => _feedback = 'Solicitação registrada para compartilhamento.');
            },
          ),
          if (_feedback.isNotEmpty) ...[const SizedBox(height: 8), Text(_feedback)],
        ],
      );
    }

    if (type == DrawerSubItemType.reportsHistory) {
      return FutureBuilder(
        future: _query('generated_reports', orderBy: 'created_at'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const HamvitLoading();
          final rows = snapshot.data!;
          if (rows.isEmpty) return const HamvitEmptyState(message: 'Sem histórico de relatórios.');
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const HamvitHeader(title: 'Histórico de Relatórios'),
              const SizedBox(height: 12),
              for (final r in rows) ...[
                HamvitCard(child: Text('ID: ${r['id']}\nPeríodo: ${r['period_start']} até ${r['period_end']}\nFormato: ${r['format']}')),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      );
    }

    if (type == DrawerSubItemType.proLink) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const HamvitHeader(title: 'Vincular Profissional', subtitle: 'Use o cupom do profissional para vincular.'),
          const SizedBox(height: 12),
          HamvitTextField(controller: _textCtrl, label: 'Cupom profissional'),
          const SizedBox(height: 8),
          HamvitButton(
            label: 'Registrar vínculo',
            onPressed: () async {
              await _audit('professional_link_requested', {'coupon': _textCtrl.text.trim().toUpperCase()});
              if (!mounted) return;
              setState(() => _feedback = 'Solicitação de vínculo registrada.');
            },
          ),
          if (_feedback.isNotEmpty) ...[const SizedBox(height: 8), Text(_feedback)],
        ],
      );
    }

    if (type == DrawerSubItemType.proMy) {
      return FutureBuilder(
        future: _query('patient_professional_links', orderBy: 'created_at'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const HamvitLoading();
          final rows = snapshot.data!;
          if (rows.isEmpty) return const HamvitEmptyState(message: 'Nenhum profissional vinculado ainda.');
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const HamvitHeader(title: 'Meu Nutricionista'),
              const SizedBox(height: 12),
              for (final r in rows) ...[
                HamvitCard(child: Text('Vínculo: ${r['id']}\nCriado em: ${r['created_at']}')),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      );
    }

    if (type == DrawerSubItemType.proCoupon) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const HamvitHeader(title: 'Cupom do Profissional'),
          const SizedBox(height: 12),
          HamvitTextField(controller: _textCtrl, label: 'Cupom em UPPERCASE'),
          const SizedBox(height: 8),
          HamvitButton(
            label: 'Salvar cupom',
            onPressed: () async {
              await _audit('professional_coupon_saved', {'coupon': _textCtrl.text.trim().toUpperCase()});
              if (!mounted) return;
              setState(() => _feedback = 'Cupom salvo com sucesso.');
            },
          ),
          if (_feedback.isNotEmpty) ...[const SizedBox(height: 8), Text(_feedback)],
        ],
      );
    }

    if (type == DrawerSubItemType.challengesActive || type == DrawerSubItemType.challengesHistory) {
      return FutureBuilder(
        future: _query('user_challenges', orderBy: 'id'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const HamvitLoading();
          final rows = snapshot.data!;
          if (rows.isEmpty) return const HamvitEmptyState(message: 'Sem desafios registrados.');
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              HamvitHeader(title: type == DrawerSubItemType.challengesActive ? 'Desafios Ativos' : 'Histórico de Desafios'),
              const SizedBox(height: 12),
              for (final r in rows) ...[
                HamvitCard(child: Text('Desafio: ${r['challenge_id']}\nStatus: ${r['status'] ?? '-'}')),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      );
    }

    if (type == DrawerSubItemType.challengesAchievements) {
      return FutureBuilder(
        future: _query('user_achievements', orderBy: 'granted_at'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const HamvitLoading();
          final rows = snapshot.data!;
          if (rows.isEmpty) return const HamvitEmptyState(message: 'Sem conquistas registradas.');
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const HamvitHeader(title: 'Conquistas'),
              const SizedBox(height: 12),
              for (final r in rows) ...[
                HamvitCard(child: Text('Conquista: ${r['achievement_id']}\nData: ${r['granted_at']}')),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      );
    }

    if (type == DrawerSubItemType.challengesStreaks) {
      return FutureBuilder(
        future: _query('user_streaks', orderBy: 'updated_at'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const HamvitLoading();
          final rows = snapshot.data!;
          if (rows.isEmpty) return const HamvitEmptyState(message: 'Sem frequências registradas.');
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const HamvitHeader(title: 'Frequências'),
              const SizedBox(height: 12),
              for (final r in rows) ...[
                HamvitCard(child: Text('Tipo: ${r['streak_type'] ?? '-'}\nAtual: ${r['current_count'] ?? 0}')),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      );
    }

    if (type == DrawerSubItemType.settingsAccount ||
        type == DrawerSubItemType.settingsSecurity ||
        type == DrawerSubItemType.settingsNotifications ||
        type == DrawerSubItemType.settingsPrivacy ||
        type == DrawerSubItemType.settingsAccessibility ||
        type == DrawerSubItemType.settingsDataExport) {
      final titles = {
        DrawerSubItemType.settingsAccount: 'Conta',
        DrawerSubItemType.settingsSecurity: 'Segurança',
        DrawerSubItemType.settingsNotifications: 'Notificações',
        DrawerSubItemType.settingsPrivacy: 'Privacidade',
        DrawerSubItemType.settingsAccessibility: 'Acessibilidade',
        DrawerSubItemType.settingsDataExport: 'Dados e exportação',
      };
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          HamvitHeader(title: titles[type] ?? 'Configurações'),
          const SizedBox(height: 12),
          const HamvitCard(child: Text('Tela dedicada pronta para configuração deste módulo conforme o RCP.')),
          const SizedBox(height: 8),
          HamvitButton(
            label: 'Salvar preferência local',
            onPressed: () async {
              await _audit('settings_updated', {'module': titles[type]});
              if (!mounted) return;
              setState(() => _feedback = 'Preferência registrada.');
            },
          ),
          if (_feedback.isNotEmpty) ...[const SizedBox(height: 8), Text(_feedback)],
        ],
      );
    }

    if (type == DrawerSubItemType.supportHelp ||
        type == DrawerSubItemType.supportContact ||
        type == DrawerSubItemType.supportTerms ||
        type == DrawerSubItemType.supportPrivacyPolicy) {
      final map = {
        DrawerSubItemType.supportHelp: 'Central de ajuda',
        DrawerSubItemType.supportContact: 'Falar com suporte',
        DrawerSubItemType.supportTerms: 'Termos',
        DrawerSubItemType.supportPrivacyPolicy: 'Política de privacidade',
      };
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          HamvitHeader(title: map[type] ?? 'Suporte'),
          const SizedBox(height: 12),
          HamvitCard(
            child: Text(
              type == DrawerSubItemType.supportContact
                  ? 'Use este canal para dúvidas técnicas e de uso. O atendimento HAMVIT deve manter tom acolhedor e sem culpa.'
                  : 'Conteúdo institucional e orientações deste módulo.',
            ),
          ),
          if (type == DrawerSubItemType.supportContact) ...[
            const SizedBox(height: 8),
            HamvitTextField(controller: _textCtrl, label: 'Descreva sua solicitação'),
            const SizedBox(height: 8),
            HamvitButton(
              label: 'Enviar solicitação',
              onPressed: () async {
                await _audit('support_message_sent', {'message': _textCtrl.text.trim()});
                if (!mounted) return;
                setState(() => _feedback = 'Mensagem registrada com sucesso.');
              },
            ),
            if (_feedback.isNotEmpty) ...[const SizedBox(height: 8), Text(_feedback)],
          ],
        ],
      );
    }

    return const HamvitEmptyState(message: 'Tela não implementada.');
  }
}

