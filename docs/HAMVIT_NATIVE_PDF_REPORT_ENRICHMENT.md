# HAMVIT Native PDF Report Enrichment

## Escopo
- Enriquecimento visual e analítico do relatório PDF **nativo** (somente `package:pdf`).
- Mantida a arquitetura sem Flutter widgets, sem `fl_chart`, sem screenshot e sem `MediaQuery`.

## Melhorias implementadas
- Capa premium com:
  - logo HAMVIT em destaque
  - slogan
  - nome do usuário
  - período
  - data de geração
  - card de score
  - 4 mini cards (água média, calorias médias, hábitos, sono médio)
- Resumo executivo reforçado com cards:
  - score, peso atual, IMC atual, água média, calorias médias, consistência, sono médio, tempo ativo
- Gráficos/seções com contexto:
  - título, subtítulo, média, meta, pico, legenda e insight curto
- Seções enriquecidas:
  - Hidratação
  - Alimentação + macros (barra segmentada)
  - Hábitos (resumo + heatmap)
  - Sono
  - Atividade física
  - Evolução corporal (com fallback elegante)
  - Timeline de progresso
- Fallback elegante para ausência de dados em todas as seções:
  - `Sem dados suficientes neste período.`

## Arquivos principais
- `hamvit_mobile/lib/features/reports/pdf/hamvit_report_data.dart`
- `hamvit_mobile/lib/features/reports/pdf/hamvit_pdf_theme.dart`
- `hamvit_mobile/lib/features/reports/pdf/hamvit_pdf_charts.dart`
- `hamvit_mobile/lib/features/reports/pdf/hamvit_pdf_sections.dart`
- `hamvit_mobile/lib/features/reports/pdf/hamvit_pdf_report_service.dart`
- `hamvit_mobile/lib/features/reports/report_pdf_service.dart`

## Fontes e acentuação
- Mantido uso de TTF para português:
  - `assets/fonts/Roboto-Regular.ttf`
  - `assets/fonts/Roboto-Bold.ttf`
- `pubspec.yaml` atualizado com `assets/fonts/`.

## Validação
- Geração de PDF nativo de teste:
  - `hamvit_mobile/build/reports/hamvit_native_report_7d.pdf`
- Sem dependência de captura/renderização de widgets Flutter no pipeline PDF.
- Sem retorno à estratégia que causava erro vermelho.

