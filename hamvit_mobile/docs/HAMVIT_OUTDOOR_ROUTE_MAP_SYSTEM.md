# HAMVIT Outdoor Route Map System

## Arquitetura
- `indoor`: continua manual/estimado, sem mapa.
- `outdoor`: usa GPS real, rota, mapa e pontos salvos.
- Seletor único em `activity_type_selector.dart`.

## Stack
- `geolocator`: stream de localização.
- `permission_handler`: preparado no projeto para permissões adicionais.
- `flutter_map` + `latlong2`: mapa e polyline (OpenStreetMap).

## Provider de mapa
- Arquivo: `lib/core/maps/map_tile_provider_config.dart`
- MVP usa OSM com camada configurável para troca futura (MapTiler/Mapbox).

## Banco e RLS
- Migration: `supabase/migrations/20260601_activity_route_points.sql`
- Tabela nova: `activity_route_points`
- Índices: `activity_session_id`, `user_id`, `recorded_at`
- RLS: usuário só lê/escreve/remove os próprios pontos e apenas em sessão própria.

## Fluxo Outdoor
1. Usuário seleciona caminhada/corrida outdoor.
2. Tela `OutdoorActivityTrackingScreen` pede permissão de localização.
3. Captura pontos válidos com filtro de precisão/salto.
4. Exibe mapa e polyline em tempo real.
5. Finaliza e salva `activity_sessions` + `activity_route_points`.

## Filtros de GPS
- Ignora `accuracy > 50m`
- Ignora salto irreal por velocidade
- Salva quando distância >= 5m ou tempo >= 5s

## Cálculos
- Distância: soma de segmentos válidos GPS.
- Velocidade média: `distância_km / duração_h`.
- Ritmo médio: `duração_s / distância_km`.
- Calorias: estimativa por MET (mantendo padrão do app).

## Histórico e detalhe
- Histórico continua agrupado (Hoje/Ontem/Esta semana/Mais antigas).
- Card agora abre `ActivityDetailScreen`.
- Outdoor mostra `ActivityRouteMapWidget` com início/fim.
- Indoor não mostra mapa.

## Offline
- Se mapa não carregar tiles, tracking continua.
- Sessão continua sendo salva; fila offline existente segue ativa para sessão.
- Ponto futuro: fila local robusta para `route_points` também.

## Próximos passos
- Sync offline completo de `route_points`.
- Health Connect / Apple Health / smartwatch.
- Upgrade de provider de tiles com chave e cache controlado.
