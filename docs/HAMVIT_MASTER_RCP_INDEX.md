# HAMVIT Master RCP Index

## Ordem oficial de leitura e precedência
1. `HAMVIT_RCP_FULLSTACK_DETALHADO_V2.pdf` (base arquitetural e regras globais)
2. `HAMVIT_RCP_FULLSTACK_UX_BRANDING_NAV_V3.pdf` (UX/branding/navegação)
3. `RCP_HAMVIT_Nutricional_Completo.docx` (regras nutricionais)
4. `RCP_HAMVIT_Educacao_Fisica.docx` (regras de atividade física)
5. `HAMVIT_RCP_MODULO_RECOMENDACAO_ALIMENTAR_V5.pdf` (módulo premium de recomendação)
6. `HAMVIT_300_Receitas_Saudaveis.docx` (base de seed)

## Regra de conflito
- Documento complementar prevalece apenas dentro do módulo específico.
- Fora do módulo específico, prevalece o RCP principal FullStack.

## Decisões obrigatórias consolidadas
- App mobile-first com Flutter + Riverpod + GoRouter.
- Backend/BaaS: Supabase com PostgreSQL, Auth, Storage, Edge Functions e RLS.
- Free funcional + Premium vitalício (sem anúncios e sem assinatura agressiva).
- Navegação com bottom nav de até 5 itens + drawer parcial estilo Facebook (aprox. 82%).
- Scanner de código de barras disponível no Free.
- IA de foto e recomendações alimentares automáticas apenas para Premium.
- Sem uso de service role ou segredos no app Flutter.

## Artefatos gerados nesta inicialização
- Estrutura monorepo: `hamvit_mobile`, `hamvit_admin`, `hamvit_backend`, `supabase`, `docs`, `seeds`.
- Migration inicial com tabelas mandatórias e políticas RLS base.
- Seed estruturado das 300 receitas em JSON e CSV.
- Design system e navegação base no Flutter.

## Pendências reais de ambiente
- Flutter SDK e Dart não encontrados no ambiente.
- Supabase CLI não encontrado no ambiente.
- Sem esses binários, não foi possível rodar build, migrations remotas e testes end-to-end.
