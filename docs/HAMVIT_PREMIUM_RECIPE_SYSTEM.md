# HAMVIT Premium Recipe System

## Visão Geral

O sistema de receitas premium do HAMVIT foi refatorado de um sistema puramente visual para um módulo nutricional inteligente completo. As receitas agora funcionam como refeições nutricionais reais, com dados completos, integração com o diário alimentar e recomendações inteligentes.

---

## Estrutura das Receitas

### Tabelas do Banco de Dados

#### `recipes`
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | uuid | PK |
| name | text | Nome da receita |
| description | text | Descrição |
| category | text | cafe_da_manha, almoco, jantar, lanche, ceia |
| prep_time_minutes | int | Tempo de preparo em minutos |
| servings | int | Porções padrão |
| image_url | text | URL da imagem |
| calories_kcal | numeric(8,2) | Calorias totais |
| protein_g | numeric(8,2) | Proteínas em gramas |
| carbs_g | numeric(8,2) | Carboidratos em gramas |
| fat_g | numeric(8,2) | Gorduras em gramas |
| premium_only | boolean | Se é exclusiva Premium |
| difficulty | text | facil, medio, dificil |
| source | text | Origem (admin, user) |
| created_at | timestamptz | Data de criação |
| updated_at | timestamptz | Data de atualização |

#### `recipe_ingredients`
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | uuid | PK |
| recipe_id | uuid | FK → recipes.id |
| food_id | uuid | FK → foods.id (opcional) |
| ingredient_text | text | Descrição textual (ex: "2 ovos") |
| quantity | numeric(10,2) | Quantidade |
| grams | numeric(10,2) | Gramas |
| portion_label | text | Unidade (unidade, colher, xícara) |
| step_order | int | Ordem na lista |
| created_at | timestamptz | Data de criação |

#### `recipe_steps`
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | uuid | PK |
| recipe_id | uuid | FK → recipes.id |
| step_order | int | Ordem do passo |
| instruction | text | Instrução detalhada |

#### `recipe_tags_direct`
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | uuid | PK |
| recipe_id | uuid | FK → recipes.id |
| tag | text | Tag (alta proteina, low carb, etc) |
| created_at | timestamptz | Data de criação |

### Tabelas de Interação do Usuário

#### `user_favorite_recipes`
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | uuid | PK |
| user_id | uuid | FK → profiles.id |
| recipe_id | uuid | FK → recipes.id |
| created_at | timestamptz | Data de criação |
| UNIQUE(user_id, recipe_id) | | Garante um favorito por receita |

#### `recipe_rejection_log`
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | uuid | PK |
| user_id | uuid | FK → profiles.id |
| recipe_id | uuid | FK → recipes.id |
| reason | text | Motivo da rejeição |
| created_at | timestamptz | Data de criação |

---

## Registro de Consumo

### Fluxo de Registro

Quando o usuário confirma que consumiu uma receita:

1. **Confirmação**: Modal "Você consumiu esta refeição?" com macros calculados
2. **Ajuste de Porção**: Usuário pode selecionar ½, 1 ou 2 porções
3. **Registro**: Função `register_recipe_consumption()` no PostgreSQL:
   - Cria `meal_log` com recipe_id, servings, macros calculados
   - Cria `meal_items` com os ingredientes convertidos
   - Macros são multiplicados pelo fator de porção
4. **Atualização**: Providers são invalidados para refletir mudanças no:
   - Dashboard (Home)
   - Gráficos
   - Score HAMVIT
   - Sugestões inteligentes
   - Histórico de refeições

### View `daily_macro_summary`

View que agrega dados nutricionais por dia por usuário, usada para consultas rápidas de dashboard.

---

## Recommendation Engine

### Função `get_smart_recipe_recommendations`

Motor de recomendação inteligente que considera:

**Input:**
- `p_user_id`: ID do usuário
- `p_meal_type` (opcional): Tipo de refeição desejada
- `p_limit` (opcional): Número máximo de sugestões

**Critérios de Score:**

| Fator | Peso | Descrição |
|-------|------|-----------|
| Calorias restantes | 0.30 | Se a receita cabe na meta calórica |
| Proteína restante | 0.25 | Se a receita fornece ≥30% da proteína necessária |
| Objetivo do usuário | 0.20 | Low carb → prefere carbs <30g; Ganho de massa → prefere proteína >30g |
| Disponibilidade free | 0.10 | Receitas free têm prioridade |
| Tipo de refeição | 0.15 | Se corresponde ao meal_type solicitado |

**Exclusões:**
- Receitas rejeitadas pelo usuário (via `recipe_rejection_log`)
- Receitas que excedem 120% das calorias restantes

**Output:**
- Lista de receitas com score, match_reason e tags
- Ordenadas por score decrescente

---

## Integração Nutricional

### Como as receitas impactam o sistema

1. **Diário Alimentar**: `meal_logs` agora têm `recipe_id` e `total_*` macros
2. **Dashboard Home**: `homeDashboardProvider` é invalidado após registro
3. **Score HAMVIT**: Calorias registradas via receitas entram no cálculo do score diário
4. **Gráficos**: Dados são alimentados via `daily_macro_summary`
5. **Relatórios PDF**: Refeições de receitas aparecem nos relatórios

