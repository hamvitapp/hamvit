enum HamvitFeature {
  habitsBasic,
  habitsAdvancedAnalytics,
  hydrationBasic,
  hydrationAdvancedAnalytics,
  nutritionManual,
  barcodeScanner,
  nutritionSmartRecommendations,
  nutritionAdvancedReports,
  foodPhotoAi,
  reportsScreenView,
  reportsPdfExport,
  reportsSharing,
  analyticsBasic,
  analyticsAdvanced,
  bodyProgressBasic,
  bodyProgressAdvanced,
  activitiesBasic,
  activitiesAdvanced,
  professionalSharing,
  gamificationBasic,
  gamificationAdvanced,
}

class HamvitFeatureAccess {
  final bool premiumRequired;
  final String title;
  final String freeDescription;
  final String premiumDescription;
  final String teaser;

  const HamvitFeatureAccess({
    required this.premiumRequired,
    required this.title,
    required this.freeDescription,
    required this.premiumDescription,
    required this.teaser,
  });
}

class PremiumAccessMatrix {
  static const Map<HamvitFeature, HamvitFeatureAccess> entries = {
    HamvitFeature.habitsBasic: HamvitFeatureAccess(
      premiumRequired: false,
      title: 'Hábitos básicos',
      freeDescription: 'Criação, conclusão e streak básico.',
      premiumDescription: 'Inclui histórico e consistência básica.',
      teaser: 'Evolua no seu ritmo com hábitos diários.',
    ),
    HamvitFeature.habitsAdvancedAnalytics: HamvitFeatureAccess(
      premiumRequired: true,
      title: 'Hábitos avançados',
      freeDescription: 'Sem comparativos e tendências avançadas.',
      premiumDescription: 'Insights, tendências e comparativos completos.',
      teaser: 'Veja padrões inteligentes dos seus hábitos.',
    ),
    HamvitFeature.hydrationBasic: HamvitFeatureAccess(
      premiumRequired: false,
      title: 'Hidratação básica',
      freeDescription: 'Registro diário e histórico simples.',
      premiumDescription: 'Mantém rotina diária ativa.',
      teaser: 'Registre água diariamente no Free.',
    ),
    HamvitFeature.hydrationAdvancedAnalytics: HamvitFeatureAccess(
      premiumRequired: true,
      title: 'Hidratação avançada',
      freeDescription: 'Sem insights aprofundados de padrão.',
      premiumDescription: 'Análises de padrão e alertas inteligentes.',
      teaser: 'Entenda seus padrões de hidratação.',
    ),
    HamvitFeature.nutritionManual: HamvitFeatureAccess(
      premiumRequired: false,
      title: 'Alimentação manual',
      freeDescription: 'Registro manual, macros básicos e histórico.',
      premiumDescription: 'Base para evolução diária sem bloqueio agressivo.',
      teaser: 'O diário alimentar continua livre no Free.',
    ),
    HamvitFeature.barcodeScanner: HamvitFeatureAccess(
      premiumRequired: false,
      title: 'Scanner de código de barras',
      freeDescription: 'Disponível no Free para uso diário.',
      premiumDescription: 'Também disponível no Premium.',
      teaser: 'Scanner livre para aumentar retenção e consistência.',
    ),
    HamvitFeature.nutritionSmartRecommendations: HamvitFeatureAccess(
      premiumRequired: true,
      title: 'Recomendações inteligentes',
      freeDescription: 'Sem montagem automática do dia.',
      premiumDescription: 'Sugestões, substituições e montagem inteligente.',
      teaser: 'Desbloqueie automação nutricional com IA.',
    ),
    HamvitFeature.nutritionAdvancedReports: HamvitFeatureAccess(
      premiumRequired: true,
      title: 'Relatórios nutricionais profissionais',
      freeDescription: 'Free com leitura simples na tela.',
      premiumDescription: 'Relatórios avançados e profissionais.',
      teaser: 'Aprofunde a análise alimentar com Premium.',
    ),
    HamvitFeature.foodPhotoAi: HamvitFeatureAccess(
      premiumRequired: true,
      title: 'IA de foto da comida',
      freeDescription: 'Sem acesso no plano Free.',
      premiumDescription: 'Análise por imagem com revisão manual obrigatória.',
      teaser: 'Premium inclui IA de foto (limite inicial 3/dia).',
    ),
    HamvitFeature.reportsScreenView: HamvitFeatureAccess(
      premiumRequired: false,
      title: 'Relatórios em tela',
      freeDescription: 'Visualização simples liberada.',
      premiumDescription: 'Permanece liberada no Premium.',
      teaser: 'Acompanhe seus dados em tela no Free.',
    ),
    HamvitFeature.reportsPdfExport: HamvitFeatureAccess(
      premiumRequired: true,
      title: 'Exportação PDF',
      freeDescription: 'Não exporta no Free.',
      premiumDescription: 'PDF profissional e estruturado.',
      teaser: 'Exporte relatórios com Premium Vitalício.',
    ),
    HamvitFeature.reportsSharing: HamvitFeatureAccess(
      premiumRequired: true,
      title: 'Compartilhamento de relatórios',
      freeDescription: 'Sem compartilhamento no Free.',
      premiumDescription: 'Share sheet, WhatsApp e e-mail.',
      teaser: 'Compartilhe evolução com quem acompanha você.',
    ),
    HamvitFeature.analyticsBasic: HamvitFeatureAccess(
      premiumRequired: false,
      title: 'Analytics básico',
      freeDescription: 'Indicadores essenciais e score básico.',
      premiumDescription: 'Base de leitura diária.',
      teaser: 'Veja o essencial sem travas agressivas.',
    ),
    HamvitFeature.analyticsAdvanced: HamvitFeatureAccess(
      premiumRequired: true,
      title: 'Analytics avançado',
      freeDescription: 'Sem comparativos e tendências completas.',
      premiumDescription: 'Comparativos, tendências e insights inteligentes.',
      teaser: 'Premium entrega analytics completo.',
    ),
    HamvitFeature.bodyProgressBasic: HamvitFeatureAccess(
      premiumRequired: false,
      title: 'Evolução corporal básica',
      freeDescription: 'Peso, medidas e progresso básico.',
      premiumDescription: 'Histórico essencial disponível.',
      teaser: 'Registre evolução corporal no Free.',
    ),
    HamvitFeature.bodyProgressAdvanced: HamvitFeatureAccess(
      premiumRequired: true,
      title: 'Evolução corporal avançada',
      freeDescription: 'Sem comparativos detalhados.',
      premiumDescription: 'Gráficos completos e tendências.',
      teaser: 'Aprofunde sua evolução com Premium.',
    ),
    HamvitFeature.activitiesBasic: HamvitFeatureAccess(
      premiumRequired: false,
      title: 'Atividade física básica',
      freeDescription: 'Caminhada/corrida com GPS e histórico básico.',
      premiumDescription: 'Base completa para uso diário.',
      teaser: 'Movimento diário liberado no Free.',
    ),
    HamvitFeature.activitiesAdvanced: HamvitFeatureAccess(
      premiumRequired: true,
      title: 'Atividade física avançada',
      freeDescription: 'Sem comparativos de evolução detalhada.',
      premiumDescription: 'Comparativos e relatórios avançados.',
      teaser: 'Veja sua evolução detalhada no Premium.',
    ),
    HamvitFeature.professionalSharing: HamvitFeatureAccess(
      premiumRequired: true,
      title: 'Compartilhamento profissional',
      freeDescription: 'Sem envio para nutricionista no Free.',
      premiumDescription: 'Vínculo profissional, cupons e relatórios.',
      teaser: 'Integre acompanhamento profissional.',
    ),
    HamvitFeature.gamificationBasic: HamvitFeatureAccess(
      premiumRequired: false,
      title: 'Gamificação básica',
      freeDescription: 'Streak básico no Free.',
      premiumDescription: 'Base para consistência diária.',
      teaser: 'Mantenha sua sequência ativa.',
    ),
    HamvitFeature.gamificationAdvanced: HamvitFeatureAccess(
      premiumRequired: true,
      title: 'Gamificação avançada',
      freeDescription: 'Sem desafios premium.',
      premiumDescription: 'Desafios avançados e achievements premium.',
      teaser: 'Desafios inteligentes para manter motivação.',
    ),
  };

  static HamvitFeatureAccess of(HamvitFeature feature) {
    return entries[feature]!;
  }

  static bool isAllowed(HamvitFeature feature, {required bool isPremium}) {
    final access = of(feature);
    return !access.premiumRequired || isPremium;
  }
}
