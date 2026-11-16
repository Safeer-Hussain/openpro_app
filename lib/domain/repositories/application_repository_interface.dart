import '../entities/job_application_entity.dart';

abstract class ApplicationRepositoryInterface {
  Future<List<JobApplicationEntity>> getApplications({String? userId});

  Future<JobApplicationEntity?> getApplicationById(String id);

  Future<JobApplicationEntity> updateApplicationStage({
    required String applicationId,
    required ApplicationStage newStage,
  });

  Future<JobApplicationEntity> createApplication({
    required String jobId,
    required String userId,
    required String jobTitle,
    required String company,
    required String companyLogo,
    required String salaryRange,
    required String location,
    String? coverNote,
  });
}
