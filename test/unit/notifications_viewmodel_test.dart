import 'package:flutter_test/flutter_test.dart';
import 'package:open_pro/domain/entities/app_notification_entity.dart';
import 'package:open_pro/presentation/notifications/viewmodels/notifications_viewmodel.dart';

import '../helpers/mock_repositories.dart';

void main() {
  group('AppNotificationEntity Tests', () {
    test('Entity supports copyWith, timeAgo, and serialization parity', () {
      final now = DateTime.now();
      final notification = AppNotificationEntity(
        id: 'notif_test_1',
        userId: 'user_1',
        title: 'Recruiter Outreach',
        body: 'Sarah Vance sent a message.',
        category: NotificationCategory.recruiter,
        company: 'CloudScale Global',
        matchScore: 98,
        isRead: false,
        timestamp: now.subtract(const Duration(minutes: 5)),
      );

      expect(notification.isRead, isFalse);
      expect(notification.category, equals(NotificationCategory.recruiter));
      expect(notification.timeAgo, equals('5m ago'));
      expect(notification.category.label, equals('Recruiter Alerts'));

      final map = notification.toMap();
      expect(map['id'], equals('notif_test_1'));
      expect(map['is_read'], equals(0));
      expect(map['match_score'], equals(98));

      final fromMap = AppNotificationEntity.fromMap(map);
      expect(fromMap.id, equals(notification.id));
      expect(fromMap.title, equals(notification.title));
      expect(fromMap.matchScore, equals(98));
      expect(fromMap.isRead, isFalse);

      final updated = notification.copyWith(isRead: true);
      expect(updated.isRead, isTrue);
      expect(notification.isRead, isFalse); // Immutability verification
    });

    test('timeAgo calculates various durations correctly', () {
      final now = DateTime.now();
      expect(
        AppNotificationEntity(
          id: '1',
          userId: 'u',
          title: 't',
          body: 'b',
          category: NotificationCategory.job,
          timestamp: now.subtract(const Duration(seconds: 15)),
        ).timeAgo,
        equals('Just now'),
      );

      expect(
        AppNotificationEntity(
          id: '2',
          userId: 'u',
          title: 't',
          body: 'b',
          category: NotificationCategory.job,
          timestamp: now.subtract(const Duration(hours: 4)),
        ).timeAgo,
        equals('4h ago'),
      );

      expect(
        AppNotificationEntity(
          id: '3',
          userId: 'u',
          title: 't',
          body: 'b',
          category: NotificationCategory.job,
          timestamp: now.subtract(const Duration(days: 1)),
        ).timeAgo,
        equals('Yesterday'),
      );

      expect(
        AppNotificationEntity(
          id: '4',
          userId: 'u',
          title: 't',
          body: 'b',
          category: NotificationCategory.job,
          timestamp: now.subtract(const Duration(days: 3)),
        ).timeAgo,
        equals('3d ago'),
      );

      expect(
        AppNotificationEntity(
          id: '5',
          userId: 'u',
          title: 't',
          body: 'b',
          category: NotificationCategory.job,
          timestamp: now.subtract(const Duration(days: 14)),
        ).timeAgo,
        equals('2w ago'),
      );
    });

    test('NotificationCategory parses variations safely', () {
      expect(
        NotificationCategory.fromString('recruiter'),
        equals(NotificationCategory.recruiter),
      );
      expect(
        NotificationCategory.fromString('job_alert'),
        equals(NotificationCategory.job),
      );
      expect(
        NotificationCategory.fromString('community_event'),
        equals(NotificationCategory.community),
      );
      expect(
        NotificationCategory.fromString('unknown_type'),
        equals(NotificationCategory.recruiter),
      );
    });
  });

  group('NotificationsViewModel Unit Tests', () {
    late MockNotificationRepository mockRepo;
    late NotificationsViewModel viewModel;

    setUp(() async {
      mockRepo = MockNotificationRepository();
      viewModel = NotificationsViewModel(repository: mockRepo);
      // Wait for initial load
      await Future<void>.delayed(Duration.zero);
    });

    test('Initializes with loaded notifications and accurate unread count', () {
      expect(viewModel.notifications.length, equals(3));
      expect(viewModel.unreadCount, equals(2));
      expect(viewModel.isLoading, isFalse);
    });

    test('Filters by category correctly', () {
      expect(viewModel.filteredNotifications.length, equals(3));

      viewModel.setCategory(NotificationCategory.recruiter);
      expect(
        viewModel.selectedCategory,
        equals(NotificationCategory.recruiter),
      );
      expect(viewModel.filteredNotifications.length, equals(1));
      expect(
        viewModel.filteredNotifications.first.category,
        equals(NotificationCategory.recruiter),
      );

      viewModel.setCategory(NotificationCategory.job);
      expect(viewModel.filteredNotifications.length, equals(1));
      expect(
        viewModel.filteredNotifications.first.category,
        equals(NotificationCategory.job),
      );

      viewModel.setCategory(null); // Back to All
      expect(viewModel.filteredNotifications.length, equals(3));
    });

    test('Counts unread items per category', () {
      expect(viewModel.unreadCountForCategory(null), equals(2));
      expect(
        viewModel.unreadCountForCategory(NotificationCategory.recruiter),
        equals(1),
      );
      expect(
        viewModel.unreadCountForCategory(NotificationCategory.job),
        equals(1),
      );
      expect(
        viewModel.unreadCountForCategory(NotificationCategory.community),
        equals(0),
      );
    });

    test('markAsRead updates item state and decrements unread count', () async {
      expect(viewModel.unreadCount, equals(2));

      await viewModel.markAsRead('mock_notif_1');

      final item = viewModel.notifications.firstWhere(
        (n) => n.id == 'mock_notif_1',
      );
      expect(item.isRead, isTrue);
      expect(viewModel.unreadCount, equals(1));

      // Verifies persistence in mock repo
      final repoCount = await mockRepo.getUnreadCount();
      expect(repoCount, equals(1));
    });

    test('markAllAsRead marks every notification as read', () async {
      expect(viewModel.unreadCount, equals(2));

      await viewModel.markAllAsRead();

      expect(viewModel.unreadCount, equals(0));
      for (final n in viewModel.notifications) {
        expect(n.isRead, isTrue);
      }

      final repoCount = await mockRepo.getUnreadCount();
      expect(repoCount, equals(0));
    });

    test('deleteNotification removes item and adjusts unread count', () async {
      expect(viewModel.notifications.length, equals(3));
      expect(viewModel.unreadCount, equals(2));

      await viewModel.deleteNotification('mock_notif_1');

      expect(viewModel.notifications.length, equals(2));
      expect(viewModel.unreadCount, equals(1));
      expect(
        viewModel.notifications.any((n) => n.id == 'mock_notif_1'),
        isFalse,
      );
    });

    test(
      'addNotification prepends notification and increments unread count',
      () async {
        final newNotif = AppNotificationEntity(
          id: 'new_1',
          userId: 'user_default',
          title: 'New Match Alert',
          body: 'Elena Rostova reached out.',
          category: NotificationCategory.recruiter,
          isRead: false,
          timestamp: DateTime.now(),
        );

        await viewModel.addNotification(newNotif);

        expect(viewModel.notifications.first.id, equals('new_1'));
        expect(viewModel.unreadCount, equals(3));
      },
    );
  });
}
