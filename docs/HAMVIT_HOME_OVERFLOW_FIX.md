# HAMVIT Home Overflow Fix

## Objetivo
Eliminar o erro visual de overflow na tela Hoje/Home sem remover barras de progresso, mantendo dados reais e visual premium.

## Problema observado
Erro de runtime na Home:
- A RenderFlex overflowed by XX pixels on the bottom

Contexto de falha:
- Cards de estatísticas com conteúdo vertical (header + valor + badge + subtítulo + barra + nota)
- Grid com altura insuficiente para telas estreitas

## Correções aplicadas

### 1) Grid de estatísticas da Home
Arquivo:
- hamvit_mobile/lib/features/home/widgets/daily_stats/hamvit_daily_stats_grid.dart

Ajustes:
- Substituído `GridView.count` por `GridView.builder` com `SliverGridDelegateWithFixedCrossAxisCount`.
- Definido `mainAxisExtent` responsivo para garantir altura mínima real:
  - telas estreitas: 188
  - demais: 172

Resultado:
- cards de Água, Hábitos, Atividade e Sono não ficam comprimidos verticalmente.

### 2) Card de estatística resiliente
Arquivo:
- hamvit_mobile/lib/features/home/widgets/daily_stats/hamvit_stat_card.dart

Ajustes:
- Padding interno ajustado para reduzir pressão vertical.
- Adicionado `LayoutBuilder` com modo compacto quando a altura disponível é baixa.
- Controle de linhas e overflow em textos críticos (`title`, `value`, badge e `footerNote`).
- Em modo compacto, reduz conteúdo secundário para priorizar barra + informação essencial.

Resultado:
- barra permanece dentro do card em diferentes densidades de conteúdo.

### 3) Barra de progresso segura
Arquivo:
- hamvit_mobile/lib/features/home/widgets/daily_stats/hamvit_mini_progress_bar.dart

Ajustes:
- Mantida com altura padrão 6px.
- Largura baseada em `double.infinity` e preenchimento com `FractionallySizedBox`.
- `ClipRRect` para bordas e prevenção de extrapolação visual.

Resultado:
- barra não extrapola largura e mantém acabamento visual.

### 4) Grid dos módulos principais da Today
Arquivo:
- hamvit_mobile/lib/features/home/today_page.dart

Ajustes:
- Substituído `GridView.count` por `GridView.builder` com `mainAxisExtent`.
- Altura responsiva dos cards de módulos:
  - telas estreitas: 170
  - demais: 156
- Removido comportamento de layout que pressionava o conteúdo para baixo em cards.

Resultado:
- melhor estabilidade em telas pequenas.

### 5) Scroll e padding inferior da Home
Arquivo:
- hamvit_mobile/lib/features/home/today_page.dart

Ajustes:
- `ListView` com padding inferior calculado para não ficar coberto pela bottom navigation:
  - `safeAreaBottom + kBottomNavigationBarHeight + 24`

Resultado:
- conteúdo final da Home não fica escondido sob a navegação.

## Validação
Comandos executados:
1. `..\\tools\\flutter\\bin\\flutter.bat analyze`

Status:
- analyze sem erros após os ajustes de layout.

## Observação de ambiente
Em ambientes com caminho contendo espaço (`Projeto HAMFIT`), testes e build podem falhar em hooks nativos (`objective_c`) dependendo do comando/contexto. Isso não altera a correção de layout aplicada na Home.
