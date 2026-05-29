# Refatoração: Relatório Premium HAMVIT

Objetivo: modernizar e transformar o gerador de PDF atual em um "Relatório de acompanhamento HAMVIT" com aparência premium, storytelling de evolução, gráficos reais e seções modulares.

Work in progress:

- Auditoria do gerador atual: concluída. Arquivos relevantes:
  - `lib/features/reports/report_pdf_service.dart`
  - `lib/features/reports/reports_service.dart`
  - `lib/features/reports/report_repository.dart`
  - `lib/features/reports/reports_pdf_screen.dart`

- Estrutura criada (scaffold):
  - `lib/features/reports/report_theme.dart` — cores e estilos PDF
  - `lib/features/reports/report_chart_renderer.dart` — renderizadores simples de gráficos (sparkline/bar) e heatmap
  - `lib/features/reports/executive_summary_generator.dart` — resumo executivo modular
  - `lib/features/reports/report_layout_engine.dart` — orquestrador de páginas (capa, seções)

Próximos passos (incremental):
1. Refatorar `reports_service`/`report_repository` para garantir que `EvolutionReportData` entregue pontos e séries otimizadas.
2. Iterar layout da capa (tipografia, mini-cards, gradiente). Produzir variações e aprovação.
3. Substituir `barSparkline` por renderer de linha suave (SVG) para versão final.
4. Implementar tratamento de seções vazias (mensagens e CTAs elegantes).
5. Testar geração no emulador e exportar PDF de amostra.
6. Ajustes de performance, watermark e rodapé.
7. Atualizar documentação e critérios de aceite.

Notas de desenvolvimento:
- Mantive a API pública de `ReportPdfService` para não quebrar chamadas existentes.
- A versão inicial usa renderização vetorial simples (barras/heatmap) para garantir gráficos "reais" baseados em dados. Podemos evoluir para linhas suaves com SVG/imagem.
