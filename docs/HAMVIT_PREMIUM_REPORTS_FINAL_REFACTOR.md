# HAMVIT Premium Reports Final Refactor

## Resultado
- O PDF foi refatorado para formato visual premium com foco em leitura wellness/clinica.
- Removidos placeholders tipo sparkline simplificado do fluxo principal.
- PDF agora usa captura de widgets reais Flutter como imagem antes da montagem do documento.

## Arquitetura
- `report_widget_image_renderer.dart`:
  - Renderiza widgets reais (line charts, heatmap, donut de macros, timeline).
  - Captura em imagem via `ScreenshotController.captureFromWidget`.
  - Entrega `ReportChartImages`.
- `report_chart_renderer.dart`:
  - Contrato tipado `ReportChartImages`.
- `report_pdf_service.dart`:
  - `generateEvolutionPdf` recebe `charts`.
  - Encaminha para layout.
- `report_layout_engine.dart`:
  - Novo layout editorial com componentes premium:
    - `ReportExecutiveCard`
    - `ReportChartSection`
    - `ReportInsightCard`
    - `ReportMetricGrid`
    - `ReportTrendComparison`
    - `ReportEmptyState`
  - Rodape com paginação e data de geração.
- `report_theme.dart`:
  - Paleta/estilos premium de PDF.
- `report_insight_engine.dart`:
  - Motor contextual de insights com comparação temporal (período atual vs anterior).

## Dados e insights
- Dados continuam vindo do `ReportRepository` com base em Supabase.
- Suporte de período: `7d`, `15d`, `30d`, `all`.
- Insight contextual por domínio:
  - hidratação
  - calorias
  - hábitos/consistência
  - sono
  - atividade
  - proximidade da meta de peso

## Estados vazios
- Evita visual de erro e evita narrativa com valor zero como se fosse dado válido.
- Usa mensagens premium:
  - `Sem dados suficientes no período.`
  - `Registre mais informações para análises mais completas.`

## Fluxo Premium/Free
- Free: continua com visualização em tela.
- Premium: geração PDF completa com gráficos reais capturados.

## Observações
- A captura de widget usa o mesmo stack visual dos componentes Flutter de gráfico, preservando identidade do app.
- A tela `EvolutionReportScreen` agora gera imagens antes de chamar o serviço de PDF.

