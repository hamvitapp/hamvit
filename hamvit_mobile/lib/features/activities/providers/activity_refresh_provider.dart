import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Contador simples que é incrementado periodicamente enquanto uma atividade
/// está em andamento. Usado para notificar telas (ex: Hoje) que devem
/// invalidar/atualizar seus providers.
final activityRefreshTickProvider = StateProvider<int>((ref) => 0);
