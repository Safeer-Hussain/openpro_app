import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/app_notification_entity.dart';
import '../../../domain/repositories/notification_repository_interface.dart';

class NotificationsViewModel extends ChangeNotifier {
  final NotificationRepositoryInterface repository;

  NotificationsViewModel({required this.repository}) {
    loadNotifications();
  }

  List<AppNotificationEntity> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  NotificationCategory? _selectedCategory;
  int _unreadCount = 0;

  List<AppNotificationEntity> get notifications =>
      List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  NotificationCategory? get selectedCategory => _selectedCategory;
  int get unreadCount => _unreadCount;

  List<AppNotificationEntity> get filteredNotifications {
    if (_selectedCategory == null) return _notifications;
    return _notifications
        .where((n) => n.category == _selectedCategory)
        .toList();
  }

  int get unreadCountForSelectedCategory {
    return filteredNotifications.where((n) => !n.isRead).length;
  }

  int unreadCountForCategory(NotificationCategory? category) {
    if (category == null) return _unreadCount;
    return _notifications
        .where((n) => n.category == category && !n.isRead)
        .length;
  }

  Future<void> loadNotifications({
    String? userId = AppConstants.defaultUserId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notifications = await repository.getNotifications(
        category: null,
        userId: userId,
      );
      _unreadCount = await repository.getUnreadCount(userId: userId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCategory(NotificationCategory? category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      if (_unreadCount > 0) {
        _unreadCount--;
      }
      notifyListeners();

      try {
        await repository.markAsRead(id);
      } catch (e) {
        _notifications[index] = _notifications[index].copyWith(isRead: false);
        _unreadCount++;
        notifyListeners();
      }
    }
  }

  Future<void> markAllAsRead({
    String? userId = AppConstants.defaultUserId,
  }) async {
    final previousNotifications = List<AppNotificationEntity>.from(
      _notifications,
    );
    final previousUnread = _unreadCount;

    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    _unreadCount = 0;
    notifyListeners();

    try {
      await repository.markAllAsRead(userId: userId);
    } catch (e) {
      _notifications = previousNotifications;
      _unreadCount = previousUnread;
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final removed = _notifications.removeAt(index);
      if (!removed.isRead && _unreadCount > 0) {
        _unreadCount--;
      }
      notifyListeners();

      try {
        await repository.deleteNotification(id);
      } catch (e) {
        _notifications.insert(index, removed);
        if (!removed.isRead) _unreadCount++;
        notifyListeners();
      }
    }
  }

  Future<void> addNotification(AppNotificationEntity notification) async {
    _notifications.insert(0, notification);
    if (!notification.isRead) {
      _unreadCount++;
    }
    notifyListeners();

    try {
      await repository.addNotification(notification);
    } catch (e) {
      // Optimistic state remains intact
    }
  }
}
