import '../entities/app_notification_entity.dart';

abstract class NotificationRepositoryInterface {
  Future<List<AppNotificationEntity>> getNotifications({
    NotificationCategory? category,
    String? userId,
  });

  Future<int> getUnreadCount({String? userId});

  Future<void> markAsRead(String notificationId);

  Future<void> markAllAsRead({String? userId});

  Future<void> deleteNotification(String notificationId);

  Future<AppNotificationEntity> addNotification(
    AppNotificationEntity notification,
  );
}
