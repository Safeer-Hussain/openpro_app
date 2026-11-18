import 'package:flutter_test/flutter_test.dart';
import 'package:open_pro/core/network/sync_manager.dart';
import 'package:open_pro/domain/entities/sync_mutation_entity.dart';

import '../helpers/mock_repositories.dart';

void main() {
  group('SyncMutationEntity Tests', () {
    test('Entity supports copyWith, timeAgo, and serialization parity', () {
      final now = DateTime.now();
      final mutation = SyncMutationEntity(
        id: 'mut_test_1',
        actionType: SyncActionType.likePost,
        payload: {'postId': 'post_101', 'userId': 'user_test'},
        status: SyncStatus.pending,
        retryCount: 0,
        createdAt: now.subtract(const Duration(seconds: 30)),
      );

      expect(mutation.isPending, isTrue);
      expect(mutation.isSyncing, isFalse);
      expect(mutation.isCompleted, isFalse);
      expect(mutation.isFailed, isFalse);
      expect(mutation.timeAgo, equals('Just now'));
      expect(mutation.actionType.label, equals('Like Post'));

      final map = mutation.toMap();
      expect(map['id'], equals('mut_test_1'));
      expect(map['action_type'], equals('likePost'));
      expect(map['status'], equals('pending'));

      final fromMap = SyncMutationEntity.fromMap(map);
      expect(fromMap.id, equals(mutation.id));
      expect(fromMap.actionType, equals(SyncActionType.likePost));
      expect(fromMap.payload['postId'], equals('post_101'));
      expect(fromMap.payload['userId'], equals('user_test'));
      expect(fromMap.status, equals(SyncStatus.pending));

      final updated = mutation.copyWith(
        status: SyncStatus.completed,
        retryCount: 1,
      );
      expect(updated.status, equals(SyncStatus.completed));
      expect(updated.retryCount, equals(1));
      expect(mutation.status, equals(SyncStatus.pending)); // Immutability
    });

    test('SyncActionType and SyncStatus parse enum strings correctly', () {
      expect(
        SyncActionType.fromString('likePost'),
        equals(SyncActionType.likePost),
      );
      expect(
        SyncActionType.fromString('addComment'),
        equals(SyncActionType.addComment),
      );
      expect(
        SyncActionType.fromString('applyJob'),
        equals(SyncActionType.applyJob),
      );
      expect(
        SyncActionType.fromString('bookmarkJob'),
        equals(SyncActionType.bookmarkJob),
      );
      expect(
        SyncActionType.fromString('endorseSkill'),
        equals(SyncActionType.endorseSkill),
      );
      expect(
        SyncActionType.fromString('unknownAction'),
        equals(SyncActionType.custom),
      );

      expect(SyncStatus.fromString('pending'), equals(SyncStatus.pending));
      expect(SyncStatus.fromString('syncing'), equals(SyncStatus.syncing));
      expect(SyncStatus.fromString('completed'), equals(SyncStatus.completed));
      expect(SyncStatus.fromString('failed'), equals(SyncStatus.failed));
      expect(SyncStatus.fromString('unknown'), equals(SyncStatus.pending));
    });
  });

  group('OfflineSyncQueue & SyncManager Unit Tests', () {
    late MockOfflineSyncQueue mockQueue;
    late SyncManager syncManager;

    setUp(() {
      mockQueue = MockOfflineSyncQueue();
      syncManager = SyncManager(queue: mockQueue);
      syncManager.setOnline(false); // start offline
    });

    test('Enqueues mutations and captures pending count offline', () async {
      expect(syncManager.pendingCount, equals(0));

      final mut1 = await syncManager.enqueue(
        actionType: SyncActionType.likePost,
        payload: {'postId': 'p1'},
      );

      final mut2 = await syncManager.enqueue(
        actionType: SyncActionType.addComment,
        payload: {'postId': 'p1', 'content': 'Architecture discussion'},
      );

      expect(syncManager.pendingCount, equals(2));
      expect(syncManager.mutations.length, equals(2));
      expect(mut1.actionType, equals(SyncActionType.likePost));
      expect(mut2.actionType, equals(SyncActionType.addComment));
    });

    test('Processes queue sequentially upon reconnection', () async {
      final processedActions = <String>[];

      syncManager.registerHandler(SyncActionType.likePost, (payload) async {
        processedActions.add('like_${payload['postId']}');
      });

      syncManager.registerHandler(SyncActionType.addComment, (payload) async {
        processedActions.add('comment_${payload['postId']}');
      });

      await syncManager.enqueue(
        actionType: SyncActionType.likePost,
        payload: {'postId': 'post_a'},
      );

      await syncManager.enqueue(
        actionType: SyncActionType.addComment,
        payload: {'postId': 'post_a'},
      );

      expect(processedActions.isEmpty, isTrue);
      expect(syncManager.pendingCount, equals(2));

      // Simulate network restored
      syncManager.setOnline(true);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(processedActions, equals(['like_post_a', 'comment_post_a']));
      expect(syncManager.pendingCount, equals(0));
      expect(syncManager.lastSyncedAt, isNotNull);
    });

    test('Handles handler errors by marking failed with retry count', () async {
      syncManager.registerHandler(SyncActionType.applyJob, (payload) async {
        throw Exception('Network timeout on cloud gateway');
      });

      await syncManager.enqueue(
        actionType: SyncActionType.applyJob,
        payload: {'jobId': 'job_999'},
      );

      syncManager.setOnline(true);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final item = syncManager.mutations.first;
      expect(item.isFailed, isTrue);
      expect(item.retryCount, equals(1));
      expect(item.errorMessage, contains('Network timeout'));
      expect(syncManager.pendingCount, equals(1));
    });

    test(
      'retryFailed retries failed mutations and marks completed on resolution',
      () async {
        var shouldFail = true;

        syncManager.registerHandler(SyncActionType.applyJob, (payload) async {
          if (shouldFail) {
            throw Exception('Flaky endpoint');
          }
        });

        await syncManager.enqueue(
          actionType: SyncActionType.applyJob,
          payload: {'jobId': 'job_retry'},
        );

        syncManager.setOnline(true);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(syncManager.mutations.first.isFailed, isTrue);

        // Fix failure condition and retry
        shouldFail = false;
        await syncManager.retryFailed();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(syncManager.mutations.first.isCompleted, isTrue);
        expect(syncManager.pendingCount, equals(0));
      },
    );

    test('clearCompleted cleans successfully synced records', () async {
      await syncManager.enqueue(
        actionType: SyncActionType.bookmarkJob,
        payload: {'jobId': 'job_1'},
      );

      syncManager.setOnline(true);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(syncManager.mutations.length, equals(1));
      expect(syncManager.mutations.first.isCompleted, isTrue);

      await syncManager.clearCompleted();
      expect(syncManager.mutations.isEmpty, isTrue);
    });

    test('deleteMutation removes single mutation from queue', () async {
      final mut = await syncManager.enqueue(
        actionType: SyncActionType.endorseSkill,
        payload: {'skill': 'Flutter'},
      );

      expect(syncManager.mutations.length, equals(1));

      await syncManager.deleteMutation(mut.id);
      expect(syncManager.mutations.isEmpty, isTrue);
      expect(syncManager.pendingCount, equals(0));
    });
  });
}