### Atualização em Tempo Real

Quando uma refeição é registrada:
```dart
ref.invalidate(recipeByIdProvider(recipeId));
ref.invalidate(smartRecommendationsProvider(null));
ref.invalidate(mealHistoryProvider);
ref.invalidate(allRecipesProvider);
```

---

## Sistema Premium

| Funcionalidade | Free | Premium |
|---------------|------|---------|
| Ver receitas free | ✅ | ✅ |
| Ver receitas premium | ❌ | ✅ |
| Registrar consumo manual | ✅ | ✅ |
| Registrar consumo de receitas | ✅ | ✅ |
| Sugestões inteligentes | ❌ | ✅ |
| Favoritar receitas | ✅ | ✅ |
| "Não gostei" / Rejeitar | ✅ | ✅ |
| Trocar receita | ✅ | ✅ |
| Histórico de refeições | ✅ | ✅ |
| Recomendações automáticas | ❌ | ✅ |
| Montagem inteligente do dia | ❌ | ✅ |

---

## Telas Implementadas

### `RecipeDetailsScreen`
Tela completa da receita com:
- Header com gradiente por categoria
- Nome e descrição
- Chips de tempo, porções, kcal, proteína, dificuldade
- Tags (alta proteína, low carb, etc.)
- Card nutricional com macros e barra visual
- Ajuste de porção (0.5x, 1x, 2x)
- Botão "Registrar refeição" com confirmação
- Lista de ingredientes
- Modo de preparo (passo a passo)
- Botões: Favoritar, Não gostei, Trocar
- Favoritar (coração no AppBar)

### `RecipeSuggestionsScreen`
Substitui `MealRecommendationsPage` legado:
- Filtro por tipo de refeição
- Cards de sugestão com score e motivo
- Ações: Ver receita, Não gostei
- Seção de favoritos (horizontal scroll)
- Histórico baseado em meal_logs reais
- Estados vazios com call-to-action

### `PremiumSuggestionsScreen`
Versão premium com layout expandido:
- Card "Com base no seu dia"
- Filtro por tipo de refeição
- Sugestões com match_reason detalhado
- Favoritos e histórico

---

## Favoritos

### API
- `toggleFavorite(recipeId)`: Adiciona/remove dos favoritos
- `fetchFavorites()`: Lista receitas favoritas
- Provider `favoriteRecipesProvider` para UI reativa

### Armazenamento
Tabela `user_favorite_recipes` com UNIQUE(user_id, recipe_id)

---

## "Não Gostei" / Rejeição

### Fluxo
1. Usuário clica "Não gostei"
2. Registro em `recipe_rejection_log` com user_id, recipe_id, reason
3. `smartRecommendationsProvider` é invalidado
4. Receita rejeitada é excluída das sugestões futuras

---

## Trocar Receita

### Fluxo
1. Usuário clica "Trocar"
2. Busca sugestões inteligentes para mesma categoria
3. Modal com alternativas disponíveis
4. Navega para a nova receita selecionada

---

## Seeds

22 receitas seed incluídas com:
- Dados completos (macros, calorias, porções)
- Ingredientes categorizados
- Modo de preparo passo a passo
- Tags (alta proteína, rápido, caseiro)
- Distribuição por todas as categorias
- 3 receitas premium exclusivas

---

## Como Executar a Migration

```bash
supabase migration up
```

Ou execute o SQL manualmente:
```sql
\i supabase/migrations/20260526000022_premium_recipe_system.sql
```

---

## Arquivos do Código

| Arquivo | Descrição |
|---------|-----------|
| `lib/features/nutrition/models/recipe.dart` | Modelo Recipe |
| `lib/features/nutrition/models/recipe_ingredient.dart` | Modelo RecipeIngredient |
| `lib/features/nutrition/models/recipe_step.dart` | Modelo RecipeStep |
| `lib/features/nutrition/recipe_repository.dart` | Repositório com todas as operações |
| `lib/features/nutrition/recipe_provider.dart` | Providers Riverpod |
| `lib/features/nutrition/screens/recipe_details_screen.dart` | Tela detalhada da receita |
| `lib/features/nutrition/screens/recipe_suggestions_screen.dart` | Tela de sugestões |
| `lib/features/nutrition/screens/premium_suggestions_screen.dart` | Tela premium completa |
| `lib/theme/hamvit_colors.dart` | Cores dos macros e tema |
| `supabase/migrations/20260526000022_premium_recipe_system.sql` | Migration completa |

---

## Próximos Passos (Melhorias Futuras)

1. Upload de fotos reais para receitas
2. IA para gerar receitas personalizadas
3. Compartilhamento de receitas entre usuários
4. Avaliação (estrelas) das receitas
5. Lista de compras automática baseada em ingredientes
6. Integração com WhatsApp/cardápio semanal
7. Receitas sazonais (baseadas em estação do ano)