import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_tables.dart';
import '../../domain/entities/job_application_entity.dart';
import '../../domain/repositories/application_repository_interface.dart';

class ApplicationRepository implements ApplicationRepositoryInterface {
  final AppDatabase database;

  ApplicationRepository({required this.database});

  @override
  Future<List<JobApplicationEntity>> getApplications({
    String? userId = AppConstants.defaultUserId,
  }) async {
    final db = await database.database;

    final String query;
    final List<dynamic> args;

    if (userId != null && userId.isNotEmpty) {
      query =
          '''
        SELECT 
          a.id,
          a.job_id,
          a.user_id,
          a.status,
          a.cover_note,
          a.scheduled_slots,
          a.applied_at,
          a.updated_at,
          COALESCE(a.job_title, j.title, 'Mobile Systems Role') AS job_title,
          COALESCE(a.company, j.company, 'Enterprise Partner') AS company,
          COALESCE(a.company_logo, j.company_logo, 'assets/images/cloudscale.png') AS company_logo,
          COALESCE(a.salary_range, '\$' || j.salary_min || ' - \$' || j.salary_max, '\$180k - \$240k') AS salary_range,
          COALESCE(a.location, j.location, 'Remote') AS location
        FROM ${DatabaseTables.applications} a
        LEFT JOIN ${DatabaseTables.jobs} j ON a.job_id = j.id
        WHERE a.user_id = ?
        ORDER BY a.applied_at DESC
      ''';
      args = [userId];
    } else {
      query =
          '''
        SELECT 
          a.id,
          a.job_id,
          a.user_id,
          a.status,
          a.cover_note,
          a.scheduled_slots,
          a.applied_at,
          a.updated_at,
          COALESCE(a.job_title, j.title, 'Mobile Systems Role') AS job_title,
          COALESCE(a.company, j.company, 'Enterprise Partner') AS company,
          COALESCE(a.company_logo, j.company_logo, 'assets/images/cloudscale.png') AS company_logo,
          COALESCE(a.salary_range, '\$' || j.salary_min || ' - \$' || j.salary_max, '\$180k - \$240k') AS salary_range,
          COALESCE(a.location, j.location, 'Remote') AS location
        FROM ${DatabaseTables.applications} a
        LEFT JOIN ${DatabaseTables.jobs} j ON a.job_id = j.id
        ORDER BY a.applied_at DESC
      ''';
      args = [];
    }

    final results = await db.rawQuery(query, args);
    return results.map((map) => JobApplicationEntity.fromMap(map)).toList();
  }

  @override
  Future<JobApplicationEntity?> getApplicationById(String id) async {
    final applications = await getApplications(userId: null);
    final match = applications.where((a) => a.id == id);
    if (match.isEmpty) return null;
    return match.first;
  }

  @override
  Future<JobApplicationEntity> updateApplicationStage({
    required String applicationId,
    required ApplicationStage newStage,
  }) async {
    final db = await database.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      DatabaseTables.applications,
      {'status': newStage.name, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [applicationId],
    );

    // Also update parent job application_status if associated
    final currentApp = await getApplicationById(applicationId);
    if (currentApp != null) {
      await db.update(
        DatabaseTables.jobs,
        {'application_status': newStage.name},
        where: 'id = ?',
        whereArgs: [currentApp.jobId],
      );
      return currentApp.copyWith(
        stage: newStage,
        updatedAt: DateTime.parse(now),
      );
    }

    throw StateError('Application with ID $applicationId not found');
  }

  @override
  Future<JobApplicationEntity> createApplication({
    required String jobId,
    required String userId,
    required String jobTitle,
    required String company,
    required String companyLogo,
    required String salaryRange,
    required String location,
    String? coverNote,
  }) async {
    final db = await database.database;
    final now = DateTime.now();
    final appId = 'app_${jobId}_$userId';

    final newEntity = JobApplicationEntity(
      id: appId,
      jobId: jobId,
      userId: userId,
      jobTitle: jobTitle,
      company: company,
      companyLogo: companyLogo,
      salaryRange: salaryRange,
      location: location,
      stage: ApplicationStage.applied,
      coverNote: coverNote,
      scheduledSlots: const [],
      appliedAt: now,
      updatedAt: now,
    );

    await db.insert(
      DatabaseTables.applications,
      newEntity.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await db.update(
      DatabaseTables.jobs,
      {'application_status': 'applied'},
      where: 'id = ?',
      whereArgs: [jobId],
    );

    return newEntity;
  }
}
