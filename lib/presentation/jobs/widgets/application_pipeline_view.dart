import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/app_feedback.dart';
import '../../../domain/entities/job_application_entity.dart';
import '../viewmodels/application_pipeline_viewmodel.dart';

class ApplicationPipelineView extends StatelessWidget {
  const ApplicationPipelineView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    return Consumer<ApplicationPipelineViewModel>(
      builder: (context, viewModel, _) {
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: isLandscape ? 40 : 56,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Application Pipeline',
                  style: TextStyle(
                    fontSize: isLandscape ? 15 : 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  '${viewModel.activeApplicationsCount} Active Applications across hiring stages',
                  style: TextStyle(
                    fontSize: isLandscape ? 10 : 11,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Refresh Pipeline',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => viewModel.loadApplications(),
              ),
            ],
          ),
          body: viewModel.isLoading
              ? Center(
                  child: CircularProgressIndicator(color: colorScheme.primary),
                )
              : _buildKanbanBoard(context, viewModel, colorScheme, isLandscape),
        );
      },
    );
  }

  Widget _buildKanbanBoard(
    BuildContext context,
    ApplicationPipelineViewModel viewModel,
    ColorScheme colorScheme,
    bool isLandscape,
  ) {
    const stages = ApplicationStage.values;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: isLandscape ? 16 : 12,
        vertical: isLandscape ? 6 : 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: stages.map((stage) {
          final stageApps = viewModel.applicationsForStage(stage);
          return _buildStageColumn(
            context: context,
            stage: stage,
            applications: stageApps,
            viewModel: viewModel,
            colorScheme: colorScheme,
            isLandscape: isLandscape,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStageColumn({
    required BuildContext context,
    required ApplicationStage stage,
    required List<JobApplicationEntity> applications,
    required ApplicationPipelineViewModel viewModel,
    required ColorScheme colorScheme,
    required bool isLandscape,
  }) {
    final columnWidth = isLandscape ? 280.0 : 290.0;

    return DragTarget<JobApplicationEntity>(
      onWillAcceptWithDetails: (details) => details.data.stage != stage,
      onAcceptWithDetails: (details) async {
        final app = details.data;
        final success = await viewModel.moveApplicationToStage(app.id, stage);
        if (context.mounted && success) {
          AppFeedback.showSuccess(
            context,
            'Moved ${app.jobTitle} to ${stage.label}',
          );
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isDropTarget = candidateData.isNotEmpty;

        return Container(
          width: columnWidth,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: isDropTarget
                ? colorScheme.primaryContainer.withValues(alpha: 0.25)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDropTarget
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.7),
              width: isDropTarget ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Column Header
              _buildColumnHeader(stage, applications.length, colorScheme),

              // Applications List
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: isLandscape ? 240 : 540),
                child: applications.isEmpty
                    ? _buildEmptyColumnPlaceholder(stage, colorScheme)
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.all(10),
                        itemCount: applications.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final app = applications[index];
                          return _buildApplicationCard(
                            context: context,
                            application: app,
                            viewModel: viewModel,
                            colorScheme: colorScheme,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildColumnHeader(
    ApplicationStage stage,
    int count,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Icon(stage.icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              stage.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyColumnPlaceholder(
    ApplicationStage stage,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              stage.icon,
              size: 28,
              color: colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'No applications in ${stage.label}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationCard({
    required BuildContext context,
    required JobApplicationEntity application,
    required ApplicationPipelineViewModel viewModel,
    required ColorScheme colorScheme,
  }) {
    final cardContent = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Logo, Job Title, Company
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.surfaceContainerHighest,
                backgroundImage: AssetImage(application.companyLogo),
                onBackgroundImageError: (error, stackTrace) {},
                child: application.companyLogo.isEmpty
                    ? Icon(
                        Icons.business_rounded,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.jobTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${application.company} • ${application.location}',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Metadata badges row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    application.salaryRange,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 11,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    application.elapsedLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Stage Indicator Progress Bar
          _buildStageProgressBar(application.stage, colorScheme),
          const SizedBox(height: 10),

          // Interactive Stage Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (application.canRegress)
                IconButton.outlined(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.arrow_back_rounded, size: 14),
                  tooltip: 'Move to ${application.stage.previousStage?.label}',
                  onPressed: () async {
                    final prev = application.stage.previousStage;
                    if (prev != null) {
                      final ok = await viewModel.regressStage(application.id);
                      if (context.mounted && ok) {
                        AppFeedback.showSuccess(
                          context,
                          'Moved to ${prev.label}',
                        );
                      }
                    }
                  },
                )
              else
                const SizedBox(width: 24),

              if (application.stage != ApplicationStage.archived)
                IconButton.outlined(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.archive_outlined, size: 14),
                  tooltip: 'Archive application',
                  onPressed: () async {
                    final ok = await viewModel.archiveApplication(
                      application.id,
                    );
                    if (context.mounted && ok) {
                      AppFeedback.showInfo(
                        context,
                        'Archived ${application.jobTitle}',
                      );
                    }
                  },
                ),

              if (application.canAdvance)
                Flexible(
                  child: FilledButton.tonalIcon(
                    onPressed: () async {
                      final next = application.stage.nextStage;
                      if (next != null) {
                        final ok = await viewModel.advanceStage(application.id);
                        if (context.mounted && ok) {
                          AppFeedback.showSuccess(
                            context,
                            'Advanced to ${next.label}',
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.arrow_forward_rounded, size: 12),
                    label: Text(
                      application.stage.nextStage!.label,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Final Stage',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    return LongPressDraggable<JobApplicationEntity>(
      data: application,
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
        child: SizedBox(width: 260, child: cardContent),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: cardContent),
      child: cardContent,
    );
  }

  Widget _buildStageProgressBar(
    ApplicationStage stage,
    ColorScheme colorScheme,
  ) {
    const totalSteps = 4; // Excluding archived
    final currentStep = stage == ApplicationStage.archived
        ? totalSteps
        : stage.index;

    return Row(
      children: List.generate(totalSteps, (index) {
        final isFilled = index <= currentStep;
        return Expanded(
          child: Container(
            height: 3,
            margin: EdgeInsets.only(right: index < totalSteps - 1 ? 3 : 0),
            decoration: BoxDecoration(
              color: isFilled
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
