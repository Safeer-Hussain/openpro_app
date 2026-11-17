import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/asset_paths.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../domain/entities/app_notification_entity.dart';
import '../viewmodels/notifications_viewmodel.dart';

class NotificationsCenterView extends StatefulWidget {
  const NotificationsCenterView({super.key});

  @override
  State<NotificationsCenterView> createState() =>
      _NotificationsCenterViewState();
}

class _NotificationsCenterViewState extends State<NotificationsCenterView> {
  String? _selectedNotificationId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: isLandscape ? 40 : 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Consumer<NotificationsViewModel>(
          builder: (context, vm, _) {
            final unread = vm.unreadCount;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Notification Center',
                  style: TextStyle(
                    fontSize: isLandscape ? 14 : 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                if (!isLandscape)
                  Text(
                    unread > 0
                        ? '$unread unread notifications'
                        : 'All notifications caught up',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: unread > 0
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            );
          },
        ),
        actions: [
          Consumer<NotificationsViewModel>(
            builder: (context, vm, _) {
              final hasUnread = vm.unreadCount > 0;
              return TextButton.icon(
                key: const Key('mark_all_read_button'),
                icon: Icon(
                  Icons.done_all_rounded,
                  size: 18,
                  color: hasUnread
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                label: Text(
                  'Mark all read',
                  style: TextStyle(
                    fontSize: isLandscape ? 11 : 12,
                    fontWeight: FontWeight.w700,
                    color: hasUnread
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                ),
                onPressed: hasUnread
                    ? () async {
                        await vm.markAllAsRead();
                        if (context.mounted) {
                          AppFeedback.showSuccess(
                            context,
                            'All notifications marked as read',
                          );
                        }
                      }
                    : null,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<NotificationsViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (isLandscape) {
            return _buildLandscapeLayout(context, vm, colorScheme);
          }

          return _buildPortraitLayout(context, vm, colorScheme);
        },
      ),
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    NotificationsViewModel vm,
    ColorScheme colorScheme,
  ) {
    final notifications = vm.filteredNotifications;

    return Column(
      children: [
        _buildCategoryChipsBar(context, vm, colorScheme, isLandscape: false),
        const Divider(height: 1, thickness: 1),
        Expanded(
          child: notifications.isEmpty
              ? _buildEmptyState(context, colorScheme)
              : RefreshIndicator(
                  onRefresh: () => vm.loadNotifications(),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = notifications[index];
                      return _buildNotificationCard(
                        context,
                        item,
                        vm,
                        colorScheme,
                        isSelected: false,
                        isCompact: false,
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    NotificationsViewModel vm,
    ColorScheme colorScheme,
  ) {
    final notifications = vm.filteredNotifications;
    final selectedItem = notifications.firstWhere(
      (n) => n.id == _selectedNotificationId,
      orElse: () => notifications.isNotEmpty
          ? notifications.first
          : AppNotificationEntity(
              id: '',
              userId: '',
              title: '',
              body: '',
              category: NotificationCategory.recruiter,
              timestamp: DateTime.fromMillisecondsSinceEpoch(0),
            ),
    );

    return Row(
      children: [
        // Left Master Pane: Filter and Notification List
        SizedBox(
          width: 320,
          child: Column(
            children: [
              _buildCategoryChipsBar(
                context,
                vm,
                colorScheme,
                isLandscape: true,
              ),
              const Divider(height: 1, thickness: 1),
              Expanded(
                child: notifications.isEmpty
                    ? _buildEmptyState(context, colorScheme)
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        itemCount: notifications.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final item = notifications[index];
                          final isSelected = item.id == selectedItem.id;
                          return _buildNotificationCard(
                            context,
                            item,
                            vm,
                            colorScheme,
                            isSelected: isSelected,
                            isCompact: true,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1, thickness: 1),
        // Right Detail Pane
        Expanded(
          child: notifications.isEmpty
              ? Center(
                  child: Text(
                    'Select a notification to view details',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                )
              : _buildDetailPane(context, selectedItem, vm, colorScheme),
        ),
      ],
    );
  }

  Widget _buildCategoryChipsBar(
    BuildContext context,
    NotificationsViewModel vm,
    ColorScheme colorScheme, {
    required bool isLandscape,
  }) {
    final categories = <NotificationCategory?>[
      null, // All
      NotificationCategory.recruiter,
      NotificationCategory.job,
      NotificationCategory.community,
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: isLandscape ? 4 : 8,
      ),
      color: colorScheme.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: categories.map((category) {
            final isSelected = vm.selectedCategory == category;
            final label = category == null ? 'All' : category.label;
            final count = vm.unreadCountForCategory(category);

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                key: Key('chip_${category == null ? 'all' : category.name}'),
                selected: isSelected,
                avatar: Icon(
                  category == null ? Icons.inbox_outlined : category.icon,
                  size: 14,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.onPrimary.withValues(alpha: 0.25)
                              : colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                backgroundColor: colorScheme.surfaceContainerHighest,
                selectedColor: colorScheme.primary,
                showCheckmark: false,
                padding: EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: isLandscape ? 2 : 4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                onSelected: (_) {
                  vm.setCategory(category);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    AppNotificationEntity item,
    NotificationsViewModel vm,
    ColorScheme colorScheme, {
    required bool isSelected,
    required bool isCompact,
  }) {
    return Dismissible(
      key: Key('dismissible_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Dismiss',
              style: TextStyle(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.delete_outline_rounded,
              color: colorScheme.onErrorContainer,
              size: 20,
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        vm.deleteNotification(item.id);
        AppFeedback.showInfo(context, 'Notification dismissed');
      },
      child: Material(
        color: isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.4)
            : item.isRead
            ? colorScheme.surfaceContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() => _selectedNotificationId = item.id);
            if (!item.isRead) {
              vm.markAsRead(item.id);
            }
            if (!isCompact) {
              _showNotificationDetailModal(context, item, vm, colorScheme);
            }
          },
          child: Container(
            padding: EdgeInsets.all(isCompact ? 10 : 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : item.isRead
                    ? colorScheme.outlineVariant.withValues(alpha: 0.3)
                    : colorScheme.primary.withValues(alpha: 0.4),
                width: isSelected || !item.isRead ? 1.5 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Unread Dot or Category Icon
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      width: isCompact ? 34 : 40,
                      height: isCompact ? 34 : 40,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(
                          item.category,
                          colorScheme,
                        ).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item.category.icon,
                        size: isCompact ? 18 : 22,
                        color: _getCategoryColor(item.category, colorScheme),
                      ),
                    ),
                    if (!item.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.surface,
                            width: 1.5,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                // Text details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isCompact ? 12 : 13,
                                fontWeight: item.isRead
                                    ? FontWeight.w600
                                    : FontWeight.w800,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item.timeAgo,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.body,
                        maxLines: isCompact ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isCompact ? 11 : 12,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Badges row
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.category.label,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (item.company != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.company!,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          if (item.matchScore != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 10,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${item.matchScore}% Match',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailPane(
    BuildContext context,
    AppNotificationEntity item,
    NotificationsViewModel vm,
    ColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _getCategoryColor(
                    item.category,
                    colorScheme,
                  ).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.category.icon,
                  size: 24,
                  color: _getCategoryColor(item.category, colorScheme),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.category.label} • ${item.timeAgo}',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              item.body,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ),
          if (item.company != null || item.matchScore != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      item.avatarUrl ?? AssetPaths.cloudscaleLogo,
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.business_rounded,
                        size: 24,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.company ?? 'Partner Organization',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (item.matchScore != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${item.matchScore}% Match',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('View Associated Target'),
                  onPressed: () {
                    AppFeedback.showSuccess(
                      context,
                      'Opening ${item.category.label} target reference...',
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: 'Delete Notification',
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                onPressed: () {
                  vm.deleteNotification(item.id);
                  AppFeedback.showInfo(context, 'Notification deleted');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNotificationDetailModal(
    BuildContext context,
    AppNotificationEntity item,
    NotificationsViewModel vm,
    ColorScheme colorScheme,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(
                          item.category,
                          colorScheme,
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item.category.icon,
                        size: 24,
                        color: _getCategoryColor(item.category, colorScheme),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.category.label} • ${item.timeAgo}',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.body,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                ),
                if (item.company != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.business_rounded,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.company!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      if (item.matchScore != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${item.matchScore}% Match',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: const Text('View Target'),
                        onPressed: () {
                          Navigator.pop(bottomSheetContext);
                          AppFeedback.showSuccess(
                            context,
                            'Navigating to ${item.category.label} details...',
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: const Text('Delete'),
                      onPressed: () {
                        Navigator.pop(bottomSheetContext);
                        vm.deleteNotification(item.id);
                        AppFeedback.showInfo(context, 'Notification deleted');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 32,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Notifications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'You are all caught up in this category.',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(NotificationCategory category, ColorScheme scheme) {
    switch (category) {
      case NotificationCategory.recruiter:
        return scheme.primary;
      case NotificationCategory.job:
        return scheme.tertiary;
      case NotificationCategory.community:
        return scheme.secondary;
    }
  }
}
