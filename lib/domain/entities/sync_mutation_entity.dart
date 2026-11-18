import 'dart:convert';

import 'package:flutter/material.dart';

enum SyncActionType {
  likePost,
  addComment,
  applyJob,
  bookmarkJob,
  endorseSkill,
  custom;

  String get label {
    switch (this) {
      case SyncActionType.likePost:
        return 'Like Post';
      case SyncActionType.addComment:
        return 'Post Comment';
      case SyncActionType.applyJob:
        return 'Job Application';
      case SyncActionType.bookmarkJob:
        return 'Bookmark Job';
      case SyncActionType.endorseSkill:
        return 'Skill Endorsement';
      case SyncActionType.custom:
        return 'Data Mutation';
    }
  }

  IconData get icon {
    switch (this) {
      case SyncActionType.likePost:
        return Icons.thumb_up_alt_outlined;
      case SyncActionType.addComment:
        return Icons.chat_bubble_outline_rounded;
      case SyncActionType.applyJob:
        return Icons.send_rounded;
      case SyncActionType.bookmarkJob:
        return Icons.bookmark_border_rounded;
      case SyncActionType.endorseSkill:
        return Icons.verified_outlined;
      case SyncActionType.custom:
        return Icons.sync_rounded;
    }
  }

  static SyncActionType fromString(String value) {
    for (final type in SyncActionType.values) {
      if (type.name.toLowerCase() == value.toLowerCase().trim()) {
        return type;
      }
    }
    return SyncActionType.custom;
  }
}

enum SyncStatus {
  pending,
  syncing,
  completed,
  failed;

  String get label {
    switch (this) {
      case SyncStatus.pending:
        return 'Pending';
      case SyncStatus.syncing:
        return 'Syncing';
      case SyncStatus.completed:
        return 'Synced';
      case SyncStatus.failed:
        return 'Failed';
    }
  }

  IconData get icon {
    switch (this) {
      case SyncStatus.pending:
        return Icons.schedule_rounded;
      case SyncStatus.syncing:
        return Icons.sync_rounded;
      case SyncStatus.completed:
        return Icons.check_circle_outline_rounded;
      case SyncStatus.failed:
        return Icons.error_outline_rounded;
    }
  }

  static SyncStatus fromString(String value) {
    for (final status in SyncStatus.values) {
      if (status.name.toLowerCase() == value.toLowerCase().trim()) {
        return status;
      }
    }
    return SyncStatus.pending;
  }
}

class SyncMutationEntity {
  final String id;
  final SyncActionType actionType;
  final Map<String, dynamic> payload;
  final SyncStatus status;
  final int retryCount;
  final DateTime createdAt;
  final String? errorMessage;

  const SyncMutationEntity({
    required this.id,
    required this.actionType,
    required this.payload,
    this.status = SyncStatus.pending,
    this.retryCount = 0,
    required this.createdAt,
    this.errorMessage,
  });

  bool get isPending => status == SyncStatus.pending;
  bool get isSyncing => status == SyncStatus.syncing;
  bool get isCompleted => status == SyncStatus.completed;
  bool get isFailed => status == SyncStatus.failed;

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  SyncMutationEntity copyWith({
    String? id,
    SyncActionType? actionType,
    Map<String, dynamic>? payload,
    SyncStatus? status,
    int? retryCount,
    DateTime? createdAt,
    String? errorMessage,
  }) {
    return SyncMutationEntity(
      id: id ?? this.id,
      actionType: actionType ?? this.actionType,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action_type': actionType.name,
      'payload': jsonEncode(payload),
      'status': status.name,
      'retry_count': retryCount,
      'created_at': createdAt.toIso8601String(),
      'error_message': errorMessage,
    };
  }

  factory SyncMutationEntity.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> parsedPayload = {};
    final rawPayload = map['payload'];
    if (rawPayload is String && rawPayload.isNotEmpty) {
      try {
        parsedPayload = jsonDecode(rawPayload) as Map<String, dynamic>;
      } catch (_) {
        parsedPayload = {};
      }
    } else if (rawPayload is Map<String, dynamic>) {
      parsedPayload = rawPayload;
    }

    final createdAtStr =
        map['created_at'] as String? ?? DateTime.now().toIso8601String();

    return SyncMutationEntity(
      id: map['id'] as String? ?? '',
      actionType: SyncActionType.fromString(
        map['action_type'] as String? ?? 'custom',
      ),
      payload: parsedPayload,
      status: SyncStatus.fromString(map['status'] as String? ?? 'pending'),
      retryCount: (map['retry_count'] as int?) ?? 0,
      createdAt: DateTime.tryParse(createdAtStr) ?? DateTime.now(),
      errorMessage: map['error_message'] as String?,
    );
  }
}
