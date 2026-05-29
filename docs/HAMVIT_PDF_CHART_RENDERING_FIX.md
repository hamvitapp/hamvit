# HAMVIT PDF Chart Rendering Fix

## Problema corrigido
- Erro de renderização de gráficos no PDF com tela vermelha (`No MediaQuery widget ancestor found` e afins).

## Causa raiz
- Captura de widget para imagem estava sendo feita fora de uma árvore Flutter completa para charts.

## Correções implementadas
- `report_widget_image_renderer.dart`
  - Criado wrapper completo de captura:
    - `MaterialApp`
    - `MediaQuery`
    - `Directionality`
    - `Theme`
    - `Localizations` (`GlobalMaterialLocalizations`, `GlobalWidgetsLocalizations`, `GlobalCupertinoLocalizations`)
  - Criada função segura:
    - `safeRenderChartToImage(...)`
    - captura exceções
    - loga erro
    - retorna `null` em falha
  - Gráficos de PDF com tamanho fixo (`SizedBox(width: 720, height: 320)`).
  - Removida dependência de widget complexo de tela para captura; usado gráfico puro para PDF.

- `report_layout_engine.dart`
  - Fallback premium para qualquer falha de imagem:
    - `ReportChartFallbackCard`
  - Nunca exibe erro técnico no PDF.
  - Mensagens por contexto:
    - peso: `Sem registros de peso no periodo.`
    - IMC: `IMC sera exibido apos registrar peso e altura.`
    - atividade: `Sem atividades registradas no periodo.`
    - fallback geral: `Grafico indisponivel no momento.`

## Gráficos cobertos
- Peso
- IMC
- Hidratação
- Calorias
- Macros (donut)
- Hábitos (heatmap)
- Sono
- Atividade física
- Timeline de progresso

## Resultado esperado
- PDF nunca exporta tela vermelha.
- Em falha de renderização, mostra card premium de fallback.
- Em ausência de dados, mostra mensagem elegante específica do contexto.

## Validação técnica executada
- `flutter analyze lib/features/reports`
  - sem erros de compilação no módulo de relatórios
  - apenas avisos de estilo (`prefer_const_constructors`)

