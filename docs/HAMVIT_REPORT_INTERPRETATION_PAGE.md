# HAMVIT Report - Interpretation Page

## Objective
Add one final page to the HAMVIT PDF report with a professional glossary:
- Title: `Como interpretar este relatório`
- Subtitle: `Guia rápido dos principais indicadores utilizados no acompanhamento HAMVIT.`

This page is appended after `Insights e Recomendações`.

## Scope Applied
- Added only one new final PDF page in:
  - `hamvit_mobile/lib/features/reports/pdf/hamvit_pdf_sections.dart`
- Added a reusable local rendering helper for interpretation cards:
  - `_interpretationItem(...)`

## Content Included
The page includes all required sections:
1. HAMVIT Score (with interpretation bands)
2. Hidratação
3. Alimentação e calorias
4. Macronutrientes
5. Hábitos e consistência
6. Sono
7. Atividade física
8. Evolução corporal e IMC
9. Timeline de progresso
10. Aviso profissional

And final references:
- Organização Mundial da Saúde (OMS)
- American College of Sports Medicine (ACSM)
- American Academy of Sleep Medicine (AASM)
- European Food Safety Authority (EFSA)
- Institute of Medicine (IOM)
- Academy of Nutrition and Dietetics

## Non-Changes (Preserved by Design)
- No chart engine changes
- No calculation changes
- No data source changes
- No database changes
- No Flutter screen changes
- No library changes
- No changes to existing page layouts (outside appending this new final page)

## Notes
- UTF-8 accents are preserved.
- Existing PDF header/footer/page numbering flow remains active, so the new page follows the current style and numbering automatically.
