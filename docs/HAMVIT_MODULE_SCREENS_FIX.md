# HAMVIT Module Screens Fix

## Objetivo
Separar definitivamente o fluxo de onboarding das telas permanentes dos módulos do app, removendo comportamento de questionário em telas de uso diário.

## Resumo das correções

### 1) Rotas separadas
Onboarding (temporário):
- /onboarding
- /onboarding/goal
- /onboarding/body
- /onboarding/activity
- /onboarding/food
- /onboarding/sleep
- /onboarding/hydration

Telas permanentes (módulos reais):
- /home
- /profile/goals
- /profile/body
- /nutrition
- /activities
- /habits
- /sleep
- /hydration
- /settings/preferences

Arquivo principal:
- hamvit_mobile/lib/router/app_router.dart

### 2) Drawer corrigido
Menu Meu Perfil agora abre somente telas permanentes:
- Objetivos -> /profile/goals
- Dados corporais -> /profile/body
- Alimentação -> /nutrition
- Atividade Física -> /activities
- Hábitos -> /habits
- Sono -> /sleep
- Hidratação -> /hydration
- Preferências -> /settings/preferences

Arquivo:
- hamvit_mobile/lib/shared/widgets/hamvit_side_drawer.dart

### 3) Tela Objetivos (permanente)
Criada tela real com resumo de perfil/metas e botões corretos:
- objetivo atual
- peso atual
- peso desejado
- altura
- nível de atividade
- preferência alimentar
- restrições
- meta de sono
- meta de água
- meta calórica

Botões:
- Editar objetivo -> /onboarding/goal
- Editar dados corporais -> /profile/body
- Editar alimentação -> /onboarding/food
- Editar sono -> /sleep
- Editar hidratação -> /hydration

Arquivo:
- hamvit_mobile/lib/features/profile/goals_page.dart

### 4) Botão "Editar dados" corrigido
No resumo de objetivos de onboarding, o botão não aponta mais para atividade física. Agora abre tela específica de dados corporais.

Arquivo:
- hamvit_mobile/lib/features/onboarding/presentation/objectives_summary_screen.dart

### 5) Tela Dados Corporais
Criada tela dedicada para editar:
- peso
- altura
- peso desejado
- data de nascimento
- sexo biológico
- meta calórica

Arquivo:
- hamvit_mobile/lib/features/profile/body_data_page.dart

### 6) Alimentação como diário real
Tela refeita para uso contínuo com:
- resumo calórico do dia
- calorias consumidas / meta
- proteínas / carboidratos / gorduras
- refeições do dia (café, almoço, jantar, lanche)
- botão registrar refeição
- scanner de código de barras
- IA da comida (Premium)
- sugestões inteligentes (Premium)
- histórico recente
- preferências alimentares em subárea
- card de soft-gate contextual sem transformar em onboarding

Arquivo:
- hamvit_mobile/lib/features/nutrition/nutrition_page.dart

### 7) Atividade Física como módulo real
Tela refeita com:
- iniciar caminhada
- iniciar corrida
- pausar/retomar/finalizar
- tempo ativo da semana
- distância da semana
- calorias estimadas
- histórico de atividades
- card discreto para completar dados corporais, sem bloqueio

Arquivo:
- hamvit_mobile/lib/features/activities/activities_page.dart

### 8) Hábitos com gestão real
Tela refeita com:
- progresso diário X/Y
- criação de hábito
- edição e remoção de hábito
- categorias
- streak
- checklist funcional
- histórico semanal

Arquivo:
- hamvit_mobile/lib/features/habits/habits_page.dart

### 9) Sono como módulo real
Criada tela permanente de sono com:
- meta de sono
- último registro
- horas dormidas
- qualidade do sono
- histórico semanal
- registrar sono
- editar meta de sono

Campos de registro:
- horário que dormiu
- horário que acordou
- qualidade
- observação opcional

Arquivo:
- hamvit_mobile/lib/features/sleep/sleep_page.dart

### 10) Preferências gerais reais
Criada tela de preferências com:
- aparência/tema
- notificações
- unidades de medida
- idioma
- privacidade
- preferências alimentares
- lembretes
- acessibilidade
- meta de água como item (apontando para /hydration)

Arquivo:
- hamvit_mobile/lib/features/settings/preferences_page.dart

### 11) Hidratação como módulo próprio
Tela refeita com:
- meta diária
- consumo atual
- percentual atingido
- atalhos +200ml, +300ml, +500ml
- histórico do dia
- histórico semanal
- editar meta diária

Arquivo:
- hamvit_mobile/lib/features/hydration/hydration_page.dart

### 12) Componentes compartilhados
Criados componentes reutilizáveis para módulos:
- HamvitSectionHeader
- HamvitMetricCard
- HamvitHistoryCard
- HamvitProgressCard
- HamvitEditGoalButton
- HamvitModuleSummaryCard

Observação:
- HamvitSoftGateCard já existia e foi reutilizado para gate contextual.

Arquivo:
- hamvit_mobile/lib/shared/widgets/hamvit_module_widgets.dart

## Ajustes de dados de perfil
O estado do provider de onboarding foi estendido para suportar dados corporais e meta calórica em contexto de perfil/módulos.

Arquivo:
- hamvit_mobile/lib/features/onboarding/providers/onboarding_profile_provider.dart

## Validação executada
Comando:
- flutter analyze

Resultado:
- No issues found.

## Critérios de aceite atendidos
- Alimentação sem "Passo 3 de 5" em tela permanente.
- Atividade sem "Passo 2 de 5" em tela permanente.
- Sono sem "Passo 4 de 5" em tela permanente.
- Preferências não é mais tela de hidratação.
- Hábitos agora possui gestão funcional de hábitos.
- Objetivos não envia "Editar dados" para Atividade Física.
- Cada tela exibe conteúdo compatível com seu módulo.
- Onboarding isolado nas rotas /onboarding/*.
- Módulos permanentes usam onboarding apenas de forma contextual.
- Navegação livre sem prender usuário em etapas.
