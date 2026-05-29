# HAMVIT PDF Native Report Fix

## Decisão final aplicada
- Removido o caminho de geração baseado em captura de widgets Flutter.
- Pipeline de PDF agora é 100% nativo com `package:pdf` e dados puros.

## O que foi feito
- Novo modelo puro de relatório:
  - `hamvit_mobile/lib/features/reports/pdf/hamvit_report_data.dart`
- Novo tema PDF com fonte TTF e acentuação:
  - `hamvit_mobile/lib/features/reports/pdf/hamvit_pdf_theme.dart`
- Novos gráficos nativos PDF:
  - `hamvit_mobile/lib/features/reports/pdf/hamvit_pdf_charts.dart`
- Novas seções do relatório:
  - `hamvit_mobile/lib/features/reports/pdf/hamvit_pdf_sections.dart`
- Novo serviço de montagem do documento:
  - `hamvit_mobile/lib/features/reports/pdf/hamvit_pdf_report_service.dart`
- Integração no serviço principal:
  - `hamvit_mobile/lib/features/reports/report_pdf_service.dart`

## Removido do pipeline
- `report_widget_image_renderer.dart`
- `report_chart_renderer.dart`
- `report_layout_engine.dart`
- `report_theme.dart`
- arquivos PDF legados baseados em painters/model antigo

## Fontes e acentuação
- Adicionado:
  - `hamvit_mobile/assets/fonts/Roboto-Regular.ttf`
  - `hamvit_mobile/assets/fonts/Roboto-Bold.ttf`
- `pubspec.yaml` atualizado com `assets/fonts/`.
- Textos agora com acentuação correta no PDF (ex.: Relatório, Evolução, Usuário, Período, Hábitos, Água).

## Gráficos nativos implementados
- Linha simples:
  - peso
  - IMC
  - calorias
  - sono
  - timeline de progresso
- Barras:
  - hidratação por dia
  - atividade física por dia
- Heatmap:
  - consistência de hábitos
- Barra segmentada:
  - macros (proteína/carboidrato/gordura)

## Fallbacks premium
- Quando não há dados: `Sem dados suficientes no período.`
- Mensagens contextuais no layout principal para casos de ausência de dados.
- O PDF continua gerando mesmo se uma seção não tiver dados.

## Validação executada
- `flutter analyze` do novo pipeline: sem erro de compilação (apenas avisos de estilo).
- PDF nativo de teste gerado:
  - `hamvit_mobile/build/reports/hamvit_native_report_7d.pdf`
- Verificação textual do PDF:
  - sem `No MediaQuery`
  - sem `MaterialLocalizations`
  - sem stack trace
  - sem `Sparkline preview`

