import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/sync_mutation_entity.dart';
import 'offline_sync_queue.dart';

typedef MutationHandler = Future<void> Function(Map<String, dynamic> payload);

class SyncManager extends ChangeNotifier {
  final OfflineSyncQueueInterface queue;
  final Connectivity? connectivity;

  bool _isOnline = true;
  bool _isSyncing = false;
  int _pendingCount = 0;
  DateTime? _lastSyncedAt;
  List<SyncMutationEntity> _mutations = [];

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final Map<SyncActionType, MutationHandler> _handlers = {};

  SyncManager({required this.queue, this.connectivity}) {
    _init();
  }

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  int get pendingCount => _pendingCount;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  List<SyncMutationEntity> get mutations => List.unmodifiable(_mutations);

  List<SyncMutationEntity> get pendingMutations =>
      _mutations.where((m) => m.isPending || m.isFailed).toList();

  Future<void> _init() async {
    await refreshState();

    if (connectivity != null) {
      _connectivitySubscription = connectivity!.onConnectivityChanged.listen(
        _handleConnectivityChange,
      );
    }
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final hasNoConnection = results.contains(ConnectivityResult.none);
    final wasOffline = !_isOnline;
    _isOnline = !hasNoConnection;
    notifyListeners();

    // Trigger sequential queue dispatch upon reconnection
    if (wasOffline && _isOnline && _pendingCount > 0) {
      processQueue();
    }
  }

  void setOnline(bool online) {
    if (_isOnline == online) return;
    final wasOffline = !_isOnline;
    _isOnline = online;
    notifyListeners();

    if (wasOffline && _isOnline && _pendingCount > 0) {
      processQueue();
    }
  }

  void registerHandler(SyncActionType actionType, MutationHandler handler) {
    _handlers[actionType] = handler;
  }

  Future<void> refreshState() async {
    _mutations = await queue.getAllMutations();
    _pendingCount = await queue.getPendingCount();
    notifyListeners();
  }

  Future<SyncMutationEntity> enqueue({
    required SyncActionType actionType,
    required Map<String, dynamic> payload,
  }) async {
    final mutation = await queue.enqueue(
      actionType: actionType,
      payload: payload,
    );

    await refreshState();

    if (_isOnline && !_isSyncing) {
      // Fire-and-forget background replay
      unawaited(processQueue());
    }

    return mutation;
  }

  Future<void> processQueue() async {
    if (_isSyncing || !_isOnline) return;

    _isSyncing = true;
    notifyListeners();

    try {
      final pendingList = await queue.getPendingMutations();

      for (final mutation in pendingList) {
        if (!_isOnline) break;

        await queue.markSyncing(mutation.id);
        await refreshState();

        final handler = _handlers[mutation.actionType];

        try {
          if (handler != null) {
            await handler(mutation.payload);
          }
          await queue.markCompleted(mutation.id);
        } catch (e) {
          final nextRetry = mutation.retryCount + 1;
          await queue.markFailed(
            mutation.id,
            e.toString(),
            retryCount: nextRetry,
          );
        }
      }

      _lastSyncedAt = DateTime.now();
    } finally {
      _isSyncing = false;
      await refreshState();
    }
  }

  Future<void> retryFailed() async {
    if (!_isOnline) return;

    final failedList = _mutations.where((m) => m.isFailed).toList();
    for (final m in failedList) {
      await queue.updateMutation(
        m.copyWith(status: SyncStatus.pending, errorMessage: null),
      );
    }
    await processQueue();
  }

  Future<void> clearCompleted() async {
    await queue.clearCompleted();
    await refreshState();
  }

  Future<void> deleteMutation(String id) async {
    await queue.deleteMutation(id);
    await refreshState();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
