# Registro manual de alimentação

## Objetivo

O diário alimentar registra refeições compostas por alimentos reais, com
quantidade em gramas e macronutrientes calculados no momento do consumo.

## Fluxo

1. O usuário escolhe o tipo de refeição.
2. Pesquisa alimentos cadastrados em `foods`.
3. Informa a quantidade em gramas para cada alimento.
4. Pode editar ou remover itens antes de salvar.
5. O app exibe o total de calorias, proteínas, carboidratos e gorduras.
6. Uma chamada transacional cria `meal_logs` e seus `meal_items`.

## Persistência

Cada item guarda um snapshot nutricional. Alterações futuras no cadastro do
alimento não modificam o histórico do usuário.

Tabelas utilizadas:

- `foods`
- `food_portions`
- `meal_logs`
- `meal_items`

Função transacional:

- `register_manual_meal`

## Integrações

Scanner de código de barras e análise por IA devem convergir para o mesmo
contrato: uma refeição em `meal_logs` e seus alimentos em `meal_items`.

## Atualização da interface

Após salvar, os providers da tela Hoje e do Dashboard são invalidados para que
cards, gráficos, score e relatórios consumam os totais reais persistidos.
