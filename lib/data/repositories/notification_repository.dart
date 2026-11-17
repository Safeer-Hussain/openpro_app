import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_tables.dart';
import '../../domain/entities/app_notification_entity.dart';
import '../../domain/repositories/notification_repository_interface.dart';

class NotificationRepository implements NotificationRepositoryInterface {
  final AppDatabase database;

  NotificationRepository({required this.database});

  @override
  Future<List<AppNotificationEntity>> getNotifications({
    NotificationCategory? category,
    String? userId = AppConstants.defaultUserId,
  }) async {
    final db = await database.database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (userId != null && userId.isNotEmpty) {
      whereClauses.add('user_id = ?');
      whereArgs.add(userId);
    }

    if (category != null) {
      whereClauses.add('category = ?');
      whereArgs.add(category.name);
    }

    final where = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final results = await db.query(
      DatabaseTables.notifications,
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
    );

    return results.map((map) => AppNotificationEntity.fromMap(map)).toList();
  }

  @override
  Future<int> getUnreadCount({
    String? userId = AppConstants.defaultUserId,
  }) async {
    final db = await database.database;
    final whereClauses = ['is_read = 0'];
    final whereArgs = <dynamic>[];

    if (userId != null && userId.isNotEmpty) {
      whereClauses.add('user_id = ?');
      whereArgs.add(userId);
    }

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseTables.notifications} WHERE ${whereClauses.join(' AND ')}',
      whereArgs,
    );

    if (result.isNotEmpty) {
      return (result.first['count'] as int?) ?? 0;
    }
    return 0;
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    final db = await database.database;
    await db.update(
      DatabaseTables.notifications,
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  @override
  Future<void> markAllAsRead({
    String? userId = AppConstants.defaultUserId,
  }) async {
    final db = await database.database;
    if (userId != null && userId.isNotEmpty) {
      await db.update(
        DatabaseTables.notifications,
        {'is_read': 1},
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    } else {
      await db.update(DatabaseTables.notifications, {'is_read': 1});
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    final db = await database.database;
    await db.delete(
      DatabaseTables.notifications,
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  @override
  Future<AppNotificationEntity> addNotification(
    AppNotificationEntity notification,
  ) async {
    final db = await database.database;
    await db.insert(
      DatabaseTables.notifications,
      notification.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return notification;
  }
}
