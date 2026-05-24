# HAMVIT Habits Module

## Objetivo
Implementar o modulo de Habitos com dados reais, persistencia no Supabase, feedback visual diario e resiliencia para ambientes com schema legado.

## Escopo da entrega
- Tela real de Habitos com resumo, lista, historico semanal e streak.
- Criacao, edicao, exclusao e marcacao de conclusao diaria.
- Estado vazio com sugestoes e CTA para criar habito.
- Integracao do progresso de habitos no dashboard da Home.
- Migration incremental para consolidar schema e RLS.

## Arquitetura
### Camada de UI
- HabitsScreen: tela principal da feature.
- HabitsWidgets: cards e componentes visuais reutilizaveis.
- HabitsPage: wrapper legado para manter compatibilidade de navegacao.

### Camada de estado
- HabitsController: regras de negocio e orchestration.
- HabitsState: estado imutavel da feature (loading, erro, lista, resumo, streak, historico).
- Providers derivados para razao de conclusao e label diario.

### Camada de dados
- HabitRepository: leitura e escrita no Supabase.
- Suporte a schema novo e fallback para schema legado em pontos criticos.

## Arquivos principais
- hamvit_mobile/lib/features/habits/habits_screen.dart
- hamvit_mobile/lib/features/habits/habits_widgets.dart
- hamvit_mobile/lib/features/habits/habit_controller.dart
- hamvit_mobile/lib/features/habits/habit_provider.dart
- hamvit_mobile/lib/features/habits/habit_repository.dart
- hamvit_mobile/lib/features/habits/habit_model.dart
- hamvit_mobile/lib/features/habits/habits_page.dart
- hamvit_mobile/lib/features/home/today_page.dart
- supabase/migrations/20260524000009_habits_module_real.sql

## Fluxo funcional
1. Usuario abre a aba Habitos.
2. Controller carrega habitos ativos e resumo diario.
3. UI mostra:
- card de progresso diario X/Y;
- botao principal unico "Criar habito";
- streak atual e melhor streak;
- historico semanal por habito;
- cards com acao de concluir/desfazer.
4. Se nao houver habitos, UI mostra card de sugestoes com chips selecionaveis e botao "Usar sugestao".
5. Usuario cria ou edita habito em bottom sheet.
6. Usuario pode selecionar um chip e usar "Usar sugestao" para criar rapidamente o habito sugerido.
7. Toggle de conclusao registra log do dia e recalcula resumo/streak.
8. Home reflete percentual real de habitos concluidos.

## Regras importantes
- Sem habitos ativos: mostrar empty state com sugestoes.
- Regra de UX: nao exibir dois botoes com a mesma funcao. O CTA "Criar habito" aparece apenas uma vez na tela.
- No estado vazio, o card de sugestoes nao possui botao "Criar habito" interno; apenas "Usar sugestao".
- Botao "Usar sugestao" fica desabilitado ate o usuario selecionar um chip de sugestao.
- Conclusao diaria eh por data local atual.
- Exclusao prioriza inativacao (active=false); fallback para delete quando necessario.
- Client UUID de sincronizacao segue padrao user_habit_date.
- Operacoes exigem usuario autenticado para escrita.

## Banco de dados e seguranca
Migration:
- supabase/migrations/20260524000009_habits_module_real.sql

Principais pontos:
- Expansao de user_habits para campos semanticos (titulo, descricao, categoria, frequencia, ativo, metadados).
- Expansao de habit_logs para suporte completo de conclusao diaria e sincronizacao.
- Atualizacoes em habit_templates e user_streaks.
- Indices para consultas frequentes.
- Politicas RLS por ownership em user_habits e habit_logs.

## Compatibilidade com legado
Enquanto a migration nao estiver aplicada em todos os ambientes, o repositorio usa fallback em operacoes de leitura/escrita para colunas antigas.

## Validacao tecnica
Resultado mais recente:
- flutter analyze: sem issues.

Observacao:
- flutter test possui falhas atuais na suite de recomendacoes de refeicao e nao estao relacionadas ao modulo Habitos.

## Checklist de aceite rapido
- Abrir aba Habitos sem tela em branco.
- Criar habito manualmente.
- Usar sugestao no estado vazio.
- Marcar e desmarcar habito no dia.
- Editar e remover habito.
- Ver resumo X/Y atualizado em Habitos e Home.
- Confirmar historico semanal e card de streak.
