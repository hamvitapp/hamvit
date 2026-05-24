class OfflineEntity {
  final String localId;
  final String? remoteId;
  final String syncStatus; // pending, synced, failed, conflict
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSyncAttemptAt;

  const OfflineEntity({
    required this.localId,
    this.remoteId,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
    this.lastSyncAttemptAt,
  });
}
