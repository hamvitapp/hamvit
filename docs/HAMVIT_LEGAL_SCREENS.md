# HAMVIT — Telas Legais Internas

## Objetivo
Implementar telas internas completas para:
- Termos de Uso
- Política de Privacidade

Sem abrir navegador externo e sem placeholder.

## Rotas
- /legal/terms
- /legal/privacy

## Implementação

### Arquivos criados
- lib/features/legal/terms_screen.dart
- lib/features/legal/privacy_policy_screen.dart
- lib/features/legal/widgets/hamvit_legal_widgets.dart

### Arquivos atualizados
- lib/router/app_router.dart
  - Inclusão das rotas /legal/terms e /legal/privacy.
  - Inclusão dessas rotas no conjunto de áreas autenticadas.
- lib/shared/widgets/hamvit_side_drawer.dart
  - Item Suporte > Termos agora navega para /legal/terms.
  - Item Suporte > Política de privacidade agora navega para /legal/privacy.

## Padrão visual adotado
- Fundo escuro HAMVIT.
- AppBar com botão voltar (padrão hamvitBackAppBar).
- Título e subtítulo com data de atualização atual.
- Conteúdo dividido em seções (cards) com tipografia legível.
- Scroll vertical com SafeArea e padding inferior.

## Conteúdo jurídico
- Termos de Uso: 20 seções completas.
- Política de Privacidade: 18 seções completas.
- Textos com linguagem clara para usuário comum.
- Inclui limitações de saúde, nutrição, IA, relatórios, premium e dados.

## Critérios de aceite atendidos
- Clique em Termos abre tela interna.
- Clique em Política de privacidade abre tela interna.
- Ambas têm botão voltar.
- Ambas têm scroll vertical.
- Texto completo presente nas duas telas.
- Layout no padrão HAMVIT.
- Sem placeholder e sem link externo.
- Estrutura adequada para telas pequenas.
