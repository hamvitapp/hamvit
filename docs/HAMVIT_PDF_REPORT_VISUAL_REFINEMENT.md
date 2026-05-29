# HAMVIT PDF Report — Visual Refinement: Premium Cover, Logo per Page, Charts with Scale

## Resumo da Melhoria

Refinamento visual completo do PDF HAMVIT para torná-lo um relatório profissional adequado para médicos, nutricionistas e apresentação ao usuário final. Mantendo 100% da arquitetura nativa `package:pdf` com dados puros — sem Flutter widgets, sem fl_chart, sem screenshots.

---

## 1. CAPA PREMIUM (Primeira Página)

A capa foi completamente redesenhada com:

- **Gradiente HAMVIT**: degradê escuro `#071A2D` → `#0F2D4F` → `#1A4A78`
- **Logo HAMVIT em destaque**: badge ciano com texto branco e tracking
- **Slogan**: *"Evolua no seu ritmo."*
- **Identificação do usuário**: com avatar (emoji 👤), nome, período, data de geração
- **HAMVIT Score grande e dourado**: valor numérico grande (48pt) + score barra de progresso + mensagem qualitativa
- **4 Cards de resumo**: Água média, Calorias médias, Hábitos (%), Sono médio — com emojis, labels e valores
- **Rodapé da capa**: HAMVIT + página

### Arquivo: `hamvit_pdf_sections.dart` → função `buildCoverSummary()`

---

## 2. LOGO EM TODAS AS PÁGINAS

Implementado como **wordmark estilizado** no topo esquerdo de cada página:

- Badge azul com `H` dentro, seguido de `HAMVIT` em azul e nome da seção
- Alinhado com o cabeçalho da página
- Renderizado via `theme.pageHeader(sectionName, periodText)`
- Incluído em cada seção do relatório (Hidratação, Nutrição, Hábitos, Sono, etc.)

### Fallback visual:
- Usa wordmark "HAMVIT" estilizado (texto + badge azul) até o asset real ser integrado
- Totalmente discreto e consistente

### Arquivo: `hamvit_pdf_theme.dart` → método `pageHeader()`

---

## 3. CABEÇALHO PADRÃO

Todas as páginas (exceto capa) possuem:

- Mini logo + wordmark HAMVIT (topo esquerdo)
- Nome da seção (ex.: "Hidratação", "Nutrição")
- Período do relatório (topo direito)
- Linha divisória discreta

### Arquivo: `hamvit_pdf_theme.dart` → `pageHeader(sectionName, periodText)`

---

## 4. GRÁFICOS COM ESCALA NUMÉRICA

Todos os gráficos (`chartCard`) agora possuem:

| Recurso | Detalhes |
|---------|----------|
| **Eixo Y** | 5–6 marcações numéricas automáticas (ex.: 0, 1000, 2500, 3750, 5000) |
| **Unidade** | ml, kcal, h, kg, pts conforme o gráfico |
| **Labels** | Discretos, alinhados à esquerda, fonte 7pt |
| **Grid de fundo** | Linhas horizontais finas |
| **Linha de meta** | Vermelha (`#FF6B6B`) com badge "Meta X unit" |
| **Valor no topo** | Exibido na barra mais alta |
| **Legenda clara** | Explica barras, linha vermelha, período |

### Escalas por gráfico:

| Gráfico | Unidade | Meta | Marcações (exemplo) |
|---------|---------|------|---------------------|
| Hidratação | ml (ou L se >1000) | `d.waterGoal` | 0, 1250, 2500, 3750, 5000 |
| Calorias | kcal | `d.caloriesGoal` | 0, 750, 1500, 2250, 3000 |
| Sono | h | 8.0 | 0, 2, 4, 6, 8, 10 |
| Atividade | kcal | `d.caloriesGoal` | 0, 250, 500, 750, 1000 |
| Peso | kg | `d.weightTarget` | 0, 20, 40, 60, 80, 100 |
| Timeline | pts | 70 | 0, 25, 50, 75, 100 |

### Arquivo: `hamvit_pdf_charts.dart` → funções `_buildScaleTicks()`, `chartCard()`

---

## 5. LEGENDAS MELHORES

Cada gráfico agora tem legenda específica no formato:

> `Barras: {descrição} em {unidade}. Linha vermelha: {descrição da meta} ({valor meta} {unidade}). Período analisado: período completo.`

