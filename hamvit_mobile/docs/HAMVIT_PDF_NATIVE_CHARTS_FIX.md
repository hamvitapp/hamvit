Resumo da mudança
-----------------
Substituir geração de gráficos por captura de widgets Flutter por renderização nativa no PDF usando apenas o pacote `pdf`.

Arquitetura
----------
- `lib/features/reports/pdf/hamvit_pdf_models.dart`: modelo `HamvitReportData` com dados puros.
- `lib/features/reports/pdf/hamvit_pdf_theme.dart`: cores e estilos para PDFs.
- `lib/features/reports/pdf/hamvit_pdf_chart_painters.dart`: implementações de gráficos (barras, linha-spark, macros, heatmap) usando primitives `pdf`.
- `lib/features/reports/pdf/hamvit_pdf_sections.dart`: seções do relatório que usam os painters.
- `lib/features/reports/pdf/hamvit_pdf_report_service.dart`: serviço de montagem do `pw.Document` a partir de `HamvitReportData`.

Regras importantes
------------------
- Não usar widgets Flutter, `BuildContext`, `MediaQuery`, `fl_chart`, `screenshot`, `RepaintBoundary` nem qualquer captura de tela para gerar o PDF.
- Os chart painters recebem apenas dados puros.
- Se não houver dados, mostrar o fallback: "Sem dados suficientes no período.".

Próximos passos
---------------
1. Integrar `HamvitPdfReportService` no flow de geração de relatório (substituir uso de captura de widgets).
2. Escrever testes com datasets vazios e cheios para cada seção.
3. Ajustar estilos e legendas conforme feedback de design.