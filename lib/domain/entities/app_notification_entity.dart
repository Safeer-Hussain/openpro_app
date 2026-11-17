import 'package:flutter/material.dart';

enum NotificationCategory {
  recruiter,
  job,
  community;

  String get label {
    switch (this) {
      case NotificationCategory.recruiter:
        return 'Recruiter Alerts';
      case NotificationCategory.job:
        return 'Job Updates';
      case NotificationCategory.community:
        return 'Community Activity';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationCategory.recruiter:
        return Icons.shield_outlined;
      case NotificationCategory.job:
        return Icons.work_outline_rounded;
      case NotificationCategory.community:
        return Icons.hub_outlined;
    }
  }

  static NotificationCategory fromString(String value) {
    final normalized = value.toLowerCase().trim();
    if (normalized.contains('recruiter') || normalized.contains('recruit')) {
      return NotificationCategory.recruiter;
    }
    if (normalized.contains('job') ||
        normalized.contains('application') ||
        normalized.contains('career')) {
      return NotificationCategory.job;
    }
    if (normalized.contains('community') ||
        normalized.contains('guild') ||
        normalized.contains('event')) {
      return NotificationCategory.community;
    }
    return NotificationCategory.recruiter;
  }
}

class AppNotificationEntity {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationCategory category;
  final String? referenceId;
  final String? company;
  final String? avatarUrl;
  final int? matchScore;
  final bool isRead;
  final DateTime timestamp;

  const AppNotificationEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.category,
    this.referenceId,
    this.company,
    this.avatarUrl,
    this.matchScore,
    this.isRead = false,
    required this.timestamp,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  AppNotificationEntity copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationCategory? category,
    String? referenceId,
    String? company,
    String? avatarUrl,
    int? matchScore,
    bool? isRead,
    DateTime? timestamp,
  }) {
    return AppNotificationEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      referenceId: referenceId ?? this.referenceId,
      company: company ?? this.company,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      matchScore: matchScore ?? this.matchScore,
      isRead: isRead ?? this.isRead,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'category': category.name,
      'reference_id': referenceId,
      'company': company,
      'avatar_url': avatarUrl,
      'match_score': matchScore,
      'is_read': isRead ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AppNotificationEntity.fromMap(Map<String, dynamic> map) {
    final timestampStr =
        map['timestamp'] as String? ?? DateTime.now().toIso8601String();
    final isReadRaw = map['is_read'];
    final isReadBool = isReadRaw is int
        ? isReadRaw == 1
        : (isReadRaw as bool? ?? false);

    return AppNotificationEntity(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      category: NotificationCategory.fromString(
        map['category'] as String? ?? 'recruiter',
      ),
      referenceId: map['reference_id'] as String?,
      company: map['company'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      matchScore: map['match_score'] as int?,
      isRead: isReadBool,
      timestamp: DateTime.tryParse(timestampStr) ?? DateTime.now(),
    );
  }
}
