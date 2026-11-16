import 'package:flutter_test/flutter_test.dart';
import 'package:open_pro/domain/entities/job_application_entity.dart';
import 'package:open_pro/presentation/jobs/viewmodels/application_pipeline_viewmodel.dart';

import '../helpers/mock_repositories.dart';

void main() {
  group('JobApplicationEntity and ApplicationStage Tests', () {
    test('ApplicationStage fromString parses aliases and standard names accurately', () {
      expect(
        ApplicationStage.fromString('applied'),
        equals(ApplicationStage.applied),
      );
      expect(
        ApplicationStage.fromString('underReview'),
        equals(ApplicationStage.underReview),
      );
      expect(
        ApplicationStage.fromString('under_review'),
        equals(ApplicationStage.underReview),
      );
      expect(
        ApplicationStage.fromString('technicalScreening'),
        equals(ApplicationStage.technicalScreening),
      );
      expect(
        ApplicationStage.fromString('technical_screening'),
        equals(ApplicationStage.technicalScreening),
      );
      expect(
        ApplicationStage.fromString('interviewScheduled'),
        equals(ApplicationStage.technicalScreening),
      );
      expect(
        ApplicationStage.fromString('offerReceived'),
        equals(ApplicationStage.offerReceived),
      );
      expect(
        ApplicationStage.fromString('archived'),
        equals(ApplicationStage.archived),
      );
      expect(
        ApplicationStage.fromString('unknown_value'),
        equals(ApplicationStage.applied),
      );
    });

    test('Stage progression and regression logic adheres to pipeline flow', () {
      expect(
        ApplicationStage.applied.nextStage,
        equals(ApplicationStage.underReview),
      );
      expect(
        ApplicationStage.underReview.nextStage,
        equals(ApplicationStage.technicalScreening),
      );
      expect(
        ApplicationStage.technicalScreening.nextStage,
        equals(ApplicationStage.offerReceived),
      );
      expect(
        ApplicationStage.offerReceived.nextStage,
        equals(ApplicationStage.archived),
      );
      expect(ApplicationStage.archived.nextStage, isNull);

      expect(ApplicationStage.applied.previousStage, isNull);
      expect(
        ApplicationStage.underReview.previousStage,
        equals(ApplicationStage.applied),
      );
      expect(
        ApplicationStage.technicalScreening.previousStage,
        equals(ApplicationStage.underReview),
      );
      expect(
        ApplicationStage.offerReceived.previousStage,
        equals(ApplicationStage.technicalScreening),
      );
      expect(
        ApplicationStage.archived.previousStage,
        equals(ApplicationStage.offerReceived),
      );
    });

    test('JobApplicationEntity serialization and elapsedDays calculation', () {
      final now = DateTime.now();
      final entity = JobApplicationEntity(
        id: 'app_test_1',
        jobId: 'job_test_1',
        userId: 'user_safeer',
        jobTitle: 'Principal Flutter Architect',
        company: 'CloudScale Global',
        companyLogo: 'assets/images/cloudscale.png',
        salaryRange: '\$200k - \$250k',
        location: 'Remote',
        stage: ApplicationStage.underReview,
        appliedAt: now.subtract(const Duration(days: 4)),
        updatedAt: now.subtract(const Duration(days: 1)),
      );

      expect(entity.elapsedDays, equals(4));
      expect(entity.elapsedLabel, equals('4 days ago'));
      expect(entity.canAdvance, isTrue);
      expect(entity.canRegress, isTrue);

      final map = entity.toMap();
      expect(map['id'], equals('app_test_1'));
      expect(map['status'], equals('underReview'));

      final fromMap = JobApplicationEntity.fromMap(map);
      expect(fromMap.id, equals(entity.id));
      expect(fromMap.stage, equals(ApplicationStage.underReview));
      expect(fromMap.jobTitle, equals('Principal Flutter Architect'));
    });
  });

  group('ApplicationPipelineViewModel Unit Tests', () {
    late MockApplicationRepository mockRepo;
    late ApplicationPipelineViewModel viewModel;

    setUp(() {
      mockRepo = MockApplicationRepository();
      viewModel = ApplicationPipelineViewModel(repository: mockRepo);
    });

    test(
      'Initializes and loads mock applications into stage buckets',
      () async {
        await viewModel.loadApplications();

        expect(viewModel.totalApplicationsCount, equals(4));
        expect(
          viewModel.activeApplicationsCount,
          equals(4),
        ); // all 4 are non-archived in mock

        expect(viewModel.countForStage(ApplicationStage.applied), equals(1));
        expect(
          viewModel.countForStage(ApplicationStage.underReview),
          equals(1),
        );
        expect(
          viewModel.countForStage(ApplicationStage.technicalScreening),
          equals(1),
        );
        expect(
          viewModel.countForStage(ApplicationStage.offerReceived),
          equals(1),
        );
        expect(viewModel.countForStage(ApplicationStage.archived), equals(0));
      },
    );

    test('advanceStage progresses application forward across stages', () async {
      await viewModel.loadApplications();

      // app_104 is currently in 'applied'
      final app = viewModel.findApplication('app_104');
      expect(app, isNotNull);
      expect(app!.stage, equals(ApplicationStage.applied));

      // Advance from applied -> underReview
      final ok1 = await viewModel.advanceStage('app_104');
      expect(ok1, isTrue);
      expect(
        viewModel.findApplication('app_104')!.stage,
        equals(ApplicationStage.underReview),
      );

      // Advance from underReview -> technicalScreening
      final ok2 = await viewModel.advanceStage('app_104');
      expect(ok2, isTrue);
      expect(
        viewModel.findApplication('app_104')!.stage,
        equals(ApplicationStage.technicalScreening),
      );

      // Advance from technicalScreening -> offerReceived
      final ok3 = await viewModel.advanceStage('app_104');
      expect(ok3, isTrue);
      expect(
        viewModel.findApplication('app_104')!.stage,
        equals(ApplicationStage.offerReceived),
      );

      // Advance from offerReceived -> archived
      final ok4 = await viewModel.advanceStage('app_104');
      expect(ok4, isTrue);
      expect(
        viewModel.findApplication('app_104')!.stage,
        equals(ApplicationStage.archived),
      );

      // Cannot advance past archived
      final ok5 = await viewModel.advanceStage('app_104');
      expect(ok5, isFalse);
      expect(
        viewModel.findApplication('app_104')!.stage,
        equals(ApplicationStage.archived),
      );
    });

    test('regressStage moves application backward across stages', () async {
      await viewModel.loadApplications();

      // app_101 is in 'technicalScreening'
      expect(
        viewModel.findApplication('app_101')!.stage,
        equals(ApplicationStage.technicalScreening),
      );

      // Regress technicalScreening -> underReview
      final ok1 = await viewModel.regressStage('app_101');
      expect(ok1, isTrue);
      expect(
        viewModel.findApplication('app_101')!.stage,
        equals(ApplicationStage.underReview),
      );

      // Regress underReview -> applied
      final ok2 = await viewModel.regressStage('app_101');
      expect(ok2, isTrue);
      expect(
        viewModel.findApplication('app_101')!.stage,
        equals(ApplicationStage.applied),
      );

      // Cannot regress past applied
      final ok3 = await viewModel.regressStage('app_101');
      expect(ok3, isFalse);
      expect(
        viewModel.findApplication('app_101')!.stage,
        equals(ApplicationStage.applied),
      );
    });

    test(
      'moveApplicationToStage directly places application in target stage',
      () async {
        await viewModel.loadApplications();

        final ok = await viewModel.moveApplicationToStage(
          'app_104',
          ApplicationStage.offerReceived,
        );
        expect(ok, isTrue);
        expect(
          viewModel.findApplication('app_104')!.stage,
          equals(ApplicationStage.offerReceived),
        );
      },
    );

    test(
      'archiveApplication transitions application to archived stage',
      () async {
        await viewModel.loadApplications();

        final ok = await viewModel.archiveApplication('app_102');
        expect(ok, isTrue);
        expect(
          viewModel.findApplication('app_102')!.stage,
          equals(ApplicationStage.archived),
        );
        expect(viewModel.activeApplicationsCount, equals(3));
      },
    );

    test('Filtering by stage updates filteredApplications list', () async {
      await viewModel.loadApplications();

      expect(viewModel.filteredApplications.length, equals(4));

      viewModel.setStageFilter(ApplicationStage.technicalScreening);
      expect(
        viewModel.selectedStageFilter,
        equals(ApplicationStage.technicalScreening),
      );
      expect(viewModel.filteredApplications.length, equals(1));
      expect(viewModel.filteredApplications.first.id, equals('app_101'));

      viewModel.setStageFilter(null);
      expect(viewModel.filteredApplications.length, equals(4));
    });
  });
}
