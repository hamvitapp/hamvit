import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'offline_entity.dart';

class SyncMutation extends OfflineEntity {
  final String entity;
  final Map<String, dynamic> payload;

  const SyncMutation({
    required super.localId,
    required super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.remoteId,
    super.lastSyncAttemptAt,
    required this.entity,
    required this.payload,
  });
}

class SyncQueueController extends StateNotifier<List<SyncMutation>> {
  SyncQueueController() : super(const []);

  void add(SyncMutation mutation) {
    state = [...state, mutation];
  }

  void markSynced(String localId, {String? remoteId}) {
    state = [
      for (final m in state)
        if (m.localId == localId)
          SyncMutation(
            localId: m.localId,
            remoteId: remoteId ?? m.remoteId,
            syncStatus: 'synced',
            createdAt: m.createdAt,
            updatedAt: DateTime.now(),
            lastSyncAttemptAt: DateTime.now(),
            entity: m.entity,
            payload: m.payload,
          )
        else
          m,
    ];
  }
}

final syncQueueProvider = StateNotifierProvider<SyncQueueController, List<SyncMutation>>((ref) {
  return SyncQueueController();
});