Exemplos reais:
- Hidratação: *"Barras: consumo diário de água em ml. Linha vermelha: Meta diária de hidratação (3000 ml). Período analisado: período completo."*
- Sono: *"Barras: horas dormidas por dia em h. Linha vermelha: Meta de horas de sono (8 h). Período analisado: período completo."*
- Timeline: *"Barras: pontuação diária de constância (escala 0-100) em pts. Linha vermelha: Meta de consistência (70 pts) (70 pts). Período analisado: período completo."*

### Arquivo: `hamvit_pdf_charts.dart` → dentro de `chartCard()`

Heatmap:
- Escala visual com gradiente 0–100% + legenda explicativa

Macros:
- Dots coloridos + gramas + legenda "distribuição percentual de macronutrientes"

---

## 6. VALORES NOS GRÁFICOS

- **Valor no topo da barra mais alta** em cada gráfico
- **Métrica resumo**: média, meta e pico exibidos em pills acima do gráfico
- Quantidade controlada para não poluir visualmente

---

## 7. GRÁFICOS VAZIOS (Fallback)

Quando há poucos ou nenhum dado:

- Card elegante com ícone, mensagem explicativa e dica de ação
- Exemplo: *"Registre peso ao menos 2 vezes para gerar curva de evolução."*
- Dica extra: *"Registre dados continuamente para habilitar gráficos completos."*
- Não deixa espaço vazio nem card grande sem conteúdo

### Arquivo: `hamvit_pdf_charts.dart` → função `fallbackCard()`

---

## 8. VISUAL PREMIUM CONSISTENTE

| Elemento | Estilo |
|----------|--------|
| Cards | Bordas arredondadas (12px), borda sutil `#E3E8F2`, fundo branco |
| Espaçamento | Amplo, hierarquia clara entre seções |
| Paleta | Azul HAMVIT `#168DFF`, ciano `#00B7D8`, mint `#39D98A`, branco, dourado `#FFD700` |
| Tipografia | Roboto Regular/Bold, tamanhos consistentes |
| Alinhamento | Texto e elementos alinhados, margens de 24–32pt |
| Consistência | Mesmo padrão de header, footer, cards entre páginas |

---

## 9. RODAPÉ (Todas as Páginas)

- HAMVIT (com badge H azul)
- Data de geração
- Número da página
- Texto: *"Documento informativo. Não substitui avaliação profissional."*
- Linha divisória acima

### Arquivo: `hamvit_pdf_theme.dart` → método `fullFooter()`

---

## 10. ARQUIVOS MODIFICADOS

| Arquivo | O que mudou |
|---------|-------------|
| `hamvit_pdf_theme.dart` | Novas cores (coverGrad*, goalLine, accentGold, white, lightBg, etc.), novos estilos (cover*, logo*, header*, footer*, *style), método `pageHeader()`, método `fullFooter()`, método `divider()` |
| `hamvit_pdf_charts.dart` | Sistema completo de escala Y automática (`_buildScaleTicks`), grid lines, goal line com badge, value labels, downsample, heatmap com gradiente, fallback mais elegante, macros com dots + gramas |
| `hamvit_pdf_sections.dart` | Capa premium completa (`buildCoverSummary` com score grande + barra + 4 cards + gradiente), todas as seções agora com `t.pageHeader()`, métricas com unit, chartCard com unit/goalLabel, fallback mais descritivo |
| `hamvit_pdf_report_service.dart` | Gradiente na capa, footer rico via `theme.fullFooter()`, data de geração dinâmica, paginação do MultiPage |

---

## 11. CRITÉRIOS DE ACEITE

- [x] Primeira página parece capa premium (gradiente, logo, score dourado, 4 cards)
- [x] Mini logo aparece no topo esquerdo de todas as páginas (wordmark HAMVIT)
- [x] Todos os gráficos têm escala numérica (5-6 ticks automáticos)
- [x] Todos os gráficos têm unidade de medida (ml, kcal, h, kg, pts)
- [x] Todos os gráficos têm legenda útil (barras + linha vermelha + período)
- [x] Metas visíveis nos gráficos (linha vermelha com badge "Meta X unit")
- [x] PDF continua sem erro vermelho (package:pdf puro)
- [x] Acentuação correta (português brasileiro)
- [x] Visual profissional para médico/nutricionista
- [x] 100% nativo package:pdf — sem Flutter widgets, sem fl_chart, sem screenshot