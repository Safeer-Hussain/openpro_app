import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_pro/core/theme/app_theme.dart';
import 'package:open_pro/presentation/notifications/viewmodels/notifications_viewmodel.dart';
import 'package:open_pro/presentation/notifications/views/notifications_center_view.dart';
import 'package:provider/provider.dart';

import '../helpers/mock_repositories.dart';

void main() {
  late MockNotificationRepository mockRepo;
  late NotificationsViewModel viewModel;

  setUp(() {
    mockRepo = MockNotificationRepository();
    viewModel = NotificationsViewModel(repository: mockRepo);
  });

  Widget createWidgetUnderTest({ThemeMode themeMode = ThemeMode.dark}) {
    return ChangeNotifierProvider<NotificationsViewModel>.value(
      value: viewModel,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: const NotificationsCenterView(),
      ),
    );
  }

  group('NotificationsCenterView Widget Tests', () {
    testWidgets(
      'Renders Notification Center, category chips, and initial cards',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Notification Center'), findsOneWidget);
        expect(find.text('2 unread notifications'), findsOneWidget);
        expect(find.byKey(const Key('mark_all_read_button')), findsOneWidget);

        // Verify Category Filter Chips
        expect(find.byKey(const Key('chip_all')), findsOneWidget);
        expect(find.byKey(const Key('chip_recruiter')), findsOneWidget);
        expect(find.byKey(const Key('chip_job')), findsOneWidget);
        expect(find.byKey(const Key('chip_community')), findsOneWidget);

        // Verify Notification Titles
        expect(find.text('High Compatibility Recruiter View'), findsOneWidget);
        expect(find.text('Application Stage Advanced'), findsOneWidget);
        expect(find.text('Keynote Speaker Invitation'), findsOneWidget);

        // Verify Match Score Badge
        expect(find.text('96% Match'), findsWidgets);
      },
    );

    testWidgets('Filters list when a category chip is tapped', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap Recruiter Alerts chip
      await tester.tap(find.byKey(const Key('chip_recruiter')));
      await tester.pumpAndSettle();

      expect(find.text('High Compatibility Recruiter View'), findsOneWidget);
      expect(find.text('Application Stage Advanced'), findsNothing);
      expect(find.text('Keynote Speaker Invitation'), findsNothing);

      // Tap Community Activity chip
      await tester.ensureVisible(find.byKey(const Key('chip_community')));
      await tester.tap(find.byKey(const Key('chip_community')));
      await tester.pumpAndSettle();

      expect(find.text('Keynote Speaker Invitation'), findsOneWidget);
      expect(find.text('High Compatibility Recruiter View'), findsNothing);

      // Tap All chip to restore
      await tester.ensureVisible(find.byKey(const Key('chip_all')));
      await tester.tap(find.byKey(const Key('chip_all')));
      await tester.pumpAndSettle();

      expect(find.text('High Compatibility Recruiter View'), findsOneWidget);
      expect(find.text('Application Stage Advanced'), findsOneWidget);
      expect(find.text('Keynote Speaker Invitation'), findsOneWidget);
    });

    testWidgets('Tapping unread card marks it as read and opens detail sheet', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(viewModel.unreadCount, equals(2));

      // Tap the first unread notification card
      await tester.tap(find.text('High Compatibility Recruiter View'));
      await tester.pumpAndSettle();

      // Verifies unread count decremented to 1
      expect(viewModel.unreadCount, equals(1));

      // Verifies modal bottom sheet opens with detail and actions
      expect(find.text('View Target'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Tap View Target in modal sheet
      await tester.tap(find.text('View Target'));
      await tester.pumpAndSettle();

      // Modal closed
      expect(find.text('View Target'), findsNothing);
    });

    testWidgets('Mark all read button marks all notifications as read', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(viewModel.unreadCount, equals(2));

      await tester.tap(find.byKey(const Key('mark_all_read_button')));
      await tester.pumpAndSettle();

      expect(viewModel.unreadCount, equals(0));
      expect(find.text('All notifications caught up'), findsOneWidget);
    });

    testWidgets('Swiping card dismisses it from notification list', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(viewModel.notifications.length, equals(3));

      // Dismiss the first card
      await tester.drag(
        find.byKey(const Key('dismissible_mock_notif_1')),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      expect(viewModel.notifications.length, equals(2));
      expect(find.text('High Compatibility Recruiter View'), findsNothing);
    });

    testWidgets('Displays empty state when category has zero notifications', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Create repository with no notifications
      final emptyRepo = MockNotificationRepository(notifications: []);
      final emptyVm = NotificationsViewModel(repository: emptyRepo);

      await tester.pumpWidget(
        ChangeNotifierProvider<NotificationsViewModel>.value(
          value: emptyVm,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const NotificationsCenterView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Notifications'), findsOneWidget);
      expect(
        find.text('You are all caught up in this category.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Landscape 800x360 viewport safety renders two-pane master-detail with zero overflow',
      (tester) async {
        tester.view.physicalSize = const Size(800, 360);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // In landscape, check master list and detail pane rendered side by side
        expect(find.text('Notification Center'), findsOneWidget);
        expect(find.text('High Compatibility Recruiter View'), findsWidgets);

        // Verifies associated target action button in detail pane
        expect(find.text('View Associated Target'), findsOneWidget);

        // Verify no RenderFlex overflow exceptions occurred
        expect(tester.takeException(), isNull);
      },
    );
  });
}
