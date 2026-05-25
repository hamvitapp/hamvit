# HAMVIT Evolution Reports

## Objetivo

Centralizar o fluxo de relatório em uma única experiência:

- Tela principal: `/reports/evolution`
- Período: `7 dias`, `15 dias`, `30 dias`, `Todos`
- PDF profissional gerado dentro da própria tela
- Compartilhamento por Share Sheet
- Histórico persistido em `generated_reports`

## Regras de acesso

### Plano Free

- Pode visualizar o relatório completo em tela.
- Não pode gerar PDF profissional.
- Não pode compartilhar com profissional pela ação dedicada.
- Ao tocar nas ações bloqueadas, recebe `PremiumTeaserCard` com upgrade não agressivo.

### Plano Premium Vitalício

- Pode gerar PDF profissional na tela de evolução.
- Pode compartilhar relatório (Share Sheet) com rastreio em `report_shares`.

## Arquitetura (mobile)

### Novos arquivos

- `hamvit_mobile/lib/features/reports/report_controller.dart`
- `hamvit_mobile/lib/features/reports/report_period_selector.dart`
- `hamvit_mobile/lib/features/reports/report_repository.dart`
- `hamvit_mobile/lib/features/reports/report_pdf_service.dart`
- `hamvit_mobile/lib/features/reports/evolution_report_screen.dart`

### Responsabilidades

- `report_controller.dart`
  - Estado de período atual (`reportPeriodProvider`).
  - Carregamento de dados consolidados (`evolutionReportProvider`).
  - Histórico de relatórios (`reportHistoryProvider`).

- `report_repository.dart`
  - Consulta dados reais no Supabase para peso, IMC, água, calorias/macros, hábitos, atividade e sono.
  - Agrega por período e produz objeto `EvolutionReportData`.
  - Registra compartilhamentos em `report_shares`.

- `report_pdf_service.dart`
  - Gera PDF multi-página com branding HAMVIT.
  - Faz upload para bucket privado `report-pdfs`.
  - Registra metadados em `generated_reports`.

- `evolution_report_screen.dart`
  - Interface principal do relatório de evolução.
  - Seletor 7/15/30/todos.
  - Seções: resumo, evolução corporal, alimentação, hidratação, hábitos, atividade, sono e insights.
  - Barra de ações: baixar PDF, enviar ao nutricionista/médico, ver histórico.

## Rotas e navegação

- Nova rota ativa:
  - `/reports/evolution`

- Ajustes realizados:
  - Drawer em Relatórios usa `Relatório de evolução`.
  - Item legado separado de `Exportar PDF` removido do drawer.
  - Fluxo legado de rota `/reports/pdf` removido do roteador principal.

## Banco de dados e segurança

### Tabelas

- `generated_reports`
  - Uso de colunas existentes: `report_type`, `pdf_path`, `summary_json`, `ready_at`.
  - Nova coluna adicionada: `period_type`.

- `report_shares`
  - Registro de compartilhamentos com `channel`, `shared_at`, `user_id`.

### Storage

- Bucket privado: `report-pdfs`
- Políticas em `storage.objects` com escopo por usuário (`owner = auth.uid()`) para:
  - `SELECT`
  - `INSERT`
  - `UPDATE`
  - `DELETE`

### Migration

- `supabase/migrations/20260525000018_evolution_reports_storage_and_period.sql`

## UX e produto

- O usuário não precisa sair da tela de evolução para gerar/compartilhar PDF.
- O período selecionado altera tanto os cards quanto os gráficos e o documento PDF.
- O histórico de geração é invalidado e recarregado após geração/compartilhamento.

## Observações

- O compartilhamento usa o Share Sheet nativo (`printing.sharePdf`).
- O upload do PDF é tolerante a falhas; mesmo em caso de falha de upload, a geração local pode ser compartilhada.
- O registro em banco tenta persistir `report_id` para rastrear o canal de compartilhamento.
