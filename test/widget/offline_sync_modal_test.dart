import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_pro/core/network/sync_manager.dart';
import 'package:open_pro/core/theme/app_theme.dart';
import 'package:open_pro/domain/entities/sync_mutation_entity.dart';
import 'package:open_pro/presentation/common/widgets/offline_sync_modal.dart';
import 'package:provider/provider.dart';

import '../helpers/mock_repositories.dart';

void main() {
  late MockOfflineSyncQueue mockQueue;
  late SyncManager syncManager;

  setUp(() {
    mockQueue = MockOfflineSyncQueue();
    syncManager = SyncManager(queue: mockQueue);
  });

  Widget createWidgetUnderTest() {
    return ChangeNotifierProvider<SyncManager>.value(
      value: syncManager,
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                key: const Key('open_modal_btn'),
                onPressed: () => OfflineSyncModal.show(context),
                child: const Text('Open Modal'),
              );
            },
          ),
        ),
      ),
    );
  }

  group('OfflineSyncModal Widget Tests', () {
    testWidgets('Renders empty state when queue has no items', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open_modal_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Offline Sync Engine'), findsOneWidget);
      expect(find.text('Mutation Queue Empty'), findsOneWidget);
      expect(
        find.text(
          'All offline actions are synchronized with the central database.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Renders mutation cards, status badges, and actions', (
      tester,
    ) async {
      syncManager.setOnline(false);
      await syncManager.enqueue(
        actionType: SyncActionType.likePost,
        payload: {'postId': 'p100'},
      );
      await syncManager.enqueue(
        actionType: SyncActionType.addComment,
        payload: {'postId': 'p100', 'text': 'Great architecture'},
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open_modal_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Offline Sync Engine'), findsOneWidget);
      expect(find.text('Like Post'), findsOneWidget);
      expect(find.text('Post Comment'), findsOneWidget);
      expect(find.text('Pending'), findsWidgets);
      expect(find.text('2 pending operations'), findsOneWidget);

      // Now set online which auto-triggers sequential processing
      syncManager.setOnline(true);
      await tester.pumpAndSettle();

      // Automatically synced on connection restore
      expect(syncManager.pendingCount, equals(0));
      expect(find.text('0 pending operations'), findsOneWidget);
    });

    testWidgets(
      'Landscape 800x360 viewport safety renders with zero overflow',
      (tester) async {
        tester.view.physicalSize = const Size(800, 360);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await syncManager.enqueue(
          actionType: SyncActionType.applyJob,
          payload: {'jobId': 'job_1'},
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('open_modal_btn')));
        await tester.pumpAndSettle();

        expect(find.text('Offline Sync Engine'), findsOneWidget);
        expect(find.text('Job Application'), findsOneWidget);

        // Verify no RenderFlex overflow exceptions occurred
        expect(tester.takeException(), isNull);
      },
    );
  });
}
