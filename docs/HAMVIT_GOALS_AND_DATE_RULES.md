# HAMVIT Goals and Date Rules

## Objetivo
Padronizar datas no formato brasileiro e centralizar cálculo de metas de saúde para evitar campos livres sem orientação.

## Datas: padrão obrigatório
- Formato de exibição: DD/MM/AAAA.
- Formato interno (API/banco): yyyy-MM-dd.
- Nenhum campo de data deve ser TextField livre sem máscara e sem calendário.

## Componente central de data
Arquivo:
- hamvit_mobile/lib/shared/widgets/hamvit_date_field.dart

Capacidades do componente `HamvitDateField`:
- Label e hint DD/MM/AAAA.
- Date picker ao tocar no ícone de calendário.
- Digitação manual opcional com máscara DD/MM/AAAA.
- Validação de data real.
- Conversão para ISO via callback para persistência.
- Mensagem de erro amigável.

Suporte utilitário:
- hamvit_mobile/lib/core/hamvit_date_utils.dart

## Motor central de metas
Pasta:
- hamvit_mobile/lib/core/goals/

Arquivos:
- goal_calculation_engine.dart
- hydration_goal_calculator.dart
- calorie_goal_calculator.dart
- weight_goal_estimator.dart
- nutrition_target_model.dart

### Regras aplicadas
- TMB: Mifflin-St Jeor.
- GET/TDEE: TMB x fator de atividade.
- Déficit para emagrecimento: seguro e moderado.
- Limites mínimos de segurança calórica:
  - Feminino: mínimo 1200 kcal/dia.
  - Masculino: mínimo 1500 kcal/dia.
  - Sexo não informado: mínimo conservador 1400 kcal/dia.
- Meta de água inicial: 35 ml/kg/dia, arredondada para múltiplos de 50 ml.
- Estimativa de tempo saudável para meta de peso: base de 0,5 kg/semana.

## Telas ajustadas

### Dados corporais
Arquivo:
- hamvit_mobile/lib/features/profile/body_data_page.dart

Ajustes:
- Remoção do campo livre de meta calórica.
- Data de nascimento com `HamvitDateField` (calendário + máscara + validação).
- Card de metas calculadas exibindo:
  - TMB estimada
  - gasto diário estimado
  - meta diária sugerida
  - déficit aplicado
  - proteína estimada
  - meta de água estimada
- Botões:
  - Recalcular metas
  - Entender cálculo

### Objetivos
Arquivo:
- hamvit_mobile/lib/features/profile/goals_page.dart

Ajustes:
- Mostra:
  - objetivo
  - peso atual
  - peso desejado
  - diferença
  - tempo saudável estimado
  - meta calórica estimada
  - meta de água estimada
  - nível de atividade
  - data da última atualização
- Botão adicional de recalcular metas.

### Hidratação
Arquivo:
- hamvit_mobile/lib/features/hydration/hydration_page.dart

Ajustes:
- Meta baseada em cálculo do sistema por peso.
- Texto explicando base do cálculo.
- Exibição: "X ml consumidos de Y ml".
- Ajuste manual apenas em modo avançado com limite e orientação.

### Home
Arquivo:
- hamvit_mobile/lib/features/home/today_page.dart

Ajustes:
- Usa metas calculadas no dashboard quando disponíveis.
- Ação de água aponta para módulo permanente de hidratação.

### Relatórios (PDF)
Arquivo:
- hamvit_mobile/lib/features/reports/reports_pdf_screen.dart

Ajustes:
- Períodos exibidos em DD/MM/AAAA.

## Provider e persistência de metas
Arquivo:
- hamvit_mobile/lib/features/onboarding/providers/onboarding_profile_provider.dart

Ajustes:
- Cálculo automático de metas após atualizações de perfil.
- Persistência das metas em preferências e alvo diário com origem:
  - system_calculated
  - user_advanced_adjusted
- Registro de histórico de metas quando aplicável.

## Supabase migration
Arquivo:
- supabase/migrations/20260524000008_goals_targets_date_rules.sql

Ajustes principais:
- Ampliação de `health_profiles` com campos de perfil corporal e data.
- Ampliação de `daily_nutrition_targets` com água, origem e metadados de cálculo.
- Criação de `goal_history` com RLS por usuário.

## Linguagem UX aplicada
Mensagens de apoio foram escritas com tom:
- acolhedor
- educativo
- sem promessas agressivas

Exemplo:
- "Estimativa saudável aproximada. O ritmo pode variar conforme rotina, adesão e acompanhamento profissional."

## Validação técnica
Comando executado:
- flutter analyze

Resultado:
- No issues found.
