import 'package:flutter/foundation.dart';

import '../../../domain/entities/job_application_entity.dart';
import '../../../domain/repositories/application_repository_interface.dart';

class ApplicationPipelineViewModel extends ChangeNotifier {
  final ApplicationRepositoryInterface repository;

  ApplicationPipelineViewModel({required this.repository}) {
    loadApplications();
  }

  List<JobApplicationEntity> _applications = [];
  bool _isLoading = false;
  String? _errorMessage;
  ApplicationStage? _selectedStageFilter;

  List<JobApplicationEntity> get applications =>
      List.unmodifiable(_applications);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ApplicationStage? get selectedStageFilter => _selectedStageFilter;

  int get totalApplicationsCount => _applications.length;

  int get activeApplicationsCount =>
      _applications.where((a) => a.stage != ApplicationStage.archived).length;

  List<JobApplicationEntity> get filteredApplications {
    if (_selectedStageFilter == null) {
      return _applications;
    }
    return _applications.where((a) => a.stage == _selectedStageFilter).toList();
  }

  List<JobApplicationEntity> applicationsForStage(ApplicationStage stage) {
    return _applications.where((a) => a.stage == stage).toList();
  }

  int countForStage(ApplicationStage stage) {
    return _applications.where((a) => a.stage == stage).length;
  }

  void setStageFilter(ApplicationStage? stage) {
    if (_selectedStageFilter != stage) {
      _selectedStageFilter = stage;
      notifyListeners();
    }
  }

  Future<void> loadApplications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _applications = await repository.getApplications();
    } catch (e) {
      _errorMessage = 'Failed to load application pipeline: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> advanceStage(String applicationId) async {
    final index = _applications.indexWhere((a) => a.id == applicationId);
    if (index == -1) return false;

    final currentApp = _applications[index];
    final next = currentApp.stage.nextStage;
    if (next == null) return false;

    return moveApplicationToStage(applicationId, next);
  }

  Future<bool> regressStage(String applicationId) async {
    final index = _applications.indexWhere((a) => a.id == applicationId);
    if (index == -1) return false;

    final currentApp = _applications[index];
    final prev = currentApp.stage.previousStage;
    if (prev == null) return false;

    return moveApplicationToStage(applicationId, prev);
  }

  Future<bool> moveApplicationToStage(
    String applicationId,
    ApplicationStage targetStage,
  ) async {
    final index = _applications.indexWhere((a) => a.id == applicationId);
    if (index == -1) return false;

    final original = _applications[index];
    if (original.stage == targetStage) return true;

    final optimistic = original.copyWith(
      stage: targetStage,
      updatedAt: DateTime.now(),
    );

    // Optimistic UI update
    _applications[index] = optimistic;
    notifyListeners();

    try {
      final updated = await repository.updateApplicationStage(
        applicationId: applicationId,
        newStage: targetStage,
      );
      _applications[index] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      // Revert on failure
      _applications[index] = original;
      _errorMessage = 'Failed to transition application stage: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> archiveApplication(String applicationId) async {
    return moveApplicationToStage(applicationId, ApplicationStage.archived);
  }

  JobApplicationEntity? findApplication(String id) {
    final matches = _applications.where((a) => a.id == id);
    if (matches.isEmpty) return null;
    return matches.first;
  }
}
