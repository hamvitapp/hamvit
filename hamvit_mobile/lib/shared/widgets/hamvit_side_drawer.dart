import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/menu/drawer_subpages.dart';
import '../../theme/hamvit_colors.dart';
import 'hamvit_components.dart';

class HamvitSideDrawer extends StatefulWidget {
  final bool isPremium;
  final bool isAdmin;
  final String? userName;
  final VoidCallback onLogout;

  const HamvitSideDrawer({
    super.key,
    required this.isPremium,
    required this.isAdmin,
    this.userName,
    required this.onLogout,
  });

  @override
  State<HamvitSideDrawer> createState() => _HamvitSideDrawerState();
}

class _HamvitSideDrawerState extends State<HamvitSideDrawer> {
  String? _expandedMenu;

  void _go(BuildContext context, String route, {Object? extra}) {
    Navigator.of(context).pop();
    context.go(route, extra: extra);
  }

  Widget _sub(String title, DrawerSubItemType type) {
    return Builder(
      builder: (context) => HamvitMenuTile(
        title: title,
        icon: Icons.chevron_right_rounded,
        onTap: () => _go(context, '/drawer/subitem', extra: type),
      ),
    );
  }

  Widget _mainMenu({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return HamvitExpandableMenuItem(
      title: title,
      icon: icon,
      initiallyExpanded: _expandedMenu == title,
      onExpansionChanged: (expanded) {
        setState(() {
          _expandedMenu = expanded ? title : (_expandedMenu == title ? null : _expandedMenu);
        });
      },
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(24))),
      child: Container(
        color: HamvitColors.primaryNavy,
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.white.withValues(alpha: 0.08),
            splashColor: HamvitColors.accentBlue.withValues(alpha: 0.2),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.fromLTRB(16.0, 88.0, 16.0, 8.0),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [HamvitColors.primaryDark, HamvitColors.primaryNavy],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: HamvitColors.accentCyan.withValues(alpha: 0.2),
                          child: Text(
                            ((widget.userName ?? 'U').isNotEmpty ? (widget.userName ?? 'U')[0] : 'U').toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.userName ?? 'Usuário HAMVIT', overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                              Text(
                                widget.isPremium ? 'Premium Vitalício ativo' : 'Plano Free ativo',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 90,
                      width: double.infinity,
                      child: Image.asset(
                        'assets/branding/hamvit_hoje_exata.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                    ),
                  ],
                ),
              ),
              _mainMenu(
                title: 'Meu Perfil',
                icon: Icons.account_circle_outlined,
                children: [
                  HamvitMenuTile(
                    title: 'Objetivos',
                    icon: Icons.flag_outlined,
                    onTap: () => _go(context, '/drawer/objectives'),
                  ),
                  HamvitMenuTile(
                    title: 'Alimentação',
                    icon: Icons.restaurant_menu,
                    onTap: () => _go(context, '/drawer/food'),
                  ),
                  HamvitMenuTile(
                    title: 'Atividade Física',
                    icon: Icons.directions_run,
                    onTap: () => _go(context, '/drawer/activity'),
                  ),
                  HamvitMenuTile(
                    title: 'Hábitos',
                    icon: Icons.checklist,
                    onTap: () => _go(context, '/drawer/habits'),
                  ),
                  HamvitMenuTile(
                    title: 'Sono',
                    icon: Icons.nightlight_round,
                    onTap: () => _go(context, '/drawer/sleep'),
                  ),
                  HamvitMenuTile(
                    title: 'Preferências',
                    icon: Icons.tune,
                    onTap: () => _go(context, '/drawer/hydration'),
                  ),
                ],
              ),
              _mainMenu(
                title: 'Premium',
                icon: Icons.workspace_premium_outlined,
                children: [
                  _sub('Benefícios', DrawerSubItemType.premiumBenefits),
                  _sub('Comprar Premium', DrawerSubItemType.premiumBuy),
                  _sub('Histórico de pagamento', DrawerSubItemType.premiumPaymentHistory),
                  _sub('Cupons', DrawerSubItemType.premiumCoupons),
                ],
              ),
              _mainMenu(
                title: 'Relatórios',
                icon: Icons.insert_chart_outlined_rounded,
                children: [
                  _sub('Resumo de evolução', DrawerSubItemType.reportsSummary),
                  _sub('Exportar PDF', DrawerSubItemType.reportsExportPdf),
                  _sub('Enviar ao nutricionista', DrawerSubItemType.reportsSendNutritionist),
                  _sub('Histórico de relatórios', DrawerSubItemType.reportsHistory),
                ],
              ),
              _mainMenu(
                title: 'Nutricionista',
                icon: Icons.medical_services_outlined,
                children: [
                  _sub('Vincular profissional', DrawerSubItemType.proLink),
                  _sub('Meu nutricionista', DrawerSubItemType.proMy),
                  _sub('Cupom do profissional', DrawerSubItemType.proCoupon),
                  _sub('Compartilhar relatório', DrawerSubItemType.proShareReport),
                ],
              ),
              _mainMenu(
                title: 'Desafios',
                icon: Icons.emoji_events_outlined,
                children: [
                  _sub('Desafios ativos', DrawerSubItemType.challengesActive),
                  _sub('Conquistas', DrawerSubItemType.challengesAchievements),
                  _sub('Streaks', DrawerSubItemType.challengesStreaks),
                  _sub('Histórico', DrawerSubItemType.challengesHistory),
                ],
              ),
              _mainMenu(
                title: 'Configurações',
                icon: Icons.settings_outlined,
                children: [
                  _sub('Conta', DrawerSubItemType.settingsAccount),
                  _sub('Segurança', DrawerSubItemType.settingsSecurity),
                  _sub('Notificações', DrawerSubItemType.settingsNotifications),
                  _sub('Privacidade', DrawerSubItemType.settingsPrivacy),
                  _sub('Acessibilidade', DrawerSubItemType.settingsAccessibility),
                  _sub('Dados e exportação', DrawerSubItemType.settingsDataExport),
                ],
              ),
              _mainMenu(
                title: 'Suporte',
                icon: Icons.support_agent_outlined,
                children: [
                  _sub('Central de ajuda', DrawerSubItemType.supportHelp),
                  _sub('Falar com suporte', DrawerSubItemType.supportContact),
                  _sub('Termos', DrawerSubItemType.supportTerms),
                  _sub('Política de privacidade', DrawerSubItemType.supportPrivacyPolicy),
                ],
              ),
              const Divider(height: 20, thickness: 1),
              HamvitMenuTile(
                title: 'Sair',
                icon: Icons.logout,
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onLogout();
                },
              ),
              if (widget.isAdmin)
                _mainMenu(
                  title: 'Admin',
                  icon: Icons.admin_panel_settings_outlined,
                  children: [
                    HamvitMenuTile(
                      title: 'Atalhos Admin',
                      icon: Icons.admin_panel_settings_outlined,
                      onTap: () => _go(context, '/drawer/admin'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

