import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_pro/core/theme/app_theme.dart';
import 'package:open_pro/domain/entities/job_application_entity.dart';
import 'package:open_pro/presentation/jobs/viewmodels/application_pipeline_viewmodel.dart';
import 'package:open_pro/presentation/jobs/widgets/application_pipeline_view.dart';
import 'package:provider/provider.dart';

import '../helpers/mock_repositories.dart';

void main() {
  late MockApplicationRepository mockRepo;
  late ApplicationPipelineViewModel viewModel;

  setUp(() {
    mockRepo = MockApplicationRepository();
    viewModel = ApplicationPipelineViewModel(repository: mockRepo);
  });

  Widget createWidgetUnderTest() {
    return ChangeNotifierProvider<ApplicationPipelineViewModel>.value(
      value: viewModel,
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const ApplicationPipelineView(),
      ),
    );
  }

  group('ApplicationPipelineView Widget Tests', () {
    testWidgets(
      'Renders pipeline app bar, all 5 stage columns, and stage headers',
      (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Application Pipeline'), findsOneWidget);
        expect(find.textContaining('Active Applications'), findsOneWidget);

        // Verify all 5 stage column labels are rendered
        expect(find.text('Applied'), findsWidgets);
        expect(find.text('Under Review'), findsWidgets);
        expect(find.text('Technical Screening'), findsWidgets);
        expect(find.text('Offer Received'), findsWidgets);
        expect(find.text('Archived'), findsWidgets);

        // Verify initial applications rendered in appropriate columns
        expect(find.text('Senior Flutter Developer'), findsOneWidget);
        expect(
          find.text('Staff Flutter Engineer - Offline First'),
          findsOneWidget,
        );
        expect(find.text('Principal Mobile Systems Architect'), findsOneWidget);
        expect(find.text('Lead Mobile Systems Engineer'), findsOneWidget);

        // Verify elapsed days label
        expect(find.textContaining('Applied today'), findsOneWidget);
        expect(find.textContaining('3 days ago'), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping advance button transitions application to next stage',
      (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Senior Flutter Developer is in Applied (app_104)
        // Advance button should say "Under Review"
        final advanceButton = find.widgetWithText(FilledButton, 'Under Review');
        expect(advanceButton, findsOneWidget);

        await tester.tap(advanceButton);
        await tester.pumpAndSettle();

        // Verified: app_104 now in underReview
        final updatedApp = viewModel.findApplication('app_104');
        expect(updatedApp!.stage, equals(ApplicationStage.underReview));

        // Advance button on that card should now say "Technical Screening"
        expect(
          find.widgetWithText(FilledButton, 'Technical Screening'),
          findsWidgets,
        );
      },
    );

    testWidgets('Tapping archive button moves application to Archived stage', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap the archive icon on the first available card
      final archiveButton = find.byTooltip('Archive application').first;
      await tester.tap(archiveButton);
      await tester.pumpAndSettle();

      // Verify archived column now has at least 1 application
      expect(viewModel.countForStage(ApplicationStage.archived), equals(1));
    });

    testWidgets('Zero RenderFlex overflow on 800x360 landscape viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ApplicationPipelineView), findsOneWidget);
    });
  });
}
