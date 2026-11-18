import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/sync_mutation_entity.dart';
import '../database/app_database.dart';
import '../database/database_tables.dart';

abstract class OfflineSyncQueueInterface {
  Future<SyncMutationEntity> enqueue({
    required SyncActionType actionType,
    required Map<String, dynamic> payload,
  });

  Future<List<SyncMutationEntity>> getPendingMutations();

  Future<List<SyncMutationEntity>> getAllMutations();

  Future<int> getPendingCount();

  Future<void> updateMutation(SyncMutationEntity mutation);

  Future<void> markSyncing(String id);

  Future<void> markCompleted(String id);

  Future<void> markFailed(String id, String error, {int? retryCount});

  Future<void> deleteMutation(String id);

  Future<void> clearCompleted();

  Future<void> clearAll();
}

class OfflineSyncQueue implements OfflineSyncQueueInterface {
  final AppDatabase database;
  final Uuid _uuid = const Uuid();

  OfflineSyncQueue({required this.database});

  @override
  Future<SyncMutationEntity> enqueue({
    required SyncActionType actionType,
    required Map<String, dynamic> payload,
  }) async {
    final db = await database.database;
    final mutation = SyncMutationEntity(
      id: 'mut_${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4().substring(0, 8)}',
      actionType: actionType,
      payload: payload,
      status: SyncStatus.pending,
      retryCount: 0,
      createdAt: DateTime.now(),
    );

    await db.insert(
      DatabaseTables.syncQueue,
      mutation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return mutation;
  }

  @override
  Future<List<SyncMutationEntity>> getPendingMutations() async {
    final db = await database.database;
    final results = await db.query(
      DatabaseTables.syncQueue,
      where: "status IN ('pending', 'failed') AND retry_count < 5",
      orderBy: 'created_at ASC',
    );

    return results.map((map) => SyncMutationEntity.fromMap(map)).toList();
  }

  @override
  Future<List<SyncMutationEntity>> getAllMutations() async {
    final db = await database.database;
    final results = await db.query(
      DatabaseTables.syncQueue,
      orderBy: 'created_at DESC',
    );

    return results.map((map) => SyncMutationEntity.fromMap(map)).toList();
  }

  @override
  Future<int> getPendingCount() async {
    final db = await database.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM ${DatabaseTables.syncQueue} WHERE status IN ('pending', 'failed')",
    );
    if (result.isNotEmpty) {
      return (result.first['count'] as int?) ?? 0;
    }
    return 0;
  }

  @override
  Future<void> updateMutation(SyncMutationEntity mutation) async {
    final db = await database.database;
    await db.update(
      DatabaseTables.syncQueue,
      mutation.toMap(),
      where: 'id = ?',
      whereArgs: [mutation.id],
    );
  }

  @override
  Future<void> markSyncing(String id) async {
    final db = await database.database;
    await db.update(
      DatabaseTables.syncQueue,
      {'status': SyncStatus.syncing.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> markCompleted(String id) async {
    final db = await database.database;
    await db.update(
      DatabaseTables.syncQueue,
      {'status': SyncStatus.completed.name, 'error_message': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> markFailed(String id, String error, {int? retryCount}) async {
    final db = await database.database;
    final values = <String, dynamic>{
      'status': SyncStatus.failed.name,
      'error_message': error,
    };
    if (retryCount != null) {
      values['retry_count'] = retryCount;
    }

    await db.update(
      DatabaseTables.syncQueue,
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteMutation(String id) async {
    final db = await database.database;
    await db.delete(DatabaseTables.syncQueue, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> clearCompleted() async {
    final db = await database.database;
    await db.delete(
      DatabaseTables.syncQueue,
      where: 'status = ?',
      whereArgs: [SyncStatus.completed.name],
    );
  }

  @override
  Future<void> clearAll() async {
    final db = await database.database;
    await db.delete(DatabaseTables.syncQueue);
  }
}
