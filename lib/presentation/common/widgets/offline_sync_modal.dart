import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/sync_manager.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../domain/entities/sync_mutation_entity.dart';

class OfflineSyncModal extends StatelessWidget {
  const OfflineSyncModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const OfflineSyncModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final maxModalHeight = isLandscape
        ? MediaQuery.of(context).size.height * 0.95
        : MediaQuery.of(context).size.height * 0.75;

    return Container(
      constraints: BoxConstraints(maxHeight: maxModalHeight),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Consumer<SyncManager>(
          builder: (context, syncManager, _) {
            final mutations = syncManager.mutations;
            final isOnline = syncManager.isOnline;
            final isSyncing = syncManager.isSyncing;
            final pendingCount = syncManager.pendingCount;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.sync_alt_rounded,
                          color: colorScheme.onPrimaryContainer,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Offline Sync Engine',
                              style: TextStyle(
                                fontSize: isLandscape ? 14 : 16,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isOnline
                                        ? colorScheme.tertiary
                                        : colorScheme.error,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isOnline
                                      ? 'Online • Cloud Sync Active'
                                      : 'Offline • Local SQLite Queue',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (pendingCount > 0 && isOnline)
                        FilledButton.tonalIcon(
                          key: const Key('sync_now_button'),
                          icon: isSyncing
                              ? SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                )
                              : const Icon(Icons.sync_rounded, size: 16),
                          label: Text(
                            isSyncing ? 'Syncing...' : 'Sync Now',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onPressed: isSyncing
                              ? null
                              : () async {
                                  await syncManager.processQueue();
                                  if (context.mounted) {
                                    AppFeedback.showSuccess(
                                      context,
                                      'Mutations synced successfully',
                                    );
                                  }
                                },
                        ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Queue items list
                Expanded(
                  child: mutations.isEmpty
                      ? _buildEmptyQueue(context, colorScheme)
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          itemCount: mutations.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = mutations[index];
                            return _buildMutationCard(
                              context,
                              item,
                              syncManager,
                              colorScheme,
                            );
                          },
                        ),
                ),
                // Footer actions
                if (mutations.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                      border: Border(
                        top: BorderSide(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$pendingCount pending operations',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Row(
                          children: [
                            if (mutations.any((m) => m.isFailed))
                              TextButton.icon(
                                key: const Key('retry_failed_button'),
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 16,
                                ),
                                label: const Text(
                                  'Retry Failed',
                                  style: TextStyle(fontSize: 12),
                                ),
                                onPressed: () async {
                                  await syncManager.retryFailed();
                                  if (context.mounted) {
                                    AppFeedback.showInfo(
                                      context,
                                      'Retrying pending mutations...',
                                    );
                                  }
                                },
                              ),
                            if (mutations.any((m) => m.isCompleted))
                              TextButton.icon(
                                key: const Key('clear_synced_button'),
                                icon: const Icon(
                                  Icons.cleaning_services_rounded,
                                  size: 16,
                                ),
                                label: const Text(
                                  'Clear Synced',
                                  style: TextStyle(fontSize: 12),
                                ),
                                onPressed: () async {
                                  await syncManager.clearCompleted();
                                  if (context.mounted) {
                                    AppFeedback.showSuccess(
                                      context,
                                      'Cleared completed sync records',
                                    );
                                  }
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyQueue(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_done_outlined,
                size: 28,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Mutation Queue Empty',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'All offline actions are synchronized with the central database.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMutationCard(
    BuildContext context,
    SyncMutationEntity item,
    SyncManager syncManager,
    ColorScheme colorScheme,
  ) {
    final statusColor = _getStatusColor(item.status, colorScheme);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.actionType.icon, size: 18, color: statusColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        item.actionType.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.status.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _formatPayloadSummary(item),
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.errorMessage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Error: ${item.errorMessage}',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${item.timeAgo} • Retries: ${item.retryCount}',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            tooltip: 'Remove',
            onPressed: () {
              syncManager.deleteMutation(item.id);
              AppFeedback.showInfo(context, 'Mutation removed from queue');
            },
          ),
        ],
      ),
    );
  }

  String _formatPayloadSummary(SyncMutationEntity item) {
    if (item.payload.isEmpty) return 'No payload parameters';
    final entries = item.payload.entries
        .take(3)
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');
    return entries;
  }

  Color _getStatusColor(SyncStatus status, ColorScheme colorScheme) {
    switch (status) {
      case SyncStatus.pending:
        return colorScheme.primary;
      case SyncStatus.syncing:
        return colorScheme.tertiary;
      case SyncStatus.completed:
        return colorScheme.secondary;
      case SyncStatus.failed:
        return colorScheme.error;
    }
  }
}
